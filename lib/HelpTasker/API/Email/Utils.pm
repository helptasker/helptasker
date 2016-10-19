package HelpTasker::API::Email::Utils;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper trim encode);
use Carp qw(croak);
use Email::Valid;
use Mojo::JSON qw(true false);
use MIME::Words qw(encode_mimeword);
use Email::Address;

sub validator {
    my ($self,$address,$param) = @_;
    my $mxcheck  = $param->{'mxcheck'} || undef;
    my $tldcheck = $param->{'tldcheck'} || undef;
    return Email::Valid->address(-address => $address, -mxcheck=>$mxcheck, -tldcheck=>$tldcheck) ? true : false
}

sub parse_address {
    my ($self,$string) = @_;

    my @result = ();
    for my $data (Email::Address->parse($string)) {
        my $address  = $data->address;
        my $name     = $data->name;
        my $user     = $data->user;
        my $host     = $data->host;
        my $original = $data->original;

        $address = trim(lc($address));
        $host    = trim(lc($host));
        my $mime = Email::Address->new($self->mimeword($name) => $address);
        push(@result, {name => $name, address => $address, user => $user, host => $host, original => $original, mime=>$mime});
    }
    return wantarray ? @result : shift @result;
}

sub mimeword {
    my ($self,$string,$type) = @_;
    return encode_mimeword(encode('UTF-8', $string), $type // 'b', 'UTF-8');
}

1;

=encoding utf8
 
=head1 NAME
 
HelpTasker::API::Email::Utils
 
=head1 SYNOPSIS
 
    my $utils = $t->app->api->email->utils; # Create object HelpTasker::API::Email::Utils

    if($utils->validator('user@gmail.com')){
        say 'ok email';
    }
    else{
        say 'invalid email';
    }

    if($utils->validator('user@gmail.com', {mxcheck=>1, tldcheck=>1})){
        say 'ok email';
    }
    else{
        say 'invalid email';
    }

    say $utils->mimeword('Казерогова Лилу'); # =?UTF-8?B?0JrQsNC30LXRgNC+0LPQvtCy0LAg0JvQuNC70YM=?=

    my $result = $utils->parse_address('"Test User" <devnull@example.com>');
    say dumper $result;

=head1 METHODS

=head2 validator

    my $params = {mxcheck=>1, tldcheck=>1}; # Check MX zone and check TLD zone
    my $result = $self->app->api->email->utils->validator('user@example.com', $params);

=head2 mimeword

    my $result = $self->app->api->email->utils->mimeword('Казерогова Лилу');

=head2 parse_address

    my $result = $self->app->api->email->utils->parse_address('"Test User" <devnull@example.com>');
    say $result->{'address'};  # Email address (devnull@example.com)
    say $result->{'host'};     # Email hostname (example.com)
    say $result->{'name'};     # Name (Test User)
    say $result->{'original'}; # Original string ("Test User" <devnull@example.com>)
    say $result->{'user'};     # Username (devnull)
    say $result->{'mime'};     # Object Email::Address


=cut

