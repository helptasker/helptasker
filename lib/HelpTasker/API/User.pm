package HelpTasker::API::User;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper);
use Carp qw(croak);
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

    my ($sql, @bind) = $self->api->utils->sql->insert(
        -into=>'"user"',
        -values=>$validation->output,
        -returning=>'user_id',
    );

    say $sql;
    say dumper \@bind;

    #my $pg = $self->app->pg->db->query($sql,@bind);
    #$self->queue_id($pg->hash->{'user_id'});
    return $self;
}

1;
