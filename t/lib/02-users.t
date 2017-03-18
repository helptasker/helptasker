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

note('create');
my $user = $t->app->lib->users->create(login=>'KAZEROGOVA', firstname=>'Lilu', lastname=>'Kazerogova', email=>'devnull@yandex.ru', password=>'1234567890');
like($user->to_hash->{'date_create'}->to_datetime, qr/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]+Z$/, 'date_create');
like($user->to_hash->{'date_update'}->to_datetime, qr/^[0-9]{4}\-[0-9]{2}\-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]+Z$/, 'date_update');
ok($user->to_hash->{'user_id'} == 1, 'user_id');
ok($user->to_hash->{'firstname'} eq 'Lilu', 'firstname');
ok($user->to_hash->{'lastname'} eq 'Kazerogova', 'lastname');
ok($user->to_hash->{'login'} eq 'kazerogova', 'login');
ok($user->to_hash->{'email'} eq 'devnull@yandex.ru', 'email');
ok($user->to_hash->{'password'} eq '01b307acba4f54f55aafc33bb06bbbf6ca803e9a', 'password');

subtest 'sub test User.pm' => sub {
    ok($user->user_id == 1, 'user_id');
    ok($user->firstname eq 'Lilu', 'firstname');
    ok($user->lastname eq 'Kazerogova', 'lastname');
    ok($user->login eq 'kazerogova', 'login');
    ok($user->email eq 'devnull@yandex.ru', 'email');
    ok($user->password eq '01b307acba4f54f55aafc33bb06bbbf6ca803e9a', 'password');
};

subtest 'sub test User.pm save' => sub {
    $user->firstname('Seraya');
    $user->save;
    ok($user->firstname eq 'Seraya', 'update check');
};

done_testing();
