use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper b64_decode);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear; # reset db

note('db');
ok($t->app->api->cache->save('key','value') == 1, 'set ok');
ok($t->app->api->cache->get('key') eq 'value', 'get ok');

ok($t->app->api->cache->save('key','value',1) == 1, 'set ok');
sleep 2;
ok(!defined $t->app->api->cache->get('key') == 1, 'get expire ok');

my $types = {
    ru_str=>'Тест',
    en_str=>'Test',
    int=>12345,
    unicode=>"\x{20AC}",
    ip=>'2001:cdba:0000:0000:0000:0000:3257:9652',
    hash=>{test=>1}
};
ok($t->app->api->cache->save('key',$types) == 1, 'set ok');

my $result = $t->app->api->cache->get('key');
ok($result->{'ru_str'} eq 'Тест', 'type ru_str');
ok($result->{'en_str'} eq 'Test', 'type en_str');
ok($result->{'int'} == 12345, 'type int');
ok($result->{'unicode'} eq "\x{20AC}", 'type unicode');
ok($result->{'ip'} eq '2001:cdba:0000:0000:0000:0000:3257:9652', 'type ip');
ok($result->{'hash'}->{'test'} == 1, 'type hash');

ok($t->app->api->cache->remove('key') == 1, 'ok remove');
ok(!defined $t->app->api->cache->get('key') == 1, 'ok delete');

note('memcached');
$ENV{'MOJO_CONFIG'} = "$FindBin::Bin/config/cache-memcached.conf";
$t = Test::Mojo->new('HelpTasker');

ok($t->app->api->cache->save('key','value',5) == 1, 'set ok');
ok($t->app->api->cache->get('key') eq 'value', 'get ok');

$types = {
    ru_str=>'Тест',
    en_str=>'Test',
    int=>12345,
    unicode=>"\x{20AC}",
    ip=>'2001:cdba:0000:0000:0000:0000:3257:9652',
    hash=>{test=>1}
};
ok($t->app->api->cache->save('key',$types,5) == 1, 'set ok');

$result = $t->app->api->cache->get('key');
ok($result->{'ru_str'} eq 'Тест', 'type ru_str');
ok($result->{'en_str'} eq 'Test', 'type en_str');
ok($result->{'int'} == 12345, 'type int');
ok($result->{'unicode'} eq "\x{20AC}", 'type unicode');
ok($result->{'ip'} eq '2001:cdba:0000:0000:0000:0000:3257:9652', 'type ip');
ok($result->{'hash'}->{'test'} == 1, 'type hash');

ok($t->app->api->cache->remove('key') == 1, 'ok remove');
ok(!defined $t->app->api->cache->get('key') == 1, 'ok delete');

done_testing();
