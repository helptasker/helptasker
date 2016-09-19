package HelpTasker::API::Ticket;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper);

sub get {
    my $self = shift;
    say dumper $self;
    return;
}


1;

