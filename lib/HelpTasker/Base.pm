package HelpTasker::Base;
use Mojo::Base -base;


sub app {
    my $self = shift;
    return $self->{'app'};
}

1;
