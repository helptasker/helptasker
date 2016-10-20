use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

$t->get_ok('/auth/');
$t->status_is(200);
#$->text_is('div#message' => 'Hello!');

$t->get_ok('/auth/registration/');
$t->status_is(200);

$t->post_ok('/auth/'=>form => {});
$t->status_is(200);
$t->text_is('div[class="alert alert-danger"] > span' => 'Field is not filled «Username»' , 'Field is not filled «Username»');
$t->reset_session;

$t->post_ok('/auth/'=>form => {login=>12345});
$t->status_is(200);
$t->text_is('div[class="alert alert-danger"] > span' => 'Field is not filled «Password»' , 'Field is not filled «Password»');
$t->reset_session;

$t->post_ok('/auth/'=>form => {password=>12345});
$t->status_is(200);
$t->text_is('div[class="alert alert-danger"] > span' => 'Field is not filled «Username»' , 'Field is not filled «Username»');
$t->reset_session;

# Create user
$t->app->api->user->create('kazerogova', {firstname=>'Kazerogova', lastname=>'Lilu', password=>"123456789", email=>'kazergova@example.com'});
$t->post_ok('/auth/'=>form => {login=>"kazerogova", password=>"1234567890"});
$t->status_is(200);
$t->text_is('div[class="alert alert-danger"] > span' => 'Incorrect username or password' , 'Incorrect username or password');
$t->reset_session;


done_testing();

