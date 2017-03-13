package HelpTasker::Lib::Session::Session;
use Mojo::Base -base;
use Mojo::Util qw(dumper);
use Mojo::JSON qw(true false);

has [qw/pg sql log/];
has [qw/user_id age session_id date_create date_expire date_update expiration ip name session_id session_key/];

sub to_hash {
    my $self = shift;
    my $return = {};
    while( my ($key) = each(%{$self})){
        next if($key eq 'pg' or $key eq 'log' or $key eq 'sql');
        $return->{$key} = $self->{$key};
    }
    return $return;
}

sub valid {
    my $self = shift;
    return true if($self->age > 0);
    return false;
}

1;
