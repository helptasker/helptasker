use Mojo::Base -strict;
use Mojo::Util qw(dumper);
use Test::More;
use Test::Mojo;
use FindBin;
use Try::Tiny;
use lib "$FindBin::Bin/../../lib/";
use HelpTasker::Command::migration;

my $t = Test::Mojo->new('HelpTasker');

my $migration = HelpTasker::Command::migration->new(app=>$t->app);
$migration->run('-r','-v');

note('error_tx');
my $tx = $t->app->ua->get('http://example.org/404/');
try {
    $t->app->lib->utils->error_tx($tx);
}
catch {
    like($_, qr/^404 Not Found, http:\/\/example.org\/404\//, 'check 404');
};

$tx = $t->app->ua->get('http://example.org/');
$tx = $t->app->lib->utils->error_tx($tx);
like($tx->result->body, qr/This domain is established to be used for illustrative examples in documents. You may use this/, 'check 200');


note('validation_error');
my $validation = $t->app->validation->input({str=>1});
$validation->required('str')->like(qr/^[a-z]+$/x);

try {
    $t->app->lib->utils->validation_error($validation);
}
catch {
    like($_, qr/^invalid param field:str, check:like/, 'check invalid param');
};

$validation = $t->app->validation->input({str=>1});
$validation->required('str')->like(qr/^[0-9]+$/x);
ok($validation->param('str') == 1, 'check valid param');

note('declination_by_numbers');
ok($t->app->lib->utils->declination_by_numbers(1,'Яблоко','Яблока','Яблок') eq 'Яблоко', 'form 1');
ok($t->app->lib->utils->declination_by_numbers(22,'Яблоко','Яблока','Яблок') eq 'Яблока', 'form 2');
ok($t->app->lib->utils->declination_by_numbers(30,'Яблоко','Яблока','Яблок') eq 'Яблок', 'form 3');

#note('random');
#my $random = $t->app->lib->utils->random('alpha',40);
#like($random, qr/[a-zA-Z]{40}/, 'alpha');

#$random = $t->app->lib->utils->random('upperalpha',20);
#like($random, qr/[A-Z]{20}/, 'upperalpha');

#$random = $t->app->lib->utils->random('loweralpha',20);
#like($random, qr/[a-z]{20}/, 'loweralpha');

#$random = $t->app->lib->utils->random('numeric',10);
#like($random, qr/[0-9]{10}/, 'numeric');


done_testing();

