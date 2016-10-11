package HelpTasker::API::Email::Send;
use Mojo::Base 'HelpTasker::API::Base';
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
    my $config_validator = {tldcheck => $self->app->config('recipient_check_tld'), mxcheck => $self->app->config('recipient_check_mx')};
    for my $address (uniq @tmp) {
        my $validator = $self->app->api->email->utils->validator($address, $config_validator);
        if(defined $validator && $validator){
            push(@recipients, $address);
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
        Host    => $ENV{'HELPTASKER_SMTP_HOST'}    || $self->app->config('smtp_host'),
        Port    => $ENV{'HELPTASKER_SMTP_PORT'}    || $self->app->config('smtp_port'),
        Timeout => $ENV{'HELPTASKER_SMTP_TIMEOUT'} || $self->app->config('smtp_timeout'),
        Debug   => $ENV{'HELPTASKER_SMTP_DEBUG'}   || $self->app->config('smtp_debug'),
        SSL     => $ENV{'HELPTASKER_SMTP_SSL'}     || $self->app->config('smtp_ssl'),
    ) or croak $!;

    if (defined $self->app->config('smtp_login') && defined $self->app->config('smtp_password')){
        $smtp->auth($self->app->config('smtp_login'), $self->app->config('smtp_password'));
    }

    $smtp->mail($self->from($message)) or croak $!;

    if (!defined $smtp) {
        my $error = $!;
        $error = decode 'UTF-8', $error;
        chomp($error);
        croak $error;
    }

    my @dsn = ();
    push (@dsn, 'SUCCESS') if $self->app->config('smtp_dsn_notify_success');
    push (@dsn, 'FAILURE') if $self->app->config('smtp_dsn_notify_failure');
    push (@dsn, 'DELAY')   if $self->app->config('smtp_dsn_notify_dalay');
    push (@dsn, 'NEVER')   if(!@dsn);

    $self->app->log->debug('SMTP DSN:'.join(", ",@dsn)) if(@dsn);
    $self->app->log->debug('SMTP Recipients:'.join(", ",@{$recipients})) if(@dsn);

    $recipients = $smtp->recipient(@{$recipients});
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

