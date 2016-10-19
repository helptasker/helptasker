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

$t->post_ok('/auth/'=>form => {lang=>'ru'});
$t->status_is(200);
$t->text_is('div[class="alert alert-danger"] > span' => 'Не заполнено поле «Пользователь»' , 'Не заполнено поле «Пользователь»');
$t->reset_session;

$t->post_ok('/auth/'=>form => {login=>12345});
$t->status_is(200);
$t->text_is('div[class="alert alert-danger"] > span' => 'Field is not filled «Password»' , 'Field is not filled «Password»');
$t->reset_session;

$t->post_ok('/auth/'=>form => {lang=>'ru', login=>12345});
$t->status_is(200);
$t->text_is('div[class="alert alert-danger"] > span' => 'Не заполнено поле «Пароль»' , 'Не заполнено поле «Пароль»');
$t->reset_session;


done_testing();

