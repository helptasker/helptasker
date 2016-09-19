use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper punycode_decode punycode_encode slurp b64_decode);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

ok(ref $t->app->api->email->utils eq 'HelpTasker::API::Email::Utils', 'ok object');

ok($t->app->api->email->utils->validator('devnull@abc.def', {mxcheck=>1}) == 0, 'invalid email (mxcheck)');
ok($t->app->api->email->utils->validator('devnull@abc.def', {tldcheck=>1}) == 0, 'invalid email (tldcheck)');

ok($t->app->api->email->utils->validator('devnull@example.com', {tldcheck=>1}) == 1, 'valid email (tldcheck)');
ok($t->app->api->email->utils->validator('devnull@example.com', {tldcheck=>1, mxcheck=>1}) == 0, 'invalid email (mxcheck)');
ok($t->app->api->email->utils->validator('devnull@yandex.ru', {tldcheck=>1, mxcheck=>1}) == 1, 'valid email (tldcheck and mxcheck)');


note('Method parse_address');
my $address = $t->app->api->email->utils->parse_address('devnull@yandex.ru');
ok($address->{'name'} eq 'devnull', 'check address');
ok($address->{'host'} eq 'yandex.ru', 'check host');
ok($address->{'mime'} eq '=?UTF-8?B?ZGV2bnVsbA==?= <devnull@yandex.ru>', 'check mime standart');
ok($address->{'address'} eq 'devnull@yandex.ru', 'check address');
ok($address->{'original'} eq 'devnull@yandex.ru', 'check original');
ok($address->{'user'} eq 'devnull', 'check user');

my @address = $t->app->api->email->utils->parse_address('devnull@yandex.ru');
ok($address[0]->{'name'} eq 'devnull', 'check array address');
ok($address[0]->{'host'} eq 'yandex.ru', 'check array host');
ok($address[0]->{'mime'} eq '=?UTF-8?B?ZGV2bnVsbA==?= <devnull@yandex.ru>', 'check array mime standart');
ok($address[0]->{'address'} eq 'devnull@yandex.ru', 'check array address');
ok($address[0]->{'original'} eq 'devnull@yandex.ru', 'check array original');
ok($address[0]->{'user'} eq 'devnull', 'check array user');


done_testing();
