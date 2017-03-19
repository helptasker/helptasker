use Mojo::Base -strict;
use Mojo::Util qw(dumper);
use Mojo::JSON qw(true false);
use Test::More;
use Test::Mojo;
use Try::Tiny;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use HelpTasker::Command::migration;

my $t = Test::Mojo->new('HelpTasker');

my $migration = HelpTasker::Command::migration->new(app=>$t->app);
$migration->run('-r','-v');

ok($t->app->lib->cache->set(key=>'test', value=>{string_en=>'string', string_ru=>'строка', int=>12345, bool_true=>true, bool_false=>false, smiley=>"\x{2602}"}) == 1, 'set memcached');
my $data = $t->app->lib->cache->get(key=>'test');
ok($data->{'bool_false'} == 0, 'check type bool 0');
ok($data->{'bool_true'} == 1, 'check type bool 1');
ok($data->{'int'} == 12345, 'check type int');
ok($data->{'string_en'} eq 'string', 'check type string_en');
ok($data->{'string_ru'} eq 'строка', 'check type string_ru');
ok($data->{'smiley'} eq '☂', 'check smiley');

ok($t->app->lib->cache->remove(key=>'test') == 1, 'check remove');
ok(!defined $t->app->lib->cache->get(key=>'test') == 1, 'check remove after get');

done_testing();
