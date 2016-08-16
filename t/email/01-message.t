use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper punycode_decode punycode_encode);
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

note('Method render');
$message->from('"Вася Пупкин" <pupkin@example.com>');
$message->to(["user_to1\@example.com"]);
$message->cc(["user_cc1\@example.com"]);
$message->date("1994-11-06T08:49:37Z");
$message->reply_to("reply_to\@example.com");

like($message->render, qr{From: =\?UTF-8\?B\?0JLQsNGB0Y8g0J/Rg9C/0LrQuNC9\?= \<pupkin\@example.com\>}, 'From Ok');
like($message->render, qr{To: =\?UTF-8\?B\?dXNlcl90bzE=\?= <user_to1\@example.com>}, 'To Ok');
like($message->render, qr{Cc: =\?UTF-8\?B\?dXNlcl9jYzE=\?= <user_cc1\@example.com>}, 'Cc Ok');
like($message->render, qr{Date: Sun, 06 Nov 1994 08:49:37 GMT}, 'Date Ok');
like($message->render, qr{Reply-To: =\?UTF-8\?B\?cmVwbHlfdG8=\?= <reply_to\@example.com>}, 'Reply-To Ok');
like($message->render, qr{Message-Id: [a-zA-z0-9]{40}\@}, 'Message-Id Ok');

note("\tMethod render (to array)");
$message->to(["user_to1\@example.com","user_to2\@example.com"]);
$message->cc(["user_cc1\@example.com","user_cc2\@example.com"]);

like($message->render, qr{To: =\?UTF-8\?B\?dXNlcl90bzE=\?= <user_to1\@example.com>, =\?UTF-8\?B\?dXNlcl90bzI=\?= <user_to2\@example.com>}, 'To (Array) Ok');
like($message->render, qr{Cc: =\?UTF-8\?B\?dXNlcl9jYzE=\?= <user_cc1\@example.com>, =\?UTF-8\?B\?dXNlcl9jYzI=\?= <user_cc2\@example.com>}, 'Cc (Array) Ok');

$message->to([{name=>'user_to1', address=>'user_to1@example.com'}, {name=>'user_to2', address=>'user_to2@example.com'}]);
$message->cc([{name=>'user_cc1', address=>'user_cc1@example.com'}, {name=>'user_cc2', address=>'user_cc2@example.com'}]);

like($message->render, qr{To: =\?UTF-8\?B\?dXNlcl90bzE=\?= <user_to1\@example.com>, =\?UTF-8\?B\?dXNlcl90bzI=\?= <user_to2\@example.com>}, 'To (Array) Ok');
like($message->render, qr{Cc: =\?UTF-8\?B\?dXNlcl9jYzE=\?= <user_cc1\@example.com>, =\?UTF-8\?B\?dXNlcl9jYzI=\?= <user_cc2\@example.com>}, 'Cc (Array) Ok');

#say $message->render;

#say dumper $address;
#$message->from('"Костя Тен" <kostya@yandex.ru>');
#$message->to([{address=>'user2@example.com', name=>'To1'},{address=>'user3@example.com', name=>'To2'}, "kostya\@yandex.ru", "kostya\@yandex.ru"]);
#$message->cc([{address=>'user3@example.com', name=>'Cc1'},{address=>'user4@example.com', name=>'Cc2'}]);
#$message->subject('subject');
#$message->reply_to('user5@example.com');
#$message->date('1994-11-06T08:49:37Z');




done_testing();

