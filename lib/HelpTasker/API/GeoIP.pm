package HelpTasker::API::GeoIP;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper);
use Carp qw(croak);

sub location {
    my ($self, $latitude, $longitude) = @_;
    return;
}

1;
