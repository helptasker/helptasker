use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear;    # reset db

ok(ref $t eq 'Test::Mojo', 'check object');

my $result = $t->app->validator->validation->input({email=>'test@@example.com'})->required('email')->email->is_valid('email');
ok($result != 1, 'not valid email test@@example.com');

$result = $t->app->validator->validation->input({email=>'test@examplesssssssssssss.com'})->required('email')->email({mxcheck=>1})->is_valid('email');
ok($result != 1, 'not valid email test@examplesssssssssssss.com (mxcheck=>1)');

$result = $t->app->validator->validation->input({email=>'test@examplesssssssssssss.dddddd'})->required('email')->email({tldcheck=>1})->is_valid('email');
ok($result != 1, 'not valid email test@examplesssssssssssss.dddddd (tldcheck=>1)');

$result = $t->app->validator->validation->input({email=>'test@example.com'})->required('email')->email->is_valid('email');
ok($result == 1, 'valid email test@example.com');

$result = $t->app->validator->validation->input({ref=>{test=>1}})->required('ref')->ref('HASH')->is_valid('ref');
ok($result == 1, 'valid ref HASH');

$result = $t->app->validator->validation->input({ ref=>[{test=>1}] })->required('ref')->ref('HASH')->is_valid('ref');
ok($result == 1, 'valid ref HASH in Array');

$result = $t->app->validator->validation->input({ ref=>$t })->required('ref')->ref('Test::Mojo')->is_valid('ref');
ok($result == 1, 'valid ref Test::Mojo');

$result = $t->app->validator->validation->input({ string=>' hello ' })->required('string','gap');
ok($result->param('string') eq 'hello', 'check filter gap');

$result = $t->app->validator->validation->input({ string=>' hel lo ' })->required('string','gap');
ok($result->param('string') eq 'hello', 'check filter gap (2)');

$result = $t->app->validator->validation->input({ string=>' При вет ' })->required('string','gap');
ok($result->param('string') eq 'Привет', 'check filter gap (3)');

$result = $t->app->validator->validation->input({ string=>'HELLO' })->required('string','lc');
ok($result->param('string') eq 'hello', 'check filter lc');

$result = $t->app->validator->validation->input({ string=>'ПРИВЕТ' })->required('string','lc');
ok($result->param('string') eq 'привет', 'check filter lc (2)');


done_testing();
