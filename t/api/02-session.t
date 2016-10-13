use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
use Try::Tiny;
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
ok(ref $t->app->api->session eq 'HelpTasker::API::Session', 'ok object');

$t->app->api->migration->clear; # reset db

note('params {test=>1, expire=>300}');
my $session = $t->app->api->session->create('test_project',{test=>1, expire=>300});
ok(ref $session eq 'HelpTasker::API::Session', 'ok object create');
like($session, qr/^[0-9]+\-[0-9a-z]{40}$/ix, 'ok session_key 1');
like($session->session_key, qr/^[0-9]+\-[0-9a-z]{40}$/ix, 'ok session_key 2');
like($session->session_id, qr/^[0-9]+$/ix, 'ok session_id');

note('no params');
$session = $t->app->api->session->create('test_project');
ok(ref $session eq 'HelpTasker::API::Session', 'ok object create');
like($session, qr/^[0-9]+\-[0-9a-z]{40}$/ix, 'ok session_key 1');
like($session->session_key, qr/^[0-9]+\-[0-9a-z]{40}$/ix, 'ok session_key 2');
like($session->session_id, qr/^[0-9]+$/ix, 'ok session_id');

note('get only session_id');
$session = $t->app->api->session->create('test_project');
my $get = $t->app->api->session->get($session->session_id)->as_hash;
ok($get->{'session_id'} == $session->session_id, 'check session_id');

note('check params');
my $types = {
    ru_str=>'Тест',
    en_str=>'Test',
    int=>12345,
    unicode=>"\x{20AC}",
    ip=>'2001:cdba:0000:0000:0000:0000:3257:9652',
    hash=>{test=>1}
};

$session = $t->app->api->session->create('test_project', $types);
$get = $t->app->api->session->get($session);
ok(ref $get eq 'HelpTasker::API::Session', 'ok get object');

$get = $t->app->api->session->get($session)->as_hash;
ok($get->{'age'} > 299, 'check age');
ok($get->{'data'}->{'en_str'} eq 'Test', 'check type en_str');
ok($get->{'data'}->{'ru_str'} eq 'Тест', 'check type ru_str');
ok($get->{'data'}->{'int'} == 12345, 'check type int');
ok($get->{'data'}->{'unicode'} eq "\x{20AC}", 'check type unicode');
ok($get->{'data'}->{'hash'}->{'test'} == 1, 'check type hash');

like($get->{'expire'}, qr/[0-9]+/ix, 'check expire');
ok($get->{'ip'} eq "2001:cdba::3257:9652", 'check ip');
ok($get->{'is_valid'} == 1, 'check is_valid');
like($get->{'key'}, qr/^[0-9a-z]{40}$/ix, 'check key');
like($get->{'session_id'}, qr/[0-9]+/, 'check session_id');
ok($get->{'name'} eq 'test_project', 'check name');
like($get->{'session_id'}, qr/^[0-9]+$/ix, 'check session_id');

$t->app->api->session->remove($session);

note('get session after remove');
$get = $t->app->api->session->get($session);
ok(!defined $get == 1, 'check invalid get');

note('invalid if');
unless(my $session = $t->app->api->session->get('1-'.'a' x 40)){
    ok(1==1, 'invalid if');
}

done_testing();


