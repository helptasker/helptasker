package HelpTasker::API::Session;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper sha1_sum);
use Carp qw(croak);
use Data::Random qw(rand_chars);
use Mojo::JSON qw(true false);

use overload bool => sub {1}, '""' => sub {shift->session_key }, fallback => 1;

has [qw(session_id session_key _result)];

# Create session
sub create {
    my ($self,$name,$args) = @_;
    my $validation = $self->validation->input({
        name=>$name,
        expire=>delete $args->{'expire'} || $self->app->config('session_expire') || 300,
        ip=>delete $args->{'ip'},
        key=>delete $args->{'key'} || sha1_sum(rand_chars(set=>'all', size=>50)),
        data=>$args || {},
    });

    $validation->required('name')->like(qr/^[a-z]{1}[a-z0-9\.\_\-]+$/xi);
    $validation->optional('ip','trim');
    $validation->optional('data');
    $validation->optional('expire')->like(qr/^[0-9]+$/x);
    $validation->optional('key','trim');
    $self->api->utils->error_validation($validation);

    $validation->output->{'data'} = [ "?::json", {json => $validation->param('data') } ];
    $validation->output->{'date_expire'} = Mojo::Date->new(time+$validation->param('expire'));

    my ($sql, @bind) = $self->api->utils->sql->insert(
        -into=>'session',
        -values=>$validation->output,
        -returning=>'session_id',
    );
    my $pg = $self->pg->db->query($sql,@bind);

    $self->session_id($pg->hash->{'session_id'});
    $self->session_key($self->session_id."-".$validation->param('key'));
    return $self;
}

sub get {
    my ($self,$id) = @_;

    my $where = {};
    if(defined $id && $id =~ m/^(?<session_id>[0-9]+)\-(?<key>[0-9a-z]{40})$/xi){
        $where = {session_id=>$+{'session_id'}, key=>$+{'key'}};
    }
    else {
        $where = {session_id=>$id};
    }

    my @columns = qw/session_id key name ip date_expire expire data/;
    push(@columns,'extract(epoch FROM age(date_expire,current_timestamp)) as age');

    my ($sql, @bind) = $self->api->utils->sql->select(-columns=>\@columns, -from=>'session', -where=>$where);
    my $pg = $self->pg->db->query($sql,@bind);

    return $self if(!defined $pg);
    return if($pg->rows == 0);

    my $result = $pg->expand->hash;
    $result->{'is_valid'} = $result->{'age'} > 0 ? true : false;

    $self->session_id($result->{'session_id'});
    $self->session_key($result->{'session_id'}."-".$result->{'key'});
    $self->_result($result);
    return $self;
}

sub remove {
    my ($self,$id) = @_;

    my $where = {};
    if(defined $id && $id =~ m/^(?<session_id>[0-9]+)\-(?<key>[0-9a-z]{40})$/xi){
        $where = {session_id=>$+{'session_id'}, key=>$+{'key'}};
    }
    else {
        $where = {session_id=>$id};
    }

    my ($sql, @bind) = $self->api->utils->sql->delete(-from=>'session',-where=>$where);
    $self->pg->db->query($sql,@bind);
    return;
}

sub as_hash {
    return shift->_result;
}

1;


=encoding utf8
 
=head1 NAME
 
HelpTasker::API::Session - The module works with sessions
 
=head1 SYNOPSIS
 
    my $session = $self->app->api->session; # Create object HelpTasker::API::Session

    # Create session
    $session->create('name_session', {ip=>'127.0.0.1', expire=>300, foo=>'bar'});

    # return example 1-44a6057210a354b44b881ebf95f06f43c7667686
    say $session->session_key;
    # or 
    say "$session";

    # return session id "1"
    say $session->session_id; 

    # Get session
    $session = $self->app->api->session->get($session);
    say dumper $session->as_hash;

    # Delete session
    $self->app->api->session->remove($session);

=head1 ATTRIBUTES

Available after calling methods create or get

=head2 session_key - Returns the session key

    $session->session_key;

=head2 session_id - Returns the identifier

    $session->session_id;


=head1 METHODS

=head2 create - Creates a session

    my $params = {
        ip=>'127.0.0.1', # IP address parameter optional
        expire=>300,     # The lifetime of the session (seconds)
        foo=>'bar'       # hash
    };

    # Return object HelpTasker::API::Session
    my $session = $self->app->api->session->create('name_session',$params);

=head2 get - Getting a session

    # Return object HelpTasker::API::Session
    my $session = $self->app->api->session->get('session_key');

=head2 remove - Deleting a session

    $self->app->api->session->remove('session_key');

    # or

    $self->app->api->session->remove('session_id');

=head2 as_hash

    say dumper $self->app->api->session->get('session_key')->as_hash; # Return ref hashes

=head1 OPERATORS

=head2 bool

    my $bool = !!$session;

=head2 stringify

    my $str = "$session";

=head1 SKILS

    use Carp qw/croak/;
    my $session_name = "auth";
    my $session = $self->app->api->session->create($session_name);

    if(my $session = $self->app->api->session->get($session)){
        croak qq/the session is old/ if($session->as_hash->{'is_valid'} != 1);
        croak qq/the name is not equal to $session_name/ if($session->as_hash->{'name'} ne $session_name);
        say dumper $session->as_hash;
    }
    else{
        croak qq/invalid session/;
    }

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.
 
=cut

