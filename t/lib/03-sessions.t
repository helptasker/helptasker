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

$t->app->lib->sessions->create();
my $get = $t->app->lib->sessions->get(session_id=>1);
ok($get->valid == 1, 'ok method valid');
ok($get->to_hash->{'age'} > 0, 'ok age');
ok($get->name eq '_default', 'ok name _default');

done_testing();
