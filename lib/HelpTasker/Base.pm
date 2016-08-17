package HelpTasker::Base;
use Mojo::Base -base;


sub app {
    my $self = shift;
    return $self->{'app'};
}


sub api {
    my $self = shift;
    return $self->app->api;
}

1;
