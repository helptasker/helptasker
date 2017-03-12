use Mojo::Base -strict;
use Mojo::Util qw(dumper);
use Mojo::JSON qw(true false);
use Test::More;
use Test::Mojo;
use FindBin;
use Try::Tiny;
use lib "$FindBin::Bin/../lib/";

my $t = Test::Mojo->new('HelpTasker');

$t->app->routes->get('/die')->to(cb => sub {
    my $c = shift;
    die 1;
});


#say dumper 
$t->get_ok('/die')->status_is(500);


done_testing();
