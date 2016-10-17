package HelpTasker::API::UserLog;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper);
use Carp qw(croak);
use overload bool => sub {1}, fallback => 1;

#has [qw(user_id _result)];

sub add {
    my ($self,$code,$user_id,$args) = @_;
    $args = $args->output if(ref $args eq 'Mojolicious::Validator::Validation');
    if(ref $args eq 'HASH'){
        while(my ($k,$v) = each(%{$args})){
            delete $args->{$k} if(ref $v eq 'HASH');
            delete $args->{$k} if(ref $v eq 'ARRAY');
        }
    }

    my $validation = $self->validation->input({
        user_id=>$user_id,
        code=>$code,
        args=>$args,
    });
    $validation->required('user_id','gap','lc')->like(qr/^[0-9]+$/x);
    $validation->required('code','gap','lc')->like(qr/^[0-9]+$/x);
    $validation->optional('args')->ref('HASH');
    $self->api->utils->error_validation($validation);

    $validation->output->{'args'} = [ "?::json", {json => $validation->param('args') } ];

    my ($sql, @bind) = $self->api->utils->sql->insert(
        -into=>'user_log',
        -values=>$validation->output,
        -returning=>'user_log_id',
    );

    my $pg = $self->app->pg->db->query($sql,@bind);
    croak qq/Write error sql/ if($pg->rows != 1);
    return $self;
}

1;

=encoding utf8
 
=head1 NAME
 
HelpTasker::API::UserLog
 
=head1 SYNOPSIS

    my $code = 10; 
    my $user_id = 1;
    my $args = {};
    $self->app->api->userlog->add($code,$user_id,$args);

=head1 CODES

    # Module User.pm code between (1-100)
    # 1 - Create user

=head1 SKILS

    my $code = 40;
    my $validation = $self->validation->input({
        arg1=>'arg1',
        arg2=>'arg2',
    });

    $self->api->userlog->add($code,$self->stash('user_id'),$validation);

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.
 
=cut

