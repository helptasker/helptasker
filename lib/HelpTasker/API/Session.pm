package HelpTasker::API::Session;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper sha1_sum);
use Carp qw(croak);
use Net::IP;
use Data::Random qw(rand_chars);
use Mojo::JSON qw(true false);
use overload bool => sub {1}, '""' => sub {shift->session_key }, fallback => 1;

has [qw(session_id session_key _result)];

# Create session
sub create {
    my ($self,$name,$args) = @_;
    my $validation = $self->validation->input({name=>$name, expire=>delete $args->{'expire'}, ip=>delete $args->{'ip'}, data=>$args});
    $validation->required('name')->like(qr/^[a-z]{1}[a-z0-9\.\_\-]+$/xi);
    $validation->optional('ip','trim');
    $validation->optional('data');
    $validation->optional('expire')->like(qr/^[0-9]+$/x);
    $self->api->utils->error_validation($validation);

    # Generate key
    my $key = sha1_sum(rand_chars(set=>'all', size=>50));

    my @values = ();
    for my $item (qw/key name ip expire data/){
        if($item eq 'key'){
            push(@values, $key);
        }
        elsif($item eq 'data'){
            my $val = $validation->param($item) || {};
            push(@values, {json => $val });
        }
        elsif($item eq 'expire'){
            my $val = $validation->param($item) || $self->app->config('session_expire') || 300;
            push(@values, Mojo::Date->new(time+$val));
            push(@values, $val);
        }
        else {
            push(@values, $validation->param($item));
        }
    }
    my $pg = $self->pg->db->query('INSERT INTO session (key,name,ip,date_expire,expire,data) VALUES(?,?,?,?,?,?::json) RETURNING session_id',@values);
    $self->session_id($pg->hash->{'session_id'});
    $self->session_key($self->session_id."-".$key);
    return $self;
}

sub get {
    my ($self,$id) = @_;

    my $pg;
    my $fields = "session_id, name, key, ip, date_create, date_update, date_expire, expire, data, extract(epoch FROM age(date_expire,current_timestamp)) as age";

    if(defined $id && $id =~ m/^([0-9]+)\-([0-9a-z]+)$/xi){
       $pg = $self->pg->db->query("SELECT $fields FROM session WHERE session_id = ? AND key = ?",$1,$2);
    }
    else {
       $pg = $self->pg->db->query("SELECT $fields FROM session WHERE session_id = ?",$id);
    }
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

    if(defined $id && $id =~ m/^([0-9]+)\-([0-9a-z]+)$/xi){
       $self->pg->db->query("DELETE FROM session WHERE session_id = ? AND key = ?",$1,$2);
    }
    else {
       $self->pg->db->query("DELETE FROM session WHERE session_id = ?",$id);
    }
    return;
}

sub as_hash {
    return shift->_result;
}
    #my $cb = ref $_[-1] eq 'CODE' ? pop : undef;


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


=head1 DESCRIPTION
 
L<Mojolicious::Lite> is a micro real-time web framework built around
L<Mojolicious>.
 
See L<Mojolicious::Guides::Tutorial> for more!
 
=cut

