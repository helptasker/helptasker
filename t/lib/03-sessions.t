use Mojo::Base -strict;
use Mojo::Util qw(dumper);
use Mojo::JSON qw(true false);
use Test::More;
use Test::Mojo;
use Try::Tiny;
use FindBin;
use lib "$FindBin::Bin/../../lib/";
use HelpTasker::Command::migration;

my $t = Test::Mojo->new('HelpTasker');

my $migration = HelpTasker::Command::migration->new(app=>$t->app);
$migration->run('-r','-v');

note('null session');
$t->app->lib->sessions->create();
my $get = $t->app->lib->sessions->get(session_id=>1);

ok($get->valid == 1, 'ok method valid');
ok($get->to_hash->{'age'} > 0, 'ok age');
ok(ref $get->to_hash->{'data'} eq 'HASH', 'ok data');
like($get->to_hash->{'date_create'}->to_datetime, qr/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.?[0-9]*Z?$/, 'ok date_create');
like($get->to_hash->{'date_update'}->to_datetime, qr/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.?[0-9]*Z?$/, 'ok date_update');
like($get->to_hash->{'date_expire'}->to_datetime, qr/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.?[0-9]*Z?$/, 'ok date_expire');
like($get->to_hash->{'expiration'}, qr/^[0-9]+$/, 'ok expiration');
ok($get->to_hash->{'name'} eq '_default', 'ok name');
like($get->to_hash->{'session_id'}, qr/^[0-9]+$/, 'ok session_id');
like($get->to_hash->{'session_key'}, qr/^[0-9]+\.[0-9a-z]{40}$/i, 'ok session_key');


done_testing();
