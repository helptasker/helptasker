package HelpTasker::Base;
use Mojo::Base -base;
use Mojo::Util qw(dumper);

has ['pg','log','validation','ua','defaults','lib','model','sql'];

sub config {
    return $_[0]->defaults->{'config'}->{$_[1]};
}
1;
