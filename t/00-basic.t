use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

ok(ref $t eq 'Test::Mojo', 'check object');
my $version = $t->app->pg->db->query('select version() as version')->hash->{version};
like($version, qr/^PostgreSQL\s9/, 'check PostgreSQL version');

note('i18n');
ok($t->app->l('Registration') eq 'Registration', 'ok i18n');

done_testing();

