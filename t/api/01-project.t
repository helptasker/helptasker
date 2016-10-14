use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
use Try::Tiny;
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
ok(ref $t->app->api->project eq 'HelpTasker::API::Project', 'ok object');
$t->app->api->migration->clear; # reset db

my $project_id = $t->app->api->project->create('test project', {fqdn=>'test_project'});
ok(ref $project_id eq 'HelpTasker::API::Project','check obj');
like($project_id,qr/^[0-9]+$/,'check project_id');

try {
    $t->app->api->project->create();
}
catch {
    like($_, qr/invalid param field:fqdn, check:required/, 'error check fqdn');
};

my $project = $t->app->api->project->get($project_id);
ok(ref $project_id eq 'HelpTasker::API::Project','check obj');
$project = $project->as_hash;
ok($project->{'name'} eq 'test project', 'name');
ok($project->{'fqdn'} eq 'test_project', 'fqdn');
like($project->{'date_create'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'date_create');
like($project->{'date_update'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'date_update');

$project = $t->app->api->project->update($project_id, {name=>'test project2', fqdn=>'test_project2', param=>1});
ok(ref $project eq 'HelpTasker::API::Project','check obj');

$project = $project->get($project)->as_hash;
ok($project->{'name'} eq 'test project2', 'name');
ok($project->{'fqdn'} eq 'test_project2', 'fqdn');
like($project->{'date_create'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'date_create');
like($project->{'date_update'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'date_update');
ok($project->{'settings'}->{'param'} == 1, 'check param');

my $date_update = $project->{'date_update'};
$project = $t->app->api->project->flush($project->{'project_id'})->get($project->{'project_id'})->as_hash;
ok($date_update ne $project->{'date_update'}, 'check flush');

done_testing();
