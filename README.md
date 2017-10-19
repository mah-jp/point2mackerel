# point2mackerel.pl - プリペイドカードなどの残高・ポイント数をMackerelに投稿するためのPerlスクリプト

## What is this?

このPerlスクリプトは、プリペイドカードなどのサイトをクロールして残高・ポイント数を取得し、サーバ管理・監視ツールの[Mackerel](https://mackerel.io/ja/)に投稿するためのJSON文字列を標準出力します。

対応しているカードは、現在、次の通りです。

|MODE文字列|カード名|備考|
|----|----|----|
|doutor|ドトールバリューカード (Doutor Value Card)|http://doutor.jp/|
|tullys|タリーズカード (Tully's Card)|https://www.tullys.co.jp/cpn/tullyscard/ ※所有カードが複数枚ある場合の動作は未確認|

## USAGE

1. ``git clone https://github.com/mah-jp/point2mackerel`` でファイルを取得します。
2. point2mackerel.ini を編集し、各種カードのアカウント情報を記入します。
3. テストとして ``point2mackerel.pl MODE`` を実行し、カードのポイント数が標準出力されることを確認します。
	```
	$ ./point2mackerel.pl doutor
	1869
	```
4. 引数に「-j」を指定するとJSON文字列が標準出力されます。
	```
	$ ./point2mackerel.pl -j doutor
	[ {"name": "Point.Doutor", "time": 1508429746, "value": 1869} ]
	```
5. そこで、たとえば次のようなcronを設定すると、毎時00分と30分に、Mackerelにポイントのデータが投稿されるようになります。
	> 0,30 * * * * curl https://api.mackerelio.com/api/v0/services/+++++YOUR-SERVICE-NAME+++++/tsdb -H 'X-Api-Key: +++++YOUR-API-KEY+++++' -H 'Content-Type: application/json' -X POST -d "$(/path/to/point2mackerel.pl -i /path/to/point2mackerel.ini -j +++++MODE+++++)"

## AUTHOR

大久保 正彦 (Masahiko OHKUBO) <[mah@remoteroom.jp](mailto:mah@remoteroom.jp)> <[https://twitter.com/mah_jp](https://twitter.com/mah_jp)>

## COPYRIGHT and LICENSE

This software is copyright (c) 2017 by Masahiko OHKUBO.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
