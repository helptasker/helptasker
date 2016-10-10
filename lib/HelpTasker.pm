package HelpTasker;
use Mojo::Base 'Mojolicious';
use Mojo::Util qw(dumper);
use Mojo::Loader qw(find_modules load_class);
use Mojo::Pg;
use Carp;
use Try::Tiny;
use Time::HiRes();

sub startup {
    my $self = shift;
    $self->init;

    return;
}

sub init {
    my ($self) = @_;
    $self->moniker('helptasker');
    $self->mode('development');

    $self->namespaces;
    $self->type;
    $self->default_config;
    $self->logs;
    $self->helpers;
    $self->hooks;
    $self->route;
    $self->validation;
    #say dumper $self->config;

    return;
}

sub route {
    my ($self) = @_;
    my $r = $self->routes;
    #$r->get('/')->to('example#welcome');
    $r->any('/api/:version/:action/'=>[version => ['v1'], method=>qr/[a-z]{1}[0-9a-z]+/ix])->to(controller => 'API');
    $r->any('/api/:version/:action/:param'=>[version => ['v1'], method=>qr/[a-z]{1}[0-9a-z]+/ix, param=>qr/[a-z0-9\;]/x])->to(controller => 'API');
    $r->get('/doc/')->to(controller => 'Doc', action=>'main');
    $r->get('/doc/:module')->to(controller => 'Doc', action=>'main');

    return $r;
}

sub default_config {
    my ($self) = @_;

    my $config = {
        recipient_check_mx=>1,
        recipient_check_tld=>1,
        api_prefix_http_header=>"X-HelpTasker",
        session_expiry=>300,
    };

    if (defined $ENV{'TRAVIS'}) {
        $config = $self->plugin('Config', {default => $config});
        $config->{'pg'} = 'postgresql://postgres@localhost/travis_ci_test';
        return $config;
    }
    elsif (defined $ENV{'MOJO_TEST'} && $ENV{'MOJO_TEST'} == 1) {
        $config = $self->plugin('Config', {default => $config});
        $config->{'pg'} = 'postgresql://test:test@localhost/test';
        return $config;
    }
    else {
        return $self->app->plugin('Config', {default => $config});
    }
}

sub logs {
    my ($self) = @_;
    return;
}

sub helpers {
    my ($self) = @_;

    $self->helper(pg => sub { state $pg = Mojo::Pg->new($self->config('pg')) });
    $self->plugin('ACME');

    for my $module (find_modules 'HelpTasker::API') {
        my $e = load_class $module;
        carp qq{Loading "$module" failed: $e} and next if ref $e;
        if ($module =~ m/\:\:([a-z0-9]+)$/xi) {
            my $l = lc($1);
            $self->helper(
                'api.' . $l => sub {
                    my $c   = shift;
                    my $obj = $module->new(app=>$c->app);
                    return $obj;
                }
            );
        }
    }

    $self->helper('reply.api' => sub {
        my ($c, $json, $param) = @_;
        $param->{'status'} ||= 200;

        if(my $started = $c->stash('mojo.started')){
            my $elapsed = Time::HiRes::tv_interval($started, [Time::HiRes::gettimeofday()]);
            my $rps  = $elapsed == 0 ? '??' : sprintf '%.3f', 1 / $elapsed;
            $c->res->headers->header($c->config('api_prefix_http_header').'-Performance' => "${elapsed}s, $rps/s");
        }

        #$c->res->headers->header('X-HelpTasker-Warnings' => undef);
        $c->res->headers->header($c->config('api_prefix_http_header').'-Version' => $c->stash('version'));

        if($param->{'status'} >= 400){
            return $c->render(json => {error=>$json, status=>$param->{'status'}}, status=>$param->{'status'});
        }
        else{
            return $c->render(json => {response=>$json, status=>$param->{'status'}}, status=>$param->{'status'});
        }
    });

    return;
}

sub hooks {
    my ($self) = @_;
    $self->hook(before_routes => sub {
        my $c = shift;

        my $ip = $c->req->headers->header('X-Real-IP') || $c->req->headers->header('X-Forwarded-For') || $c->tx->remote_address;
        $self->app->log->info('Remote Address ' . $ip);


        #if($c->req->url->to_string =~ m/^\/api\//ix){
        #    if(my $timezone = $c->req->headers->header('x-helptasker-timezone')){
        #        $c->pg->on(connection => sub {
        #            my ($pg, $dbh) = @_;
        #            $dbh->do("SET datestyle TO postgres, dmy;");
        #            $dbh->do("set timezone = '$timezone'");
        #        });
        #    }
        #}
    });

    $self->hook(around_action => sub {
        my ($next, $c, $action, $latest) = @_;

        if($c->stash('controller') eq 'API'){
            try {
                $next->();
            }
            catch {
                my $error = $_;
                if($error =~ m/^invalid\sparam/x){
                    if($error =~ /^([a-z0-9\s,:\[\]]+),\spackage/xi){
                        $c->reply->api($1, {status=>400});
                    }
                    else{
                        $c->reply->api($error, {status=>500});
                    }
                }
                else {
                    $c->reply->api($error, {status=>500});
                }
            };
        }
        else{
            return $next->();
        }
    });

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

sub validation {
    my ($self) = @_;

    # Проверки сущестрования индификаторов
    $self->app->validator->add_check(
        id => sub {
            my ($c, $field, $value, @args) = @_;
            if(defined $field && $field eq 'project_id' && defined $value && $value){
                my $pg = $self->app->pg->db->query("SELECT project_id FROM projects WHERE project_id = ? LIMIT 1",$value);
                my $rows = $pg->rows;
                return defined $rows && $rows ? undef : 1;
            }
        }
    );
    return;
}

1;

=encoding utf8
 
=head1 NAME
 
L<HelpTasker> - A powerful tool for creating technical support, and for the accounting system bugs

=head1 Modules
 
L<HelpTasker::API::Session> - A powerful tool for creating technical support, and for the accounting system bugs
 
=head1 SEE ALSO
 
L<http://helptasker.org>.


=cut

