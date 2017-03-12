package HelpTasker;
use Mojo::Base 'Mojolicious';
use Mojo::Pg;
use Mojo::Util qw(dumper trim);
use Mojo::Loader qw(find_modules load_class);
use Mojo::JSON qw(true false);
use Try::Tiny;
use SQL::Abstract::More;
use Email::Valid;
use Number::Phone;
use Carp qw(croak carp);

sub startup {
    my $self = shift;
    $self->moniker('helptasker');

    $self->_namespaces;
    $self->_config;
    $self->_helpers;
    $self->_lib;
    $self->_validator;
    $self->_hooks;

    my $r = $self->routes;
    $r->get('/')->to('example#welcome');

    #$r->get('/test/die/')->to(cb => sub {
    #    my $c = shift;
    #    die 1;
    #});

    return;
}

# Config
sub _config {
    my $self = shift;
    my $config = {
        secrets=>['My very secret passphrase.'],
        postgresql=>'postgresql://test:test@localhost/test',
        session_default_expiration=>600,
    };

    if (defined $ENV{'TRAVIS'} && $ENV{'TRAVIS'} == 1) {
        $config->{'postgresql'} = 'postgresql://postgres@localhost/travis_ci_test';
        $config = $self->plugin('Config', {default => $config});
        return $config;
    }
    else{
        return $self->plugin('Config', {default => $config});
    }
}

# Namespaces
sub _namespaces {
    my $self = shift;
    unshift(@{$self->app->commands->namespaces}, 'HelpTasker::Command');
    return $self;
}

# Helpers
sub _helpers {
    my $self = shift;
    $self->helper('pg' => sub { state $pg = Mojo::Pg->new($self->config('postgresql')) });
    return $self;
}

# Validator
sub _validator {
    my $self = shift;

    # ---- Filter ----
    $self->validator->add_filter(gap => sub {
        my ($validation, $name, $value) = @_;
        $value =~ s/\s+//xg;
        return $value;
    });

    $self->validator->add_filter(lc => sub {
        my ($validation, $name, $value) = @_;
        return lc $value;
    });

    $self->app->validator->add_filter(phone=>sub{
        my ($validation, $name, $value) = @_;
        $value .= "+" if($value !~ /^\+/x);
        my $number_phone = Number::Phone->new($value);
        if(defined $number_phone){
            $number_phone = $number_phone->format;
            $number_phone =~ s/\s+//gx;
            $number_phone =~ s/^\+//gx;
            return int $number_phone;
        }
        return;
    });

    # ---- Check ----
    $self->validator->add_check(email=>sub {
        my ($validation, $field, $value, $args) = @_;
        $value =~ s/\s+//xg;
        $value = lc($value);
        my $mxcheck  = $args->{'mxcheck'}  || undef;
        my $tldcheck = $args->{'tldcheck'} || undef;
        return Email::Valid->address(-address => $value, -mxcheck=>$mxcheck, -tldcheck=>$tldcheck) ? false : true;    
    });

    $self->validator->add_check(phone => sub {
        my ($validation, $field, $value, $args) = @_;
        $value .= "+" if($value !~ /^\+/x);
        my $number_phone = Number::Phone->new($value);
        if (defined $number_phone && $number_phone->is_valid) {
            if (defined $args && $args->{'type'} eq 'mobile' && $number_phone->is_mobile == 1) {
                return 0;
            }
            elsif (defined $args && $args->{'type'} eq 'mobile' && $number_phone->is_mobile != 1) {
                return 1;
            }
            return 0;
        }
        return 1;
    });

    $self->validator->add_check(check_login => sub {
        my ($validation, $field, $value, $args) = @_;
        my ($sql, @bind) = SQL::Abstract::More->new->select(-columns=>[qw/user_id/], -from=>'users', -where=>{login=>$value});
        my $pg = $self->pg->db->query($sql,@bind);
        return 1 if($pg->rows >= 1);
        return;
    });

    $self->validator->add_check(id => sub {
        my ($validation, $field, $value, $args) = @_;
        if($field eq 'user_id'){
            my ($sql, @bind) = SQL::Abstract::More->new->select(-columns=>[qw/user_id/], -from=>'users', -where=>{user_id=>$value});
            my $pg = $self->pg->db->query($sql,@bind);
            return if($pg->rows >= 1);
            return 1;
        }
    });

    return $self;
}

# Lib
sub _lib {
    my $self = shift;
    for my $module (find_modules 'HelpTasker::Lib') {
        my $e = load_class $module;
        carp qq{Loading "$module" failed: $e} and next if ref $e;
        if ($module =~ m/\:\:(?<module>[a-z0-9]+)$/ix) {
            my $l = lc($+{'module'});

            my $pg         = $self->pg;
            my $log        = $self->log;
            my $validation = $self->validation;
            my $ua         = $self->ua;
            my $defaults   = $self->defaults;
            my $sql        = SQL::Abstract::More->new();

            $self->helper('lib.'.$l => sub { $module->new(pg=>$pg, log=>$log, validation=>$validation, ua=>$ua, defaults=>$defaults, sql=>$sql, lib=>$self->lib) });
        }
    }
    return $self;
}

sub _hooks {
    my $self = shift;

    #$self->hook(around_dispatch => sub {
    #    my ($next, $c) = @_;
    #    try {
    #        $next->();
    #    }
    #    catch {
    #        #say $_;
    #        #say '111111111111111';
    #        #$c->__sentry($c,$_);
    #    };
    #    $next->();
    #});
    return;
}

#sub __sentry {
    #my ($self, $c, $message) = @_;
#    return;
#}

1;

