package HelpTasker::Lib::User::User;
use Mojo::Base -base;
use Mojo::Util qw(dumper sha1_sum encode trim);
use Mojo::JSON qw(true false);

has [qw/pg sql log/];
has [qw/user_id date_create date_update login lastname firstname email is_active password/];

sub to_hash {
    my $self = shift;
    my $return = {};
    while( my ($key) = each(%{$self})){
        next if($key eq 'pg' or $key eq 'log' or $key eq 'sql');
        $return->{$key} = $self->{$key};
    }
    return $return;
}

sub save {
    my ($self) = @_;

    if(defined $self->password && $self->password !~ m/^[0-9a-z]{40}$/x){
        $self->password(sha1_sum(encode('UTF-8',$self->password)));
    }

    if(ref $self->is_active ne 'JSON::PP::Boolean' && $self->is_active == 1){
        $self->is_active(true);
    }
    elsif(ref $self->is_active ne 'JSON::PP::Boolean' && $self->is_active == 0){
        $self->is_active(false);
    }

    if(defined $self->email){
        my $email = $self->email;
        $email = trim($email);
        $email = lc($email);
        $self->email($email);
    }

    my ($sql, @bind) = $self->sql->update(
        -table => 'users',
        -set   => {
            lastname=>$self->lastname,
            firstname=>$self->firstname,
            email=>$self->email,
            password=>$self->password,
            is_active=>$self->is_active,
            date_update=>\'current_timestamp',
        },
        -where => {user_id=>$self->user_id},
    );
    my $pg = $self->pg->db->query($sql,@bind);
    if($pg->rows == 1){
        my @log = ();
        push(@log, 'user_id:'.$self->user_id || 'n/a');
        push(@log, 'login:'.$self->login || 'n/a');
        push(@log, 'lastname:'.$self->lastname || 'n/a');
        push(@log, 'firstname:'.$self->firstname || 'n/a');
        push(@log, 'email:'.$self->email || 'n/a');
        push(@log, 'password:'.$self->password || 'n/a');
        push(@log, 'is_active:'.$self->is_active || 'n/a');
        $self->log->info('update user '.join(", ",@log));
    }

    return $self;
}

1;
