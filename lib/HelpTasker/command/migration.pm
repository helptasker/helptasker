package HelpTasker::command::migration;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw(dumper);

has description => 'Spy on application';
has usage       => "Usage: APPLICATION spy [TARGET]\n";

sub run {
    my ($self, @args) = @_;
    $self->app->api->migrations->migrate;
    return;
}

1;

