package HelpTasker::Base;
use Mojo::Base -base;


sub app {
    my $self = shift;
    return $self->{'app'};
}

sub config {
    my $self = shift;
    return $self->{'app'}->{'config'};
}

1;
