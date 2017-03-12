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



done_testing();
