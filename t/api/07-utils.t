use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper b64_decode);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear; # reset db

my $page = $t->app->api->utils->page(1000);
ok($page->{'first_page'} == 1, 'first_page');
ok($page->{'last_page'} == 100, 'last_page');
ok($page->{'limit'} == 10, 'limit');
ok($page->{'next_page'} == 2, 'next_page');
ok($page->{'next_set'} == 11, 'next_set');
ok($page->{'offset'} == 0, 'offset');
ok(ref $page->{'pages_in_set'} eq 'ARRAY', 'pages_in_set');

$page = $t->app->api->utils->page(1000, {current_page=>2});
ok($page->{'first_page'} == 1, 'first_page');
ok($page->{'last_page'} == 100, 'last_page');
ok($page->{'limit'} == 10, 'limit');
ok($page->{'next_page'} == 3, 'next_page');
ok($page->{'next_set'} == 11, 'next_set');
ok($page->{'offset'} == 10, 'offset');
ok($page->{'previous_page'} == 1, 'previous_page');
ok(ref $page->{'pages_in_set'} eq 'ARRAY', 'pages_in_set');

done_testing();

