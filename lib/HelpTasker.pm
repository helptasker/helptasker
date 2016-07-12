package HelpTasker;
use Mojo::Base 'Mojolicious';
use Mojo::Util qw(dumper);
use Mojo::Loader qw(find_modules load_class);
use Mojo::mysql;

sub startup {
    my $self = shift;
    $self->init;

    my $r = $self->routes;
    $r->get('/')->to('example#welcome');
    return;
}

sub init {
    my ($self) = @_;
    $self->moniker('helptasker');
    $self->mode('development');

    $self->namespaces;
    $self->type;
    $self->default_config;
    $self->helpers;
    return;
}

sub default_config {
    my ($self) = @_;

    my $config = {};

    if (defined $ENV{'TRAVIS'}) {
        $config = $self->app->plugin('Config', {default => $config});
        $config->{'mysql'} = 'mysql://root@localhost/test';
        return $config;
    }
    elsif (defined $ENV{'MOJO_TEST'} && $ENV{'MOJO_TEST'} == 1) {
        $config = $self->app->plugin('Config', {default => $config});
        $config->{'mysql'} = 'mysql://test@localhost/test';
        return $config;
    }
    else {
        return $self->app->plugin('Config', {default => $config});
    }
}

sub helpers {
    my ($self) = @_;

    $self->helper(
        mysql => sub { state $mysql = Mojo::mysql->new($self->config('mysql')) }
    );

    for my $module (find_modules 'HelpTasker') {
        my $e = load_class $module;
        warn qq{Loading "$module" failed: $e} and next if ref $e;
        if ($module =~ m/\:\:(?<module>([a-z0-9]+))$/i) {
            my $l = lc($+{'module'});
            $self->helper(
                'api.' . $l => sub {
                    my $c   = shift;
                    my $obj = $module->new();
                    $obj->attr(mysql => sub { $c->mysql });
                    $obj->attr(app   => sub { $c->app });
                    return $obj;
                }
            );
        }
    }
    return;
}

sub namespaces {
    my ($self) = @_;
    push @{$self->app->commands->namespaces}, 'HelpTasker::command';
    push @{$self->app->plugins->namespaces},  'HelpTasker::plugin';
    return;
}

sub type {
    my ($self) = @_;
    $self->app->types->type(txt  => 'text/plain; charset=utf-8');
    $self->app->types->type(html => 'text/html; charset=utf-8');
    $self->app->types->type(xml  => 'text/xml; charset=utf-8');
    $self->app->types->type(json => 'application/json; charset=utf-8');
    return;
}

1;

