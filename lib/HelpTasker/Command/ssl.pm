package HelpTasker::Command::ssl;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw(dumper);
use Net::SSLeay qw(get_https post_https sslcat make_headers make_form);
use IO::Socket::SSL;
use Term::ANSIColor qw(:constants);
use Carp qw(croak);


# Short description
has description => 'SSL check certificate';
 
# Usage message from SYNOPSIS
has usage => sub { shift->extract_usage };
 
sub run {
    my ($self, $host) = @_;
    $host = "https://".$host if($host !~ m/^http/x);
    my $url = Mojo::URL->new($host);

    my $srv = IO::Socket::SSL->new(PeerHost => $url->host, PeerPort => 'https', SSL_verify_mode => SSL_VERIFY_PEER, SSL_ocsp_mode => SSL_OCSP_FULL_CHAIN) or croak "failed connect or ssl handshake: $!,$SSL_ERROR";

    my @alt_names = $srv->peer_certificate('subjectAltNames');
    @alt_names = grep {$_ !~ /^[0-9]+$/x } @alt_names;

    say BOLD, BLUE, "AltNames:", RESET.' '.BOLD, GREEN, join(", ",@alt_names), RESET;
    say BOLD, BLUE, "Cipher:", RESET.' '.BOLD, RED, $srv->get_cipher, RESET;
    say BOLD, BLUE, "SSL Version:", RESET.' '.BOLD, YELLOW, $srv->get_sslversion, RESET;
    say BOLD, BLUE, "Server name:", RESET.' '.BOLD, YELLOW, $srv->get_servername, RESET;
    return;
}
 
1;
 
=encoding utf8
 
=head1 NAME
 
HelpTasker::Command::ssl - SSL check command certificate
 
=head1 SYNOPSIS
 
  Usage: APPLICATION ssl [HOST]
 
    helptasker ssl https://google.com
 
  Options:
    -h, --help      Show this summary of available options

=head1 SEE ALSO
 
L<HelpTasker>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.
 
=cut

