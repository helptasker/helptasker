use Mojo::Base -strict;
use Mojo::Util qw(dumper);
use Mojo::JSON qw(true false);
use Test::More;
use Test::Mojo;
use FindBin;
use Try::Tiny;
use lib "$FindBin::Bin/../lib/";
use HelpTasker::Command::migration;

my $t = Test::Mojo->new('HelpTasker');
my $migration = HelpTasker::Command::migration->new(app=>$t->app);
$migration->run('-r','-v');

note('filter');
my $validation = $t->app->validator->validation->input({string=>' Kazerogova Lilu '});
$validation->required('string','gap');
ok($validation->param('string') eq 'KazerogovaLilu', 'filter gap');

$validation = $t->app->validator->validation->input({string=>' Kazerogova Lilu '});
$validation->required('string','lc');
ok($validation->param('string') eq ' kazerogova lilu ', 'filter lc');

$validation = $t->app->validator->validation->input({string=>' Kazerogova Lilu '});
$validation->required('string','trim');
ok($validation->param('string') eq 'Kazerogova Lilu', 'filter trim');

$validation = $t->app->validator->validation->input({phone=>'7 (909) 000-00-00'});
$validation->required('phone','phone');
ok($validation->param('phone') eq '79090000000', 'filter phone');

$validation = $t->app->validator->validation->input({phone=>'+7 (909) 000-00-00'});
$validation->required('phone','phone');
ok($validation->param('phone') eq '79090000000', 'filter phone 2');

note('check');
$validation = $t->app->validator->validation->input({email=>'Devnull@example.com'});
$validation->required('email')->email;
ok($validation->param('email') eq 'Devnull@example.com', 'check email');

$validation = $t->app->validator->validation->input({email=>'devnull@example.ssssssssssssssssssssssssss'});
$validation->required('email')->email({mxcheck=>1, tldcheck=>1});
ok($validation->has_error('email') == 1, 'invalid email devnull@example.ssssssssssssssssssssssssss');

$validation = $t->app->validator->validation->input({email=>'devnullexample.com'});
$validation->required('email')->email();
ok($validation->has_error('email') == 1, 'invalid email devnullexample.com');

$validation = $t->app->validator->validation->input({phone=>'+7 (909) 000-00-00'});
$validation->required('phone','phone')->phone({type=>'mobile'});
ok($validation->param('phone') eq '79090000000', 'phone mobile');

$validation = $t->app->validator->validation->input({phone=>'+7 (495) 000-00-00'});
$validation->required('phone','phone')->phone({type=>'mobile'});
ok($validation->has_error('phone') == 1, 'invalid phone mobile');

$validation = $t->app->validator->validation->input({phone=>'+7 (495) 000-00-00'});
$validation->required('phone','phone')->phone();
ok($validation->param('phone') eq '74950000000', 'phone mobile2');

$t->app->lib->users->create(login=>'kazerogova', firstname=>'Lilu', lastname=>'Kazerogova', email=>'devnull@yandex.ru', password=>'1234567890');
try {
    $t->app->lib->users->create(login=>'kazerogova', firstname=>'Lilu', lastname=>'Kazerogova', email=>'devnull@yandex.ru', password=>'1234567890');
}
catch {
    like($_, qr/^invalid param field:login, check:check_login/, 'user already exists');
};

$validation = $t->app->validator->validation->input({object=>bless(my $res = {},'Testing::Module')});
$validation->required('object')->ref('Testing::Module');
ok(ref $validation->param('object') eq 'Testing::Module', 'object Testing::Module');

$validation = $t->app->validator->validation->input({object=>bless(my $res2 = {},'Testing::Module')});
$validation->required('object')->ref('Testing::Module::Error');
ok(ref $validation->param('object') ne 'Testing::Module', 'invalid object Testing::Module');


done_testing();
