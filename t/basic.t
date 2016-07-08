use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
ok(ref $t eq 'Test::Mojo', 'check object');
ok($t->app->config('mysql') eq 'mysql://test@/test', 'config mysql');
like($t->app->mysql->db->query('SELECT VERSION() as version;')->hashes->last->{'version'}, qr/^5/, 'check mysql version');

done_testing();
