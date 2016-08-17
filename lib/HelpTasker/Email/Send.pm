package HelpTasker::Email::Send;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper encode);
use Carp qw(croak);
use Net::SMTP_auth;
use MIME::Parser;
use List::MoreUtils qw(uniq);
use Email::Valid;

has 'from';

sub recipient {
    my ($self,$message) = @_;

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);
    my $entity = $parser->parse_data(encode('UTF-8', $message));
    my $heads = $entity->head;

    my @recipient = ();

    for my $address (Email::Address->parse($heads->get('to'))) {
        push(@recipient, $address->address);
    }

    for my $address (Email::Address->parse($heads->get('cc'))) {
        push(@recipient, $address->address);
    }
    @recipient = uniq @recipient;

    croak qq/not found recipient/ unless (@recipient);

    return \@recipient;
}

1;
