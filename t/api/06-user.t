use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper b64_decode);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear; # reset db

#$t->app->api->user->create('res', {lastname=>'ыыы', firstname=>' Ten ', email=>' kostya @ yandex . ru'});


ok(1==1);
done_testing();
