package HelpTasker::Lib::Cache::Memcached;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper);
use Mojo::JSON qw(true false);
use Cache::Memcached::Fast;
use Carp qw(croak);

sub memcached {
    my $self = shift;
    my $url = Mojo::URL->new($self->config('cache_memcached_host'));

    my $config = {servers => [$url->host.':'.$url->port], utf8 => 1, max_size=>512 * 1024};
    $config->{'namespace'} = $url->path->to_abs_string if(defined $url->path);

    return Cache::Memcached::Fast->new($config);
}

sub get {
    my ($self,%param) = @_;
    $self->validation->input(\%param);
    $self->validation->required('key','lc','gap');
    $self->lib->utils->validation_error($self->validation);
    return $self->memcached->get($self->validation->param('key'));
}

sub set {
    my ($self,%param) = @_;
    $self->validation->input(\%param);
    $self->validation->required('key','lc','gap');
    $self->validation->required('value')->ref('HASH');
    $self->validation->optional('expiration')->like(qr/^[0-9]+$/x);
    $self->lib->utils->validation_error($self->validation);

    my $key        = $self->validation->param('key');
    my $value      = $self->validation->param('value');
    my $expiration = $self->validation->param('expiration');
    return $self->memcached->set($key,$value,$expiration);
}

sub remove {
    my ($self,%param) = @_;
    $self->validation->input(\%param);
    $self->validation->required('key','lc','gap');
    $self->lib->utils->validation_error($self->validation);
    return $self->memcached->delete($self->validation->param('key'));
}


1;
