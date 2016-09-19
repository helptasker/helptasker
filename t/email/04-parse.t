use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper slurp);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

ok(ref $t->app->api->email->parse eq 'HelpTasker::API::Email::Parse', 'ok object');

$t->app->api->email->parse->parse(slurp "$FindBin::Bin/email/03.msg");

done_testing();
