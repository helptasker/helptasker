use Mojo::Base -strict;
use Mojo::Util qw(dumper);
use Mojo::JSON qw(true false);
use Test::More;
use Test::Mojo;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use HelpTasker::Command::migration;

my $t = Test::Mojo->new('HelpTasker');

my $migration = HelpTasker::Command::migration->new(app=>$t->app);
$migration->run('-r','-v');

#my $user = $t->app->lib->users->create(login=>'kostyaten', firstname=>'Kostya', lastname=>'Ten');

#say $t->app->libs->users->create(login=>'kostya.ten');
#say dumper $t->app->lib->users->create(login=>'kostyaten', firstname=>'Kostya', lastname=>'Ten', is_active=>false);
#my $users = $t->app->lib->users->get(user_id=>1);
#$users = $users->[0];
#say dumper $users->is_enable;
#say dumper $users->is_disable;

#$users->firstname('Kostya')->lastname('Ten')->is_active(1)->save;
#$users->password('qwerty');

#say dumper $users->to_hash;

ok(1==1);
done_testing();
