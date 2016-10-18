package HelpTasker::API::GeoIP::MaxMind;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper);
use Carp qw(croak);
use GeoIP2::Database::Reader;
use base 'HelpTasker::API::GeoIP';
use overload bool => sub {1}, fallback => 1;

# http://dev.maxmind.com/geoip/geoip2/geolite2/

sub ip {
    my ($self,$ip) = @_;
    #my $reader = GeoIP2::Database::Reader->new(file=>'/path/to/database', locales => [ 'en' ]);
    return;
}

1;
