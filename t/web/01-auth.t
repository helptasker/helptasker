use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

$t->get_ok('/auth/');
$t->status_is(200);
#$->text_is('div#message' => 'Hello!');

say dumper $t->ua;

$t->get_ok('/auth/registration/');
$t->status_is(200);

#say dumper $t->tx->res->body;

ok(1==1);

done_testing();

