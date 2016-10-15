use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper b64_decode);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear; # reset db

my $project_id = $t->app->api->project->create('test project', {fqdn=>'test_project'});

my $queue_id = $t->app->api->queue->create('name queue', {project_id=>$project_id, type=>1});
ok(ref $queue_id eq 'HelpTasker::API::Queue', 'ok object');
like($queue_id, qr/^[0-9]+$/, 'check queue_id');

my $queue = $t->app->api->queue->get($queue_id);
ok(ref $queue eq 'HelpTasker::API::Queue', 'ok object');

$queue = $queue->as_hash;
ok($queue->{'name'} eq 'name queue', 'check name');
like($queue->{'queue_id'}, qr/^[0-9]+$/, 'check queue_id');
like($queue->{'project_id'}, qr/^[0-9]+$/, 'check project_id');
ok($queue->{'name'} eq 'name queue', 'check name');
like($queue->{'date_create'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'check date_create');
like($queue->{'date_update'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'check date_update');
ok(ref $queue->{'settings'} eq 'HASH', 'check data');

$queue = $t->app->api->queue->update($queue_id, {name=>'name queue', type=>2});
ok(ref $queue eq 'HelpTasker::API::Queue','ok object');

$queue = $queue->get($queue)->as_hash;
ok($queue->{'name'} eq 'name queue', 'check name');
like($queue->{'queue_id'}, qr/^[0-9]+$/, 'check queue_id');
like($queue->{'project_id'}, qr/^[0-9]+$/, 'check project_id');
ok($queue->{'name'} eq 'name queue', 'check name');
like($queue->{'date_create'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'check date_create');
like($queue->{'date_update'}, qr/[0-9]{4}-[0-9]{2}-[0-9]{2}\s[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]+\+[0-9]+/, 'check date_update');
ok(ref $queue->{'settings'} eq 'HASH', 'check data');

my $date_update = $queue->{'date_update'};
$queue = $t->app->api->queue->flush($queue->{'queue_id'})->get($queue->{'queue_id'})->as_hash;
ok($date_update ne $queue->{'date_update'}, 'check flush');

done_testing();
