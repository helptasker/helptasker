package HelpTasker;
use Mojo::Base 'Mojolicious';
use Mojo::Util qw(dumper decode);
use Mojo::Loader qw(find_modules load_class);
use Mojo::Pg;
use Carp;
use Try::Tiny;
use Time::HiRes();
use HelpTasker::API::I18N;
use I18N::LangTags::Detect;
use I18N::LangTags;
use Text::Xslate;

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

    #$self->app->api->migration->clear;

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

    $r->any(['GET', 'POST'] => '/auth/')->to(controller => 'Auth', action=>'login', handler=>'tx');
    $r->any(['GET', 'POST'] => '/auth/registration/')->to(controller => 'Auth', action=>'registration', handler=>'tx');
    return $r;
}

sub default_config {
    my ($self) = @_;

    my $config = {
        recipient_check_mx=>1,
        recipient_check_tld=>1,
        api_prefix_http_header=>"X-HelpTasker",
        session_expiry=>300,

        i18n_default_language=>'en',
        cdn_host=>'https://helptasker.github.io/',
        api_email_mime_default_to=>'devnull@helptasker.org',
        api_email_mime_default_from=>'devnull@helptasker.org',
        api_email_mime_default_subject=>'No Subject',
        api_email_mime_template=>'HelpTasker::API::Email::Mime',
        api_email_mime_template_section=>'auto_template',
        api_email_mime_encode=>'base64',
        api_cache_module=>'HelpTasker::API::Cache::DB',
        api_geo_module=>'HelpTasker::API::GeoIP::MaxMind',
        api_geo_module_maxmind_base_dir=>'/var/tmp/maxmind/',
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
        next if($module eq 'HelpTasker::API::GeoIP');
        next if($module eq 'HelpTasker::API::I18N');

        my $e = load_class $module;
        carp qq{Loading "$module" failed: $e} and next if ref $e;
        if ($module =~ m/\:\:([a-z0-9]+)$/xi) {
            my $l = lc($1);
            $self->helper('api.' . $l => sub {
                my $c   = shift;
                return $module->new(app=>$c->app);
            });
        }
    }

    # Loader module cache
    if(my $module = $self->app->config('api_cache_module')){
        my $e = load_class $module;
        carp qq{Loading "$module" failed: $e} and next if ref $e;
        $self->helper('api.cache' => sub {
            my $c   = shift;
            return $module->new(app=>$c->app);
        });
    }

    # Loader module geo
    if(my $module = $self->app->config('api_geo_module')){
        my $e = load_class $module;
        carp qq{Loading "$module" failed: $e} and next if ref $e;
        $self->helper('api.geoip' => sub {
            my $c   = shift;
            return $module->new(app=>$c->app);
        });
    }

    # Loader i18n
    my $lh = HelpTasker::API::I18N->new;

    # Helper l
    $self->helper(l => sub {
        my ($c, $text, @args) = @_;
        if(defined $text && $text){
            my $get = $lh->get_handle($c->stash('i18n_language'));
            $c->stash(language=>$get->language_tag);
            return $get->maketext($text,@args);
        }
        else{
            my $get = $lh->get_handle($c->stash('i18n_language'));
            $c->stash(language=>$get->language_tag);
            return $get->language_tag;
        }
    });

    # Helper language
    $self->helper(language => sub {
        return shift->stash('language');
    });

    # Helper CDN host
    $self->helper(cdn_host => sub {
        my ($c, $path) = @_;
        my $url = Mojo::URL->new($c->app->config('cdn_host'));
        $url->path($path);
        return $url;
    });

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

	# Xslate
	my $tx = Text::Xslate->new({
		path=>$self->renderer->paths,
	});

	$self->renderer->add_handler(tx=>sub {
		my ($renderer, $c, $output, $options) = @_;
		my $template = $c->stash->{'template_name'} || $renderer->template_name($options);
		my %params = (%{$c->stash}, c=>$c);

		if(defined(my $inline = $options->{inline})) {
			return $$output = $tx->render_string($inline, \%params);
		}
		else {
			$$output = $tx->render($template, \%params);
		}
		return 1;
	});

    return;
}

sub hooks {
    my ($self) = @_;

    $self->hook(before_routes => sub {
        my $c = shift;
		#$c->stash(param=>$c->req->params->to_hash);

        #my $ip = $c->req->headers->header('X-Real-IP') || $c->req->headers->header('X-Forwarded-For') || $c->tx->remote_address;
        #$self->app->log->info('Remote Address ' . $ip);
        #$self->app->log->info('Accept Language ' . $c->req->headers->accept_language);

        # Detect language header Accept-Language
        if(my $language = $c->req->cookie('language')){
            $c->stash(i18n_language => $language->value);
        }
        else{
            if(my $accept_language = $c->req->headers->accept_language){
                my @languages = I18N::LangTags::implicate_supers(I18N::LangTags::Detect->http_accept_langs($accept_language));
                if(@languages){
                    $c->stash(i18n_language => shift @languages);
                }
                else {
                    $c->stash(i18n_language => $self->app->config('i18n_default_language'));
                }
            }
            else {
                $c->stash(i18n_language => $self->app->config('i18n_default_language'));
            }
            $c->res->cookies({name => 'language', value => $c->stash('i18n_language'), path=>'/', max_age=>60*60*24*365});
        }

        # Params lang=en
        if(my $lang = $c->req->params->param('lang')){
            $c->stash(i18n_language => $lang);
            $c->res->cookies({name => 'language', value => $lang, path=>'/', max_age=>60*60*24*365});
        }

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
        return $next->();
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

    $self->app->validator->add_check(
        id => sub {
            my ($c, $field, $value, @args) = @_;
            if(defined $field && $field eq 'project_id' && defined $value && $value){
                my ($sql, @bind) = $self->api->utils->sql->select(-columns=>[qw/project_id/], -from=>'project', -where=>{project_id=>$value});
                my $pg = $self->app->pg->db->query($sql,@bind);
                my $rows = $pg->rows;
                return defined $rows && $rows ? undef : 1;
            }
            elsif(defined $field && $field eq 'queue_id' && defined $value && $value){
                my ($sql, @bind) = $self->api->utils->sql->select(-columns=>[qw/queue_id/], -from=>'queue', -where=>{queue_id=>$value});
                my $pg = $self->app->pg->db->query($sql,@bind);
                my $rows = $pg->rows;
                return defined $rows && $rows ? undef : 1;
            }
            elsif(defined $field && $field eq 'user_id' && defined $value && $value){
                my ($sql, @bind) = $self->api->utils->sql->select(-columns=>[qw/user_id/], -from=>'"user"', -where=>{user_id=>$value});
                my $pg = $self->app->pg->db->query($sql,@bind);
                my $rows = $pg->rows;
                return defined $rows && $rows ? undef : 1;
            }
        }
    );

    $self->app->validator->add_check(
        exist => sub {
            my ($c, $field, $value, $args) = @_;
            if(defined $field && $field eq 'login' && defined $value && $value){
                my ($sql, @bind) = $self->api->utils->sql->select(-columns=>[qw/user_id/], -from=>'"user"', -where=>{login=>$value});
                my $pg = $self->app->pg->db->query($sql,@bind);
                my $rows = $pg->rows;
                return defined $rows && $rows ? undef : 1;
            }
        }
    );

    $self->app->validator->add_check(
        not_exist => sub {
            my ($c, $field, $value, $args) = @_;
            if(defined $field && $field eq 'login' && defined $value && $value){
                my ($sql, @bind) = $self->api->utils->sql->select(-columns=>[qw/user_id/], -from=>'"user"', -where=>{login=>$value});
                my $pg = $self->app->pg->db->query($sql,@bind);
                my $rows = $pg->rows;
                return defined $rows && $rows ? 1 : undef;
            }
        }
    );

    # Email address
    $self->app->validator->add_check(
        email => sub {
            my ($c, $field, $value, $args) = @_;
            return $self->app->api->email->utils->validator($value,$args) ? undef : 1;
        }
    );



    # Ref object
    $self->app->validator->add_check(
        ref => sub {
            my ($c, $field, $value, $args) = @_;
            return ref $value eq $args ? undef : 1;
        }
    );

    # FILTERS
    $self->app->validator->add_filter(lc=>sub{
        my ($validation, $name, $value) = @_;
        return lc $value;
    });

    $self->app->validator->add_filter(gap=>sub{
        my ($validation, $name, $value) = @_;
        $value =~ s/\s+//gx;
        return $value;
    });

    $self->app->validator->add_filter(oauth_login=>sub{
        my ($validation, $name, $value) = @_;
        $value =~ s/\,//gx;
        $value =~ s/\.//gx;
        return $value;
    });


    return;
}

1;

=encoding utf8
 
=head1 NAME
 
L<HelpTasker> - A powerful tool for creating technical support, and for the accounting system bugs

=head1 Modules
 
L<HelpTasker::API::Session> - A powerful tool for creating technical support, and for the accounting system bugs

L<HelpTasker::API::Email::Mime>

L<HelpTasker::API::Email::Utils>

 
=head1 SEE ALSO
 
L<http://helptasker.org>.


=cut

