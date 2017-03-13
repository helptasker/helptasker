package HelpTasker::Lib::Sessions;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper sha1_sum);
use Mojo::JSON qw(true false);
use Carp qw(croak);
use HelpTasker::Lib::Session::Session;

sub create {
    my ($self,%param) = @_;
    $self->validation->input(\%param);
    $self->validation->optional('name','lc','gap');
    $self->validation->optional('expiration')->like(qr/^[0-9]+$/x);
    $self->validation->optional('ip');
    $self->validation->optional('user_id','gap')->like(qr/^[0-9]+$/x)->id;

    $self->validation->output->{'name'}        ||= '_default';
    $self->validation->output->{'expiration'}  ||= $self->validation->param('expiration') || $self->config('session_default_expiration') || 600;

    $self->validation->output->{'data'}        = [ "?::json", {json => $self->validation->param('data') || {} } ];
    $self->validation->output->{'date_expire'} = Mojo::Date->new(time+$self->validation->output->{'expiration'} );

    my ($sql, @bind) = $self->sql->insert(-into=>'sessions', -values=>$self->validation->output, -returning => 'session_id');
    my $session_id = $self->pg->db->query($sql,@bind)->hash->{'session_id'};

    my @chars = ('A'..'Z', 'a'..'z', 0..9);
    my $session_key;
    $session_key .= $chars[rand @chars] for 1..500;
    $session_key = $session_id.'.'.sha1_sum($session_key);

    ($sql, @bind) = $self->sql->update(-table=>'sessions', -set=>{session_key => $session_key}, -where=>{session_id => $session_id});
    $self->pg->db->query($sql,@bind);

    return $self->get(session_id=>$session_id);
}

sub gets {
    my ($self,%param) = @_;
    $self->validation->input(\%param);
    $self->validation->optional('session_id','gap')->like(qr/^[0-9]+$/x);
    $self->validation->optional('session_key','gap')->like(qr/^[0-9]+$/x);
    $self->lib->utils->validation_error($self->validation);

    my $where = {};
    if(my $session_id = $self->validation->every_param('session_id')){
        $where->{'session_id'} = {-in=>$session_id};
    }
    elsif(my $session_key = $self->validation->every_param('session_key')){
        $where->{'session_key'} = {-in=>$session_key};
    }
    else{
        croak qq/invalid param session_id or session_key/;
    }

    my @columns = ('extract(epoch FROM age(date_expire,current_timestamp)) as age');
    my @dates   = ("extract(epoch from date_create at time zone 'utc') as date_create", "extract(epoch from date_update at time zone 'utc') as date_update", "extract(epoch from date_expire at time zone 'utc') as date_expire");
    my ($sql, @bind) = $self->sql->select(
        -columns   => [qw/session_id session_key name user_id expiration ip data/, @columns, @dates],
        -from      => 'sessions',
        -where     => $where,
    );
    my $pg = $self->pg->db->query($sql,@bind);

    my @result = ();
    while (my $next = $pg->expand->hash) {
        $next->{'date_create'} = Mojo::Date->new($next->{'date_create'});
        $next->{'date_update'} = Mojo::Date->new($next->{'date_update'});
        $next->{'date_expire'} = Mojo::Date->new($next->{'date_expire'});
        push(@result, HelpTasker::Lib::Session::Session->new(%{$next}, pg=>$self->pg, log=>$self->log, sql=>$self->sql));
    }
    return \@result;
}


sub get {
    my ($self,%param) = @_;
    my $gets = $self->gets(%param);
    return shift @{$gets} if(@{$gets});
    return;
}

1;
