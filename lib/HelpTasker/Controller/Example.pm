package HelpTasker::Controller::Example;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(dumper);

# This action will render a template
sub welcome {
    my $self = shift;

    my $spec = $self->openapi;
    say dumper $spec;

    # Render template "example/welcome.html.ep" with message
    #$self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
    return $self->render(openapi => {foo => 123});
}

1;
