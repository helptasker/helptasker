use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin;
use lib "$FindBin::Bin/../lib/";

my $t = Test::Mojo->new('HelpTasker');
ok(ref $t eq 'Test::Mojo');

done_testing();
