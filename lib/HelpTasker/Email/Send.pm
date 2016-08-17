package HelpTasker::Email::Send;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper encode);
use Carp qw(croak);
use Net::SMTP_auth;
use MIME::Parser;
use List::MoreUtils qw(uniq);
use Mojo::JSON qw(true false);

has 'from';

sub recipient {
    my ($self,$message) = @_;

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);
    my $entity = $parser->parse_data(encode('UTF-8', $message));
    my $heads = $entity->head;

    my @tmp = ();
    for my $address (Email::Address->parse($heads->get('to'))) {
        push(@tmp, $address->address);
    }

    for my $address (Email::Address->parse($heads->get('cc'))) {
        push(@tmp, $address->address);
    }

    my @recipients = ();
    if(my $validator_email_address = $self->app->config('validator_email_address')){
        my $mx  = $validator_email_address->{'check'}->{'mx'};
        my $tld = $validator_email_address->{'check'}->{'tld'};

        for my $address (uniq @tmp){
            push(@recipients,$address) if($self->app->api->email->utils->validator($address, {tldcheck=>$tld, mxcheck=>$mx}));
        }
    }

    croak qq/not found recipient/ unless (@recipients);

    return \@recipients;
}

1;
