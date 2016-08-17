package HelpTasker::Email::Utils;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper);
use Carp qw(croak);
use Email::Valid;
use Mojo::JSON qw(true false);

sub validator {
    my ($self,$address,$param) = @_;
    my $mxcheck  = $param->{'mxcheck'} // 0;
    my $tldcheck = $param->{'tldcheck'} // 0;
    return Email::Valid->address(-address => $address, -mxcheck=>$mxcheck, -tldcheck=>$tldcheck) ? true : false
}

1;

