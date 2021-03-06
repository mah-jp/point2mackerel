#!/usr/bin/env perl

# point2mackerel.pl (Ver.20210420) by Masahiko OHKUBO
# usage: point2mackerel.pl [-i INIFILE] [-j] [-t] [-o OPTION] MODE

use strict;
use warnings;
use lib $ENV{'HOME'} . '/perl5/lib/perl5';
use Config::Tiny;
use Encode;
use File::Temp;
use Getopt::Std;
use HTML::TagParser;
use URI::Escape;

my %opt;
Getopt::Std::getopts('i:jto:', \%opt);
my %modes = ( 'doutor' => 1, 'tullys' => 1, 'rakuten' => 1, 'saison' => 1, 'crowdbank' => 1, 'lendex' => 1 );
my $mode = shift(@ARGV) || die('[ERROR] Please select mode: { ' . join(' | ', keys(%modes)) . ' }');
my $file_ini = $opt{'i'} || 'point2mackerel.ini';
my $flag_localtest = defined($opt{'t'}) || 0;
my $config = Config::Tiny->new;
$config = Config::Tiny->read($file_ini) || die('[ERROR] Can not read INI file: ' . $file_ini);

my($card_url_1, $card_url_2, $card_charset, $card_id, $card_password, $card_pointperyen, $card_wait, $option);
my($json_key, $json_value);
if (defined($modes{$mode})) {
	$card_url_1 = $config->{$mode}->{'url'} || $config->{$mode}->{'url_1'};
	$card_url_2 = $config->{$mode}->{'url_2'};
	$card_charset = $config->{$mode}->{'charset'};
	$card_id = $config->{$mode}->{'id'};
	$card_password = $config->{$mode}->{'password'};
	$card_pointperyen = $config->{$mode}->{'rate_pointperyen'} || 1;
	$card_wait = $config->{$mode}->{'wait'} || 0;
	$json_key = $config->{$mode}->{'json_key'};
	$option = $opt{'o'} || $config->{$mode}->{'option'} || '';
} else {
	die('[ERROR] Please select mode: { ' . join(' | ', keys(%modes)) . ' }');
}

if ($mode eq 'doutor') {
	$card_id =~ s/\D//g;
	$json_value = &GET_VALUE_DOUTOR($card_url_1, $card_charset, $card_id, $card_password);
} elsif ($mode eq 'tullys') {
	$json_value = &GET_VALUE_TULLYS($card_url_1, $card_url_2, $card_charset, $card_id, $card_password);
} elsif ($mode eq 'rakuten') {
	$json_value = &GET_VALUE_RAKUTEN($card_url_1, $card_charset, $card_id, $card_password);
} elsif ($mode eq 'saison') {
	$json_value = &GET_VALUE_SAISON($card_url_1, $card_charset, $card_id, $card_password, $card_wait, $option, $flag_localtest);
} elsif ($mode eq 'crowdbank') {
	$json_value = &GET_VALUE_CROWDBANK($card_url_1, $card_charset, $card_id, $card_password, $card_wait, $flag_localtest);
} elsif ($mode eq 'lendex') {
	$json_value = &GET_VALUE_LENDEX($card_url_1, $card_charset, $card_id, $card_password, $card_wait, $flag_localtest);
}

if (defined($opt{'j'})) {
	printf ('%s' . "\n", &MAKE_JSON($json_key, $json_value / $card_pointperyen));
} else {
	printf ('%d' . "\n", $json_value / $card_pointperyen);
}
exit;

# Ver.20190529
sub GET_VALUE_DOUTOR {
	my ($card_url, $card_charset, $card_id, $card_password) = @_;
	my (@card_id) = (substr($card_id, -16, 4), substr($card_id, -12, 4), substr($card_id, -8, 4), substr($card_id, -4, 4));
	my $postdata = sprintf(
		'hid_login=ON&CUSTNUM01=%04d&CUSTNUM02=%04d&CUSTNUM03=%04d&CUSTNUM04=%04d&PASSWORD=%s',
		@card_id, URI::Escape::uri_escape($card_password));
	my $response = Encode::encode('UTF-8', Encode::decode($card_charset, `curl -s -b -c -L -X POST --data '$postdata' "$card_url"`));
	my $html;
	my ($value, $point) = ('undefined', 'undefined');
	eval { $html = HTML::TagParser->new($response); };
	if (!($@)) {
		my @elem = $html->getElementsByClassName('table member_table')->subTree()->getElementsByClassName('zipcode');
		if (@elem) {
			$value = &EXTRACT_NUMBER($elem[1]->innerText());
			$point = &EXTRACT_NUMBER($elem[3]->innerText());
		}
	} else {
		die(sprintf('[ERROR] %s' . "\n", $@));
	}
	return($value + $point);
}

# Ver.20171019
sub GET_VALUE_TULLYS {
	my ($card_url_1, $card_url_2, $card_charset, $card_id, $card_password) = @_;
	my(undef, $tmp_filename) = File::Temp::tempfile( SUFFIX => '.cookie', OPEN => 0 );
	my $postdata = sprintf(
		'login_id=%s&password=%s',
		URI::Escape::uri_escape($card_id), URI::Escape::uri_escape($card_password));
	my $response = Encode::decode($card_charset, `curl -s -c "$tmp_filename" -L -X POST --data '$postdata' "$card_url_1"`);
	$response = Encode::decode($card_charset, `curl -s -b "$tmp_filename" -L "$card_url_2"`);
	unlink($tmp_filename);
	my $html;
	my $value = 'undefined';
	eval { $html = HTML::TagParser->new($response); };
	if (!($@)) {
		$value = $html->getElementsByName('form1')->subTree()->getElementsByClassName('contentListBalance')->innerText();
		$value = &EXTRACT_NUMBER($value);
	} else {
		die(sprintf('[ERROR] %s' . "\n", $@));
	}
	return($value);
}

# Ver.20171020
sub GET_VALUE_RAKUTEN {
	my ($card_url, $card_charset, $card_id, $card_password) = @_;
	my $postdata = sprintf(
		'service_id=13&return_url=/&u=%s&p=%s',
		URI::Escape::uri_escape($card_id), URI::Escape::uri_escape($card_password));
	my $response = Encode::decode($card_charset, `curl -s -b -c -L -X POST --data '$postdata' "$card_url"`);
	my $html;
	my $value = 'undefined';
	eval { $html = HTML::TagParser->new($response); };
	if (!($@)) {
		$value = $html->getElementsByClassName('point-total')->subTree()->getElementsByTagName('dd')->innerText;
	} else {
		die(sprintf('[ERROR] %s' . "\n", $@));
	}
	$value = &EXTRACT_NUMBER($value);
	return($value);
}

# Ver.20191030
sub GET_VALUE_SAISON {
	my ($card_url, $card_charset, $card_id, $card_password, $card_wait, $option, $flag_localtest) = @_;
	my(@elem);
	my $driver = &SELENIUM($flag_localtest);
	$driver->get($card_url);
	@elem = $driver->find_elements("//input[\@name='aa_accd']");
		$elem[1]->send_keys($card_id); # 2nd element
	@elem = $driver->find_elements("//input[\@name='lg_pw']");
		$elem[1]->send_keys($card_password); # 2nd element
	my $elem = $driver->find_element("//input[\@name='SUB1']");
	$driver->move_to(element => $elem);
	$elem->click;
	$driver->pause($card_wait);
	my $html;
	my $value = 'undefined';
	my $response = Encode::encode($card_charset, $driver->get_page_source());
	$driver->quit();
	eval { $html = HTML::TagParser->new($response); };
	if (!($@)) {
		if ($option eq 'profit') {
			@elem = $html->getElementsByClassName('dataitem04');
			$value = $elem[0]->innerText; # 1st element
		} else {
			@elem = $html->getElementsByClassName('dataitem05 titlehend');
			$value = $elem[2]->innerText; # 3rd element
		}
	} else {
		die(sprintf('[ERROR] %s' . "\n", $@));
	}
	$value = &EXTRACT_NUMBER($value);
	return($value);
}

# Ver.20191031
sub GET_VALUE_CROWDBANK {
	my ($card_url_1, $card_charset, $card_id, $card_password, $card_wait, $flag_localtest) = @_;
	my(@elem);
	my $driver = &SELENIUM($flag_localtest);
	$driver->get($card_url_1);
	$driver->find_element("//input[\@name='user_id']")->send_keys($card_id);
	$driver->find_element("//input[\@name='password']")->send_keys($card_password);
	my $elem = $driver->find_element("//button[\@name='submit']");
	$driver->move_to(element => $elem);
	$elem->click;
	$driver->pause($card_wait);
	my $html;
	my $value = 'undefined';
	my $response = Encode::encode($card_charset, $driver->get_page_source());
	$driver->quit();
	eval { $html = HTML::TagParser->new($response); };
	if (!($@)) {
		@elem = $html->getElementsByClassName('money__value');
		$value = $elem[5]->innerText; # 5th element
	} else {
		die(sprintf('[ERROR] %s' . "\n", $@));
	}
	$value = &EXTRACT_NUMBER($value);
	return($value);
}

# Ver.20210420
sub GET_VALUE_LENDEX {
	my ($card_url_1, $card_charset, $card_id, $card_password, $card_wait, $flag_localtest) = @_;
	my(@elem);
	my $driver = &SELENIUM($flag_localtest);
	$driver->get($card_url_1);
	$driver->find_element("//input[\@name='username']")->send_keys($card_id);
	$driver->find_element("//input[\@name='password']")->send_keys($card_password);
	my $elem = $driver->find_element("//input[\@class='col-xs-offset-2 btn btn-success']");
	$driver->move_to(element => $elem);
	$elem->click;
	$driver->pause($card_wait);
	my $html;
	my $value = 'undefined';
	my $response = Encode::encode($card_charset, $driver->get_page_source());
	$driver->quit();
	eval { $html = HTML::TagParser->new($response); };
	if (!($@)) {
		@elem = $html->getElementsByClassName('table table-striped');
		@elem = $elem[2]->subTree()->getElementsByTagName('td');
		$value = $elem[2]->innerText; # 1st element
	} else {
		die(sprintf('[ERROR] %s' . "\n", $@));
	}
	$value = &EXTRACT_NUMBER($value);
	return($value);
}

sub EXTRACT_NUMBER {
	my($text) = @_;
	$text =~ s/\s*([\d|,]+)(.*)$/$1/;
	$text =~ s/,//g;
	$text =~ s/\D//g;
	return($text);
}

sub MAKE_JSON {
	my($key, $value) = @_;
	my $time = time;
	my $json = sprintf('[ {"name": "%s", "time": %d, "value": %d} ]', $key, $time, $value);
	return($json);
}

sub SELENIUM {
	my($flag_localtest) = @_;
	my($driver);
	if ($flag_localtest == 1) {
		use Selenium::Chrome;
		$driver = Selenium::Chrome->new; # for local test
	} else {
		use Selenium::Remote::Driver;
		$driver = Selenium::Remote::Driver->new( # for headless
			'browser_name' => 'chrome',
			'extra_capabilities' => { 'goog:chromeOptions' => { 'args' => [ 'window-size=1024,768' ] }}
		);
	}
	return($driver);
}

sub DEBUG {
	my($text) = @_;
	printf('[DEBUG] %s' . "\n", $text);
	return;
}
