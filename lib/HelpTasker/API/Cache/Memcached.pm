package HelpTasker::API::Cache::Memcached;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper);
use Carp qw(croak);
use Cache::Memcached::Fast;
use overload bool => sub {1}, fallback => 1;

sub memcached {
    my $self = shift;
    my $url = Mojo::URL->new($self->app->config('api_cache_memcached'));

    my $param = {
        servers => [$url->host.':'.$url->port],
        namespace => $url->path || $self->app->mode || 'helptasker',
        connect_timeout => 0.2,
        io_timeout => 0.5,
        close_on_error => 1,
        utf8 => 1,
    };
    return Cache::Memcached::Fast->new($param);
}

sub save {
    my ($self,$key,$value,$expire) = @_;
    my $validation = $self->validation->input({key=>$key, value=>$value});
    $validation->required('key');
    $validation->required('value');
    $validation->optional('expire')->like(qr/^[0-9]+$/x);
    $self->api->utils->error_validation($validation);
    return $self->memcached->set($validation->param('key'), $validation->param('value'), $validation->param('expire') || 60*60*24);
}

sub get {
    my ($self,$key) = @_;
    my $validation = $self->validation->input({key=>$key});
    $validation->required('key');
    $self->api->utils->error_validation($validation);
    return $self->memcached->get($validation->param('key'));
}

sub remove {
    my ($self,$key) = @_;
    my $validation = $self->validation->input({key=>$key});
    $validation->required('key');
    $self->api->utils->error_validation($validation);
    return $self->memcached->delete($validation->param('key'));
}

1;
