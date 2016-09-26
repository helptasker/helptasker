package HelpTasker::API::Session;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper sha1_sum);
use Carp qw(croak);
use Net::IP;
use Data::Random qw(rand_chars);
use Mojo::JSON qw(true false);


use overload bool => sub {1}, fallback => 1;

has [qw(session_id name ip key data expiry session_id session_key)];

# Create session
sub create {
    my ($self,%param) = @_;
    $param{'name'}   ||= $self->name;
    $param{'ip'}     ||= $self->ip;
    $param{'data'}   ||= $self->data;
    $param{'expiry'} ||= $self->expiry;

    my $validation = $self->validation->input(\%param);
    $validation->required('name')->like(qr/^[a-z]{1}[a-z0-9\.\_\-]+$/xi);
    $validation->optional('ip','trim');
    $validation->optional('data');
    $validation->optional('expiry')->like(qr/^[0-9]+$/x);
    $self->app->api->utils->error_validation($validation);

    # Generate key
    my $key = sha1_sum(rand_chars(set=>'all', size=>50));

    my @values = ();
    for my $item (qw/key name ip expiry data/){
        if($item eq 'key'){
            $self->$item($key);
            push(@values, $key);
        }
        elsif($item eq 'data'){
            my $val = $validation->param($item) || {};
            $self->$item($val);
            push(@values, {json => $val });
        }
        elsif($item eq 'expiry'){
            my $val = $validation->param($item) || $self->app->config('session_expiry') || 300;
            $self->$item($val);
            push(@values, Mojo::Date->new(time+$val));
        }
        else {
            $self->$item($validation->param($item));
            push(@values, $validation->param($item));
        }
    }

    my $pg = $self->app->pg->db->query('INSERT INTO session (key,name,ip,date_expiry,data) VALUES(?,?,?,?,?::json) RETURNING session_id',@values);
    $self->session_id($pg->hash->{'session_id'});
    $self->session_key($self->session_id."-".$self->key);
    return $self;
}

sub get_key {
    my ($self,%param) = @_;
    $param{'session_key'} ||= $self->session_key;
    $param{'name'}        ||= $self->name;
    $param{'ip'}          ||= $self->ip;

    my $validation = $self->validation->input(\%param);
    $validation->required('session_key')->like(qr/^[0-9]+\-[a-z0-9]{40}$/xi);
    $validation->required('name');
    $validation->optional('ip');
    $self->app->api->utils->error_validation($validation);

    if(my $session_key = $validation->param('session_key')){
        my ($session_id,$key) = ($session_key =~ m/^([0-9]+)\-([a-z0-9]{40})$/x);

        my $name = $validation->param('name');
        my $fields = "session_id, name, key, ip, date_create, date_update, date_expiry, data, extract(epoch FROM age(date_expiry,current_timestamp)) as age";

        my $pg = $self->app->pg->db->query("SELECT $fields FROM session WHERE session_id = ? AND key = ? AND name = ?",$session_id,$key,$name);
        return {} if($pg->rows == 0);

        my $result = $pg->expand->hash;
        $result->{'is_valid'} = $result->{'age'} > 0 ? true : false;

        if(my $ip = $validation->param('ip')){
            $result->{'is_valid'} = $result->{'ip'} eq $ip ? true : false;
        }
        return $result;
    }
    return {};
}

1;
