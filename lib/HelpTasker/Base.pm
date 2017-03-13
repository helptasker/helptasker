package HelpTasker::Base;
use Mojo::Base -base;
use Mojo::Util qw(dumper);

has ['pg','log','validation','ua','defaults','lib','model','sql'];

sub config {
    my ($self,$name) = @_;
    return $self->defaults->{'config'}->{$name};
}

1;
