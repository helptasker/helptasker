use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper punycode_decode punycode_encode slurp b64_decode);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

ok(ref $t->app->api->email->message eq 'HelpTasker::Email::Message', 'ok object');

my $message = $t->app->api->email->message;

note('Method mimeword');
ok($message->mimeword('Тест','q') eq '=?UTF-8?Q?=D0=A2=D0=B5=D1=81=D1=82?=', 'mimeword encoding QuotedPrint');
ok($message->mimeword('Тест','b') eq '=?UTF-8?B?0KLQtdGB0YI=?=', 'mimeword encoding Base64');

note('Method parse_address');
my $address = $message->parse_address('devnull@yandex.ru');
ok($address->{'name'} eq 'devnull', 'check address');
ok($address->{'host'} eq 'yandex.ru', 'check host');
ok($address->{'mime'} eq '=?UTF-8?B?ZGV2bnVsbA==?= <devnull@yandex.ru>', 'check mime standart');
ok($address->{'address'} eq 'devnull@yandex.ru', 'check address');
ok($address->{'original'} eq 'devnull@yandex.ru', 'check original');
ok($address->{'user'} eq 'devnull', 'check user');

my @address = $message->parse_address('devnull@yandex.ru');
ok($address[0]->{'name'} eq 'devnull', 'check array address');
ok($address[0]->{'host'} eq 'yandex.ru', 'check array host');
ok($address[0]->{'mime'} eq '=?UTF-8?B?ZGV2bnVsbA==?= <devnull@yandex.ru>', 'check array mime standart');
ok($address[0]->{'address'} eq 'devnull@yandex.ru', 'check array address');
ok($address[0]->{'original'} eq 'devnull@yandex.ru', 'check array original');
ok($address[0]->{'user'} eq 'devnull', 'check array user');

note('Method mime');
ok(ref $message->mime eq 'MIME::Lite', 'ok object MIME::Lite');

note('Method render');
$message->from('"Вася Пупкин" <pupkin@example.com>');
$message->to(["user_to1\@example.com"]);
$message->cc(["user_cc1\@example.com"]);
$message->date("1994-11-06T08:49:37Z");
$message->reply_to("reply_to\@example.com");
$message->body("Тест");
$message->content_type('plain/text; charset="UTF-8"');

my $gif = 'R0lGODlhyADIAMIAAP/yAAoKCgAAAcRiAO0cJAAAAAAAAAAAACH5BAEAAAUALAAAAADIAMgAAAP+WLrc/jDKSau9OOvNu/9gKI5kaZ5oqq5s675wLM90bd94ru987//AoHBILBqPyKRyyWw6n9CodEqtWq/YrHbL7Xq/4LB4TC6bz+i0es1uu9/wuHxOr9vv+Lx+z+/7/4CBgoOEhYaHiImKi4yNjo+QkZKTlJWWl5iZmpucnZ6foKGio6SlpqeoqaqrrK2ur7CxsrO0tba3uLm6u7y9vr/AwcLDxMXGx8jJysvMzc7P0NHS09TV1tfY2drb3N3e3+Dh4uPk5eaTAukCzOrry+3s6sjtAfUB8MP09vjC+vX8wfzdk/dLoL2B6YAZ3EfQ18J/DXs9ROjOobqDBwGSmHj+ENJEjSM42vN4ESPEhCdE1iOZzuTJiiVUBmApwCVFEO3aAdjJs+fOjo8+RuSQU53PowCAOhKK0kPRdEh9Km3EFCbRp1F7TmWkEylIC12zZt26KKzPrxXMij1KVpFanmgpvF3Ls22iuQDiTsBL1y6Yp4AD28yI1evQvUbprvX7JbDjnIMZFo2q1wFfxT9HnnnMuWZkingrN7iMmbGXzo8/g058VDQD0opNZ5F5ELNtw00jwL4tGwtte7eDwz1smbVwpL2v/K53PLjo3baTW1keoPnt58at19VsRqZW4NrPEi8AXbj02SUjf2cevifa8sHP+04/eH319sNzv86OP/P+ys302WRffzu9x19/8m2BWkvg9WcgVMepBseCnrHn4Hjw2WfThAvWRuCDAjQn4RsUenihfgtkuF1kgJiIn2xmDSDjAPYx4mJ7MBo3I40rzrTIjeHlCOFOO9b4Y4MvcqebjjMaqYiLoR2YlJIQtLPjlTMmqAeUUuIlpABYYqllHlwOKZ6ZTi6ZTphXjolHmSHiFidbVD5gJZtZ1mnIQQT0ScBtfv7ZI4V3iqlnIXz6CaiigxK6Zphu3pFon4tS2qijbEZqx6SCYhaofY4+auh/jgCpXZE8oSqWpn2Yap2qAMAaFat8uNocrLIid6iNSLaHa5OL7fqIarf9KmNfwpaK+lmxwBLZ7FjJNkKsbcbyuGq0vKpH7bO50klqJ7YSmCYn4Yrrn4+elGsurYeoKy67e/ZqrrfogivvvONu4i6B8CJ6L77nguKigD0O7FK+mhhskoZIEhzwJwpjxLCFUy7co8ANH1xwxhY/LIpdIB/qmr6Hhvztfih+XPLKJ6c4HsYtK2ByvShb9UQCADs=';
$message->attachment([{bytes=>b64_decode($gif), filename=>'картинка.gif'}]);

like($message->render, qr{Content-Type: image/gif; name=\"=\?UTF-8\?B\?0LrQsNGA0YLQuNC90LrQsC5naWY=\?="}, 'Attachment Ok');

like($message->render, qr{Content-Type: text/plain; charset="utf-8"}, 'Content-Type Ok');
like($message->render, qr{From: =\?UTF-8\?B\?0JLQsNGB0Y8g0J/Rg9C/0LrQuNC9\?= \<pupkin\@example.com\>}, 'From Ok');
like($message->render, qr{To: =\?UTF-8\?B\?dXNlcl90bzE=\?= <user_to1\@example.com>}, 'To Ok');
like($message->render, qr{Cc: =\?UTF-8\?B\?dXNlcl9jYzE=\?= <user_cc1\@example.com>}, 'Cc Ok');
like($message->render, qr{Date: Sun, 06 Nov 1994 08:49:37 GMT}, 'Date Ok');
like($message->render, qr{Reply-To: =\?UTF-8\?B\?cmVwbHlfdG8=\?= <reply_to\@example.com>}, 'Reply-To Ok');
like($message->render, qr{Message-Id: [a-zA-z0-9]{40}\@}, 'Message-Id Ok');

subtest 'Array to,cc' => sub {
    plan tests => 4;

    $message->to(["user_to1\@example.com","user_to2\@example.com"]);
    $message->cc(["user_cc1\@example.com","user_cc2\@example.com"]);

    like($message->render, qr{To: =\?UTF-8\?B\?dXNlcl90bzE=\?= <user_to1\@example.com>, =\?UTF-8\?B\?dXNlcl90bzI=\?= <user_to2\@example.com>}, 'To (Array) Ok');
    like($message->render, qr{Cc: =\?UTF-8\?B\?dXNlcl9jYzE=\?= <user_cc1\@example.com>, =\?UTF-8\?B\?dXNlcl9jYzI=\?= <user_cc2\@example.com>}, 'Cc (Array) Ok');

    $message->to([{name=>'user_to1', address=>'user_to1@example.com'}, {name=>'user_to2', address=>'user_to2@example.com'}]);
    $message->cc([{name=>'user_cc1', address=>'user_cc1@example.com'}, {name=>'user_cc2', address=>'user_cc2@example.com'}]);

    like($message->render, qr{To: =\?UTF-8\?B\?dXNlcl90bzE=\?= <user_to1\@example.com>, =\?UTF-8\?B\?dXNlcl90bzI=\?= <user_to2\@example.com>}, 'To (Array) Ok');
    like($message->render, qr{Cc: =\?UTF-8\?B\?dXNlcl9jYzE=\?= <user_cc1\@example.com>, =\?UTF-8\?B\?dXNlcl9jYzI=\?= <user_cc2\@example.com>}, 'Cc (Array) Ok');
};



done_testing();

