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

#my $pg = $t->app->pg;

# Use migrations to create a table
#$pg->migrations->name('my_names_app')->from_string(<<EOF)->migrate;
#-- 1 up
#create table names (id serial primary key, name text);
#-- 1 down
#drop table names;
#EOF
 
# Use migrations to drop and recreate the table
#$pg->migrations->migrate(0)->migrate;


# Insert a few rows
#my $db = $pg->db;
#$db->query('insert into names (name) values (?)', 'Sara');
#$db->query('insert into names (name) values (?)', 'Stefan');

done_testing();

