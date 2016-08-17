use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper punycode_decode punycode_encode slurp b64_decode);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

ok(ref $t->app->api->email->utils eq 'HelpTasker::Email::Utils', 'ok object');

ok($t->app->api->email->utils->validator('devnull@abc.def', {mxcheck=>1}) == 0, 'invalid email (mxcheck)');
ok($t->app->api->email->utils->validator('devnull@abc.def', {tldcheck=>1}) == 0, 'invalid email (tldcheck)');

ok($t->app->api->email->utils->validator('devnull@example.com', {tldcheck=>1}) == 1, 'valid email (tldcheck)');
ok($t->app->api->email->utils->validator('devnull@example.com', {tldcheck=>1, mxcheck=>1}) == 0, 'invalid email (mxcheck)');
ok($t->app->api->email->utils->validator('devnull@yandex.ru', {tldcheck=>1, mxcheck=>1}) == 1, 'valid email (tldcheck and mxcheck)');


done_testing();
