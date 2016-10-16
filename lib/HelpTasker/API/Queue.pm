package HelpTasker::API::Queue;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper);
use Carp qw(croak);
use overload bool => sub {1}, '""' => sub {shift->queue_id }, fallback => 1;

has [qw(queue_id _result)];

sub create {
    my ($self,$name,$args) = @_;
    my $validation = $self->validation->input({
        name=>$name,
        project_id=>delete $args->{'project_id'},
        type=>delete $args->{'type'},
        settings=>$args,
    });
    $validation->required('name','trim');
    $validation->required('type','gap')->like(qr/^[0-9]$/x);
    $validation->required('project_id','gap')->like(qr/^[0-9]+$/x)->id('project_id');
    $validation->optional('settings')->ref('HASH');
    $self->api->utils->error_validation($validation);

    $validation->output->{'settings'} = [ "?::json", {json => $validation->param('settings') } ];

    my ($sql, @bind) = $self->api->utils->sql->insert(
        -into=>'queue',
        -values=>$validation->output,
        -returning=>'queue_id',
    );

    my $pg = $self->app->pg->db->query($sql,@bind);
    $self->queue_id($pg->hash->{'queue_id'});
    return $self;
}

sub get {
    my ($self,$queue_id,$args) = @_;
    my $validation = $self->validation->input({
        queue_id=>$queue_id,
    });
    $validation->required('queue_id','gap')->like(qr/^[0-9]+$/x)->id('queue_id');
    $self->api->utils->error_validation($validation);

    my ($sql, @bind) = $self->api->utils->sql->select(
        -columns=>[qw/queue_id name date_create date_update settings project_id/],
        -from=>'queue',
        -where=>$validation->output,
    );

    my $pg = $self->app->pg->db->query($sql,@bind);
    my $result = $pg->expand->hash;
    $self->_result($result);
    $self->queue_id($queue_id);
    return $self;
}

sub update {
    my ($self,$queue_id,$args) = @_;
    my $validation = $self->validation->input({
        queue_id=>$queue_id,
        name=>delete $args->{'name'},
        type=>delete $args->{'type'},
        settings=>$args,
    });

    $validation->required('queue_id','gap')->like(qr/^[0-9]+$/x)->id('queue_id');
    $validation->optional('name','trim');
    $validation->required('type','trim')->like(qr/^[0-9]$/x);
    $validation->optional('settings')->ref('HASH');
    $self->api->utils->error_validation($validation);

    my $sql_set = {date_update => ["current_timestamp"]};
    $sql_set->{'name'}     = $validation->param('name')                               if($validation->param('name'));
    $sql_set->{'type'}     = $validation->param('type')                               if($validation->param('type'));
    $sql_set->{'settings'} = [ "?::json", {json => $validation->param('settings') } ] if($validation->param('settings') && ref $validation->param('settings') eq 'HASH' && %{$validation->param('settings')});

    my ($sql, @bind) = $self->api->utils->sql->update(
        -table=>'queue',
        -set=>$sql_set,
        -where=>{queue_id=>$validation->param('queue_id')}
    );

    $self->app->pg->db->query($sql,@bind);
    $self->flush($queue_id);
    $self->queue_id($queue_id);
    return $self;
}

sub flush {
    my ($self,$queue_id,$args) = @_;
    my $validation = $self->validation->input({
        queue_id=>$queue_id,
    });
    $validation->required('queue_id','gap')->like(qr/^[0-9]+$/x)->id('queue_id');
    $self->api->utils->error_validation($validation);

    my ($sql, @bind) = $self->api->utils->sql->update(
        -table=>'queue',
        -set=>{ date_update => ["current_timestamp"] },
        -where=>$validation->output
    );
    $self->app->pg->db->query($sql,@bind);
    $self->queue_id($queue_id);
    return $self;
}

sub as_hash {
    return shift->_result;
}

1;
