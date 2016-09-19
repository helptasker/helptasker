package HelpTasker::Controller::Example;
use Mojo::Base 'Mojolicious::Controller';

sub welcome {
    my $self = shift;
    return $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

1;

