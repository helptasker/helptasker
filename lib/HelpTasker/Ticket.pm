package HelpTasker::Ticket;
use Mojo::Base 'Mojolicious';
use Mojo::Util qw(dumper);

sub get {
    my $self = shift;
    say dumper $self;
    return;
}


1;

