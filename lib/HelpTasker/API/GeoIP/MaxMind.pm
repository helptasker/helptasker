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
    my $validation = $self->validation->input({
        ip=>$ip,
    });
    $validation->required('ip','gap','lc');
    $self->api->utils->error_validation($validation);

    my $file = Mojo::Path->new($self->app->config('api_geo_module_maxmind_base_dir').'/GeoLite2-City.mmdb')->canonicalize;
    croak qq/Permission denied $file/ if(!-r $file);

    my $reader = GeoIP2::Database::Reader->new(file=>$file, locales => [ 'en' ]);
    my $city = $reader->city( ip => $validation->param('ip') );
    my $location = $city->location;
    my $iso_code = $city->country->iso_code;
    return {latitude=>$location->latitude, longitude=>$location->longitude, iso_code=>$iso_code};
}

1;
