package HelpTasker::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(dumper);

sub login {
    my $self = shift;
    return $self->render();
}

sub registration {
    my $self = shift;
    return $self->render();
}


1;
