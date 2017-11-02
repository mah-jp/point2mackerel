# point2mackerel.pl - プリペイドカードなどの残高・ポイント数をMackerelに投稿するためのPerlスクリプト

## What is this?

このPerlスクリプトは、プリペイドカードのウェブサイトや投信サイトなどをクロールして残高・ポイント数を取得し、サーバ管理・監視ツールの[Mackerel](https://mackerel.io/ja/)に投稿するためのJSON文字列を標準出力します。

対応しているカードおよびサイトは、現在、次の通りです。

|MODE文字列|カード名・サイト名|備考|
|----|----|----|
|doutor|[ドトールバリューカード (Doutor Value Card)](http://doutor.jp/)||
|tullys|[タリーズカード (Tully's Card)](https://www.tullys.co.jp/cpn/tullyscard/)|所有カードが複数枚ある場合の動作は未確認|
|rakuten|[楽天ポイントカード (Rakuten Point Card)](https://pointcard.rakuten.co.jp/)|「総保有ポイント」のみ対応|
|saison|[セゾン投信 (Saison Asset Management)](https://www.saison-am.co.jp/)|ファンドの「評価額合計」のみ対応|
|crowdbank|[日本クラウド証券 (Crowd Bank, Crowd Securities Japan)](https://crowdbank.jp/)|投資状況の「総資金」のみ対応|

## USAGE

1. ``git clone https://github.com/mah-jp/point2mackerel`` でファイルを取得します。
2. point2mackerel.ini を編集し、必要な分のカードおよびサイトのアカウント情報を記入します。下記の　``point2mackerel.pl MODE``　で指定しないMODEのアカウント情報は未記入でOKです。
	- 「MODE = saison or crowdbank」の場合: 動作環境にSelenium (Chrome) をセットアップすることが別途必要です。本Perlスクリプト上は[Selenium::Remote::Driverモジュール](http://search.cpan.org/~gempesaw/Selenium-Remote-Driver/lib/Selenium/Remote/Driver.pm)を用いています。
3. テストとして ``point2mackerel.pl MODE`` を実行し、指定したカード等のポイント数が標準出力できていることを確認します。
	```
	$ ./point2mackerel.pl doutor
	1869
	```
4. 引数に「-j」を指定すると標準出力がJSON文字列の形式に切り替わります。
	```
	$ ./point2mackerel.pl -j doutor
	[ {"name": "Point.Doutor", "time": 1508429746, "value": 1869} ]
	```
5. そこで、たとえば次のようなcronを設定すると、毎時00分に、Mackerelにポイント等のデータが投稿されるようになります。
	> 0 * * * * curl https://api.mackerelio.com/api/v0/services/+++++YOUR-SERVICE-NAME+++++/tsdb -H 'X-Api-Key: +++++YOUR-API-KEY+++++' -H 'Content-Type: application/json' -X POST -d "$(/path/to/point2mackerel.pl -i /path/to/point2mackerel.ini -j +++++MODE+++++)"

## Seleniumセットアップに関するHINT

動作環境へのSelenium (Chrome) のセットアップを、作者は https://gist.github.com/ziadoz/3e8ab7e944d02fe872c3454d17af31a5 の install.sh スクリプトを用いて行いました。

セットアップ後には、同ページにある start-chrome.sh を用いて xvfb-run java ... を起動させておき、Seleniumを用いるMODEで point2mackerel.pl を実行すると正常に動作します。

## AUTHOR

大久保 正彦 (Masahiko OHKUBO) <[mah@remoteroom.jp](mailto:mah@remoteroom.jp)> <[https://twitter.com/mah_jp](https://twitter.com/mah_jp)>

## COPYRIGHT and LICENSE

This software is copyright (c) 2017 by Masahiko OHKUBO.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
