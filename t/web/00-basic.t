use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

note('Manifest');
$t->get_ok('/manifest.json');
$t->status_is(200);
$t->json_is('/background_color'=>'#8290a3');
$t->json_is('/display'=>'standalone');
$t->json_is('/name'=>'HelpTasker Ticket System');
$t->json_is('/short_name'=>'HelpTasker');
$t->json_is('/start_url'=>'/');

done_testing();
