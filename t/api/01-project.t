use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

ok(ref $t->app->api->project eq 'HelpTasker::API::Project', 'ok object');

my $project = $t->app->api->project->create(name=>'test project', fqdn=>'test_project');
say $project;

#$project = $t->app->api->project->get(project_id=>1);
#say dumper $project;


done_testing();
