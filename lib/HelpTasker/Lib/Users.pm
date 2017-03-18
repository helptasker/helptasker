package HelpTasker::Lib::Users;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper sha1_sum encode trim);
use Mojo::JSON qw(true false);
use Carp qw(croak confess);
use HelpTasker::Lib::User::User;

sub create {
    my ($self,%param) = @_;
    $self->validation->input(\%param);
    $self->validation->required('login','lc')->size(3,20)->like(qr/^[a-z]+[a-z0-9\-]+$/x)->check_login;
    $self->validation->required('firstname');
    $self->validation->required('lastname');
    $self->validation->optional('email','lc','gap')->email({mxcheck=>1, tldcheck=>1});
    $self->validation->optional('password','trim');
    $self->validation->optional('is_active')->in(0,1);
    $self->lib->utils->validation_error($self->validation);

    $self->validation->output->{'is_active'} ||= false;
    $self->validation->output->{'password'} = sha1_sum(encode('UTF-8',$self->validation->output->{'password'}));

    my ($sql, @bind) = $self->sql->insert(
        -into      => 'users',
        -values    => $self->validation->output,
        -returning => 'user_id',
    );

    my $user_id = $self->pg->db->query($sql,@bind)->hash->{'user_id'};
    return $self->get(user_id=>$user_id);
}

sub gets {
    my ($self,%param) = @_;
    $self->validation->input(\%param);
    $self->validation->required('user_id','gap')->like(qr/^[0-9]+$/x)->id;
    $self->lib->utils->validation_error($self->validation);

    my @dates = ("extract(epoch from date_create at time zone 'utc') as date_create", "extract(epoch from date_update at time zone 'utc') as date_update");
    my ($sql, @bind) = $self->sql->select(
        -columns   => [qw/user_id login lastname firstname email password is_active/, @dates],
        -from      => 'users',
        -where     => {user_id=>{-in=>$self->validation->every_param('user_id')}},
    );
    my $pg = $self->pg->db->query($sql,@bind);

    my @result = ();
    while (my $next = $pg->hash) {
        $next->{'is_active'}   = $next->{'is_active'} ? true : false;
        $next->{'date_create'} = Mojo::Date->new($next->{'date_create'});
        $next->{'date_update'} = Mojo::Date->new($next->{'date_update'});
        push(@result, HelpTasker::Lib::User::User->new(%{$next}, pg=>$self->pg, log=>$self->log, sql=>$self->sql));
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
