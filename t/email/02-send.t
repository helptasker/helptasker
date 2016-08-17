use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper punycode_decode punycode_encode slurp b64_decode);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

ok(ref $t->app->api->email->message eq 'HelpTasker::Email::Message', 'ok object');

my $message = $t->app->api->email->message;

$message->from('"Вася Пупкин" <pupkin@example.com>');
$message->to(["devnull\@yandex.ru","devnull\@yandex.ru"]);
$message->body("Тест");
$message->content_type('plain/text; charset="UTF-8"');
$message = $message->render;

my $recipient = $t->app->api->email->send->recipient($message);
ok(shift @{$recipient} eq 'devnull@yandex.ru', 'ok recipient');

ok($t->app->api->email->send->from($message) eq 'pupkin@example.com', 'ok from');

SKIP: {
    skip "SMTP module, not configure", 1 if !defined $t->app->config('smtp');

    $message = $t->app->api->email->message;
    $message->from('"Testing" <kostya@yandex.com>');
    $message->to(['devnull@yandex-team.ru']);
    $message->body("Тест");
    $message->content_type('plain/text; charset="UTF-8"');
    $message = $message->render;
    ok($t->app->api->email->send->smtp($message) eq '2.0.0', 'ok status smtp');
};


done_testing();
