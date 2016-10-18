use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
use HelpTasker::command::maxmind;
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear; # reset db

#say dumper $t->app->api->geoip->address;

my $command = HelpTasker::command::maxmind->new(app=>$t->app);
$command->run();



ok(1==1);
done_testing();
