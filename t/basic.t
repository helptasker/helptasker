use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->reset; # reset db

ok(ref $t eq 'Test::Mojo', 'check object');
like($t->app->mysql->db->query('SELECT VERSION() as version;')->hashes->last->{'version'}, qr/^5/, 'check mysql version');
ok($t->app->mysql->db->query('INSERT INTO `test` (`message_text`) VALUES ("I ♥ HelpTasker!");')->affected_rows == 1, 'ok insert data mysql');


done_testing();
