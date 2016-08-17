package HelpTasker::Email::Utils;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper trim encode);
use Carp qw(croak);
use Email::Valid;
use Mojo::JSON qw(true false);
use MIME::Words qw(encode_mimeword);
use Email::Address;

sub validator {
    my ($self,$address,$param) = @_;
    my $mxcheck  = $param->{'mxcheck'} // 0;
    my $tldcheck = $param->{'tldcheck'} // 0;
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

