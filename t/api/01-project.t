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

subtest 'method create' => sub {
    $t->app->api->migration->clear; # reset db
    my $project = $t->app->api->project->create(name=>'test project', fqdn=>'test_project');
    ok(ref $project eq 'HelpTasker::API::Project', 'ok object');

    $project = $project->to_hash;
    ok($project->{'project_id'} == 1, 'project_id');
    ok($project->{'name'} eq 'test project', 'name');
    ok($project->{'fqdn'} eq 'test_project', 'fqdn');
    like($project->{'date_create'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'date_create');
    like($project->{'date_update'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'date_update');
};

subtest 'method get' => sub {
    $t->app->api->migration->clear; # reset db

    my $project = $t->app->api->project->create(name=>'test project', fqdn=>'test_project');
    ok(ref $project eq 'HelpTasker::API::Project', 'ok object');

    $project = $t->app->api->project->get(project_id=>$project->project_id);
    ok($project->{'project_id'} == 1, 'project_id');
    ok($project->{'name'} eq 'test project', 'name');
    ok($project->{'fqdn'} eq 'test_project', 'fqdn');
    like($project->{'date_create'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'date_create');
    like($project->{'date_update'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'date_update');
};

subtest 'method remove' => sub {
    $t->app->api->migration->clear; # reset db
    my $project = $t->app->api->project->create(name=>'test project', fqdn=>'test_project');
    ok(ref $project eq 'HelpTasker::API::Project', 'ok object');

    $t->app->api->project->remove(project_id=>$project->project_id);

    try {
        $t->app->api->project->get(project_id=>$project->project_id);
    }
    catch {
        like($_, qr/invalid param field:project_id, check:id/, 'ok delete');
    };
};

subtest 'method update' => sub {
    $t->app->api->migration->clear; # reset db
    my $project = $t->app->api->project->create(name=>'test project', fqdn=>'test_project');
    ok(ref $project eq 'HelpTasker::API::Project', 'ok object');

    $project = $t->app->api->project->update(project_id=>$project->project_id, name=>'test project2', fqdn=>'test_project2');
    ok(ref $project eq 'HelpTasker::API::Project', 'ok object');

    $project = $project->get;

    ok($project->{'project_id'} == 1, 'project_id');
    ok($project->{'name'} eq 'test project2', 'name');
    ok($project->{'fqdn'} eq 'test_project2', 'fqdn');
    like($project->{'date_create'}, qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+$/, 'date_create');
    like($project->{'date_update'}, qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+$/, 'date_update');
};

subtest 'error check' => sub {
    $t->app->api->migration->clear; # reset db

    try {
        $t->app->api->project->create(fqdn=>'test project');
    }
    catch {
        like($_, qr/invalid param field:fqdn, check:like/);
    };

    try {
        $t->app->api->project->create(fqdn=>'test_project');
    }
    catch {
        like($_, qr/invalid param field:name, check:required/);
    };

    try {
        $t->app->api->project->create(name=>'test project');
    }
    catch {
        like($_, qr/invalid param field:fqdn, check:required/);
    };
};

subtest 'HTTP API' => sub {
    $t->app->api->migration->clear; # reset db
    $t->post_ok('/api/v1/project/'=>json=>{name=>'test project', fqdn=>'test_project'})
        ->status_is(200)
        ->json_is('/status' => 200)
        ->json_is('/response/fqdn' => 'test_project')
        ->json_is('/response/name' => 'test project')
        ->json_like('/response/date_create' => qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+$/x)
        ->json_like('/response/date_update' => qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+$/x)
        ->json_like('/response/project_id' => qr/^[0-9]+$/x)
    ;

    my $project_id = $t->tx->res->json->{'response'}->{'project_id'};

    $t->get_ok("/api/v1/project/?project_id=$project_id")
        ->status_is(200)
        ->json_is('/status' => 200)
        ->json_is('/response/fqdn' => 'test_project')
        ->json_is('/response/name' => 'test project')
        ->json_like('/response/date_create' => qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+$/x)
        ->json_like('/response/date_update' => qr/^[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+$/x)
        ->json_like('/response/project_id' => qr/^[0-9]+$/x)
    ;
};

#say dumper $t->tx->res->json;




#$t->app->api->project->update(project_id=>1, name=>'test project2', fqdn=>'test_project2');

#$project = $t->app->api->project->get(project_id=>1);
#say dumper $project;


done_testing();
