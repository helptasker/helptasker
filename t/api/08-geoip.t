use Mojo::Base -strict;
use FindBin;
use lib "$FindBin::Bin/../lib/";
use Test::More;
use Test::Mojo;
use Mojo::Util qw(dumper);
use HelpTasker::command::maxmind;
$ENV{'MOJO_TEST'} = 1;

my $t = Test::Mojo->new('HelpTasker');
$t->app->api->migration->clear; # reset db

SKIP: {
    skip 'Skip travis', 6 if defined $ENV{'TRAVIS'} && $ENV{'TRAVIS'} eq 'true';
    my $location = $t->app->api->geoip->ip('2a02:6b8::feed:0ff');
    ok($location->{'iso_code'} eq 'RU', 'iso_code');
    ok($location->{'latitude'} eq '55.7522', 'latitude');
    ok($location->{'longitude'} eq '37.6156', 'longitude');

    $location = $t->app->api->geoip->ip('8.8.8.8');
    ok($location->{'iso_code'} eq 'US', 'iso_code');
    ok($location->{'latitude'} eq '37.386', 'latitude');
    ok($location->{'longitude'} eq '-122.0838', 'longitude');

};

done_testing();
