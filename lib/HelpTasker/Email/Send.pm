package HelpTasker::Email::Send;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper encode decode);
use Carp qw(croak);
use Net::SMTP_auth;
use MIME::Parser;
use List::MoreUtils qw(uniq);
use Mojo::JSON qw(true false);

sub recipient {
    my ($self, $message) = @_;

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
    if (my $validator_email_address = $self->app->config('validator_email_address')) {
        my $mx  = $validator_email_address->{'check'}->{'mx'};
        my $tld = $validator_email_address->{'check'}->{'tld'};

        for my $address (uniq @tmp) {
            push(@recipients, $address)
              if (
                $self->app->api->email->utils->validator(
                    $address, {tldcheck => $tld, mxcheck => $mx}
                )
              );
        }
    }

    croak qq/not found recipient/ unless (@recipients);

    return \@recipients;
}

sub from {
    my ($self, $message) = @_;

    my $parser = MIME::Parser->new();
    $parser->output_to_core(1);
    my $entity = $parser->parse_data(encode('UTF-8', $message));
    my $heads = $entity->head;

    for my $address (Email::Address->parse($heads->get('from'))) {
        return $address->address;
    }
    return;
}

sub smtp {
    my ($self, $message) = @_;

    my $recipients = $self->recipient($message);

    my $smtp = Net::SMTP_auth->new(
        Host    => $ENV{'HELPTASKER_SMTP_HOST'}    || $self->app->config('smtp')->{'host'},
        Port    => $ENV{'HELPTASKER_SMTP_PORT'}    || $self->app->config('smtp')->{'port'},
        Timeout => $ENV{'HELPTASKER_SMTP_TIMEOUT'} || $self->app->config('smtp')->{'timeout'},
        Debug   => $ENV{'HELPTASKER_SMTP_DEBUG'}   || $self->app->config('smtp')->{'debug'},
        SSL     => $ENV{'HELPTASKER_SMTP_SSL'}     || $self->app->config('smtp')->{'ssl'},
    ) or croak $!;

    if (   defined $self->app->config('smtp')->{'login'}
        && defined $self->app->config('smtp')->{'password'})
    {
        $smtp->auth($self->app->config('smtp')->{'login'},
            $self->app->config('smtp')->{'password'});
    }

    $smtp->mail($self->from($message)) or croak $!;

    if (!defined $smtp) {
        my $error = $!;
        $error = decode 'UTF-8', $error;
        chomp($error);
        croak $error;
    }

    $recipients = $smtp->recipient(@{$recipients}, $self->app->config('smtp')->{'dsn'});
    if ($recipients) {
        $smtp->data();
        $smtp->datasend($_) for (unpack("(A4096)*", $message));
        $smtp->dataend();
    }
    else {
        my $error = $smtp->message();
        $error = decode 'UTF-8', $error;
        $smtp->quit;
        chomp($error);
        croak $error . ' see status code http://tools.ietf.org/html/rfc5321';
    }

    my $status = $smtp->message();
    $status =~ s/\n//x;
    $status =~ s/\r//xg;
    chomp($status);
    $smtp->quit;

    if ($status =~ m/^([0-9]+\.[0-9]+\.[0-9]+)/x) {
        $status = $1;
        return $status;
    }
    return '0.0.0';
}

1;

