use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper b64_decode);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear; # reset db

ok(ref $t->app->api->user eq 'HelpTasker::API::User', 'ok object');

my $user_id = $t->app->api->user->create('kostya', {lastname=>' Ten ', firstname=>' Kostya ', email=>' DEVNULL @ yandex . ru'});
ok(ref $user_id eq 'HelpTasker::API::User');
like($user_id, qr/^[0-9]+$/, 'check user_id');

my $user = $t->app->api->user->get($user_id);
ok(ref $user eq 'HelpTasker::API::User');
ok(ref $user->as_hash eq 'HASH');

$user = $user->as_hash;
like($user->{'date_create'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'date_create');
like($user->{'date_update'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'date_update');
ok($user->{'email'} eq 'devnull@yandex.ru', 'email');
ok($user->{'lastname'} eq 'Ten', 'lastname');
ok($user->{'firstname'} eq 'Kostya', 'firstname');
ok($user->{'login'} eq 'kostya', 'login');
like($user->{'password'},qr/[0-9a-z]{40}/, 'password');
ok($user->{'user_id'} == 1, 'user_id');
ok(ref $user->{'settings'} eq 'HASH', 'settings');

$user = $t->app->api->user->create('kostya2', {
    lastname=>' Ten ',
    firstname=>' Kostya ',
    email=>' DEVNULL @ yandex . ru',
    password=>1234567890,
    ru_str=>'Тест',
    en_str=>'Test',
    int=>12345,
    unicode=>"\x{20AC}",
    hash=>{test=>1},
});
$user = $user->get($user)->as_hash;
ok($user->{'password'} eq '01b307acba4f54f55aafc33bb06bbbf6ca803e9a', 'check password 1234567890');
ok($user->{'settings'}->{'en_str'} eq 'Test', 'check type en_str');
ok($user->{'settings'}->{'ru_str'} eq 'Тест', 'check type ru_str');
ok($user->{'settings'}->{'int'} == 12345, 'check type int');
ok($user->{'settings'}->{'unicode'} eq "\x{20AC}", 'check type unicode');
ok($user->{'settings'}->{'hash'}->{'test'} == 1, 'check type hash');

done_testing();
