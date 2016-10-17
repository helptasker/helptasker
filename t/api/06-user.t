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

$t->app->api->user->create('kostya', {lastname=>' Ten ', firstname=>' Kostya ', email=>' kostya @ yandex . ru'});
#say dumper $t->app->api->user->search('kostya')->as_hash;


ok(1==1);
done_testing();
