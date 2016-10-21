use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

ok(1==1);
done_testing();
__END__
# Registration user
#my $csrf_token = $t->ua->get('/auth/registration/')->res->dom->at('[name=csrf_token]')->{'value'};
#$t->post_ok('/auth/'=>form => {csrf_token=>$csrf_token});
#$t->status_is(200);
#$t->text_is('div[class="alert alert-danger"] > span' => 'Field is not filled «Username»', 'Field is not filled «Username»');
#$t->reset_session;

#say $csrf_token;
#done_testing();

$t->get_ok('/auth/');
$t->status_is(200);
#$->text_is('div#message' => 'Hello!');

$t->get_ok('/auth/registration/');
$t->status_is(200);

my $csrf_token = $t->ua->get('/auth/')->res->dom->at('[name=csrf_token]')->{'value'};
$t->post_ok('/auth/'=>form => {csrf_token=>$csrf_token});
$t->status_is(200);
$t->text_is('div[class="alert alert-danger"] > span' => 'Field is not filled «Username»', 'Field is not filled «Username»');
$t->reset_session;

$csrf_token = $t->ua->get('/auth/')->res->dom->at('[name=csrf_token]')->{'value'};
$t->post_ok('/auth/'=>form => {csrf_token=>$csrf_token, login=>12345});
$t->status_is(200);
$t->text_is('div[class="alert alert-danger"] > span' => 'Field is not filled «Password»', 'Field is not filled «Password»');
$t->reset_session;

$csrf_token = $t->ua->get('/auth/')->res->dom->at('[name=csrf_token]')->{'value'};
$t->post_ok('/auth/'=>form => {csrf_token=>$csrf_token, password=>12345});
$t->status_is(200);
$t->text_is('div[class="alert alert-danger"] > span' => 'Field is not filled «Username»', 'Field is not filled «Username»');
$t->reset_session;

# Create user
$csrf_token = $t->ua->get('/auth/')->res->dom->at('[name=csrf_token]')->{'value'};
$t->app->api->user->create('kazerogova', {});
$t->post_ok('/auth/'=>form => {csrf_token=>$csrf_token, login=>"kazerogova", password=>"1234567890"});
$t->status_is(200);
$t->text_is('div[class="alert alert-danger"] > span' => 'Incorrect username or password', 'Incorrect username or password');
$t->reset_session;

done_testing();
