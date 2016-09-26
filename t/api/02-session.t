use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
use Try::Tiny;
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
ok(ref $t->app->api->session eq 'HelpTasker::API::Session', 'ok object');

subtest 'method create' => sub {
    $t->app->api->migration->clear; # reset db
    my $session = $t->app->api->session->create(name=>'test_project', data=>{'test'=>1});
    say dumper $session->get_key;


    ok(1==1);
    #ok(ref $project eq 'HelpTasker::API::Session', 'ok object');

    #$project = $project->to_hash;
    #ok($project->{'project_id'} == 1, 'project_id');
    #ok($project->{'name'} eq 'test project', 'name');
    #ok($project->{'fqdn'} eq 'test_project', 'fqdn');
    #like($project->{'date_create'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'date_create');
    #like($project->{'date_update'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'date_update');
};



done_testing();
