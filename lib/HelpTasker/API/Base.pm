package HelpTasker::API::Base;
use Mojo::Base -base;
use Mojo::Util qw(dumper);

sub app {
    my $self = shift;
    return $self->{'app'};
}

sub pg {
    my $self = shift;
    return $self->app->pg;
}

sub api {
    my $self = shift;
    return $self->app->api;
}

sub validation {
    my $self = shift;
    return $self->app->validator->validation;

}

1;
