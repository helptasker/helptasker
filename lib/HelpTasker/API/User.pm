package HelpTasker::API::User;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper sha1_sum);
use Carp qw(croak);
use Data::Random qw(rand_chars);
use overload bool => sub {1}, '""' => sub {shift->user_id }, fallback => 1;

has [qw(user_id _result)];

sub create {
    my ($self,$login,$args) = @_;
    my $validation = $self->validation->input({
        login=>$login,
        lastname=>delete $args->{'lastname'},
        firstname=>delete $args->{'firstname'},
        password=>delete $args->{'password'},
        email=>delete $args->{'email'},
        settings=>$args,
    });
    $validation->required('lastname','trim');
    $validation->required('firstname','trim');
    $validation->required('login','gap','lc')->size(4,20)->like(qr/^[a-z]{1}[a-z0-9]+[\-\_]?[a-z0-9]+$/x);
    $validation->optional('password','trin')->size(6,50);
    $validation->required('email','gap','lc')->email({mxcheck=>1, tldcheck=>1});
    $validation->optional('settings')->ref('HASH');
    $self->api->utils->error_validation($validation);

    $validation->output->{'settings'} = [ "?::json", {json => $validation->param('settings') } ];
    $validation->output->{'password'} ||= rand_chars(set => 'all', size => 20);
    $validation->output->{'password'} = sha1_sum($validation->output->{'password'});

    my ($sql, @bind) = $self->api->utils->sql->insert(
        -into=>'"user"',
        -values=>$validation->output,
        -returning=>'user_id',
    );
    my $pg = $self->app->pg->db->query($sql,@bind);
    $self->user_id($pg->hash->{'user_id'});

    $self->api->userlog->add(1,$self->user_id,$validation);
    $self->app->log->info('create user - user_id:'.$self->user_id.', '.$self->api->utils->stringify($validation));
    return $self;
}

sub search {
    my ($self,$query,$args) = @_;

    my $input = {};
    if(defined $query && $query =~ m/\@/xi){
        $input = {email=>$query};
    }
    elsif(defined $query && $query =~ m/^[0-9]+$/x){
        $input = {user_id=>$query};
    }
    elsif(defined $query){
        $input = {login=>$query};
    }

    my $validation = $self->validation->input($input);
    $validation->optional('email','gap','lc')->email({mxcheck=>1, tldcheck=>1});
    $validation->optional('user_id');
    $validation->optional('login','gap','lc');
    $self->api->utils->error_validation($validation);

    $query = {
        -columns=>'*',
        -from=>'"user"',
        -order_by=>[qw/-user_id/],
        -where=>$validation->output,
        -limit => 1,
        -offset => 0,
    };

    my $page = $self->api->utils->page($query, $args);
    $query->{'-limit'}  = $page->{'limit'};
    $query->{'-offset'} = $page->{'offset'};

    my ($sql, @bind) = $self->api->utils->sql->select(%{$query});
    my $pg = $self->app->pg->db->query($sql,@bind);

    my @result = ();
    while (my $next = $pg->expand->hash) {
        push(@result,$next);
    }

    $self->_result({result=>\@result, page=>$page});
    return $self;
}

sub as_hash {
    return shift->_result;
}

1;
