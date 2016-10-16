package HelpTasker::API::Project;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper);
use Carp qw(croak);
use overload bool => sub {1}, '""' => sub {shift->project_id }, fallback => 1;

has [qw(project_id _result)];

# New project
sub create {
    my ($self,$name,$args) = @_;
    my $validation = $self->validation->input({
        name=>$name,
        fqdn=>delete $args->{'fqdn'},
        settings=>$args,
    });
    $validation->required('name','trim');
    $validation->required('fqdn','gap')->like(qr/^[a-z]{1}[a-z0-9_]+$/x);
    $validation->optional('settings')->ref('HASH');
    $self->api->utils->error_validation($validation);

    $validation->output->{'settings'} = [ "?::json", {json => $validation->param('settings') } ];

    my ($sql, @bind) = $self->api->utils->sql->insert(
        -into=>'project',
        -values=>$validation->output,
        -returning=>'project_id',
    );
    my $pg = $self->app->pg->db->query($sql,@bind);
    $self->project_id($pg->hash->{'project_id'});
    return $self;
}

# Get project
sub get {
    my ($self,$project_id,$args) = @_;
    my $validation = $self->validation->input({
        project_id=>$project_id,
    });
    $validation->required('project_id')->like(qr/^[0-9]+$/x)->id('project_id');
    $self->api->utils->error_validation($validation);

    my ($sql, @bind) = $self->api->utils->sql->select(
        -columns=>[qw/project_id name fqdn date_create date_update settings/],
        -from=>'project',
        -where=>$validation->output,
    );
    my $pg = $self->app->pg->db->query($sql,@bind);
    my $result = $pg->expand->hash;
    $self->_result($result);
    $self->project_id($project_id);
    return $self;
}

# Updating project
sub update {
    my ($self,$project_id,$args) = @_;
    my $validation = $self->validation->input({
        project_id=>$project_id,
        name=>delete $args->{'name'},
        fqdn=>delete $args->{'fqdn'},
        settings=>$args,
    });

    $validation->required('project_id')->like(qr/^[0-9]+$/x)->id('project_id');
    $validation->optional('name','trim');
    $validation->optional('fqdn','gap')->like(qr/^[a-z]{1}[a-z0-9_]+$/x);
    $validation->optional('settings')->ref('HASH');
    $self->api->utils->error_validation($validation);

    my $sql_set = {date_update => ["current_timestamp"]};
    $sql_set->{'name'}     = $validation->param('name')                               if($validation->param('name'));
    $sql_set->{'fqdn'}     = $validation->param('fqdn')                               if($validation->param('fqdn'));
    $sql_set->{'settings'} = [ "?::json", {json => $validation->param('settings') } ] if($validation->param('settings') && ref $validation->param('settings') eq 'HASH' && %{$validation->param('settings')});

    my ($sql, @bind) = $self->api->utils->sql->update(
        -table=>'project',
        -set=>$sql_set,
        -where=>{project_id=>$validation->param('project_id')}
    );
    $self->app->pg->db->query($sql,@bind);
    $self->flush($project_id);
    $self->project_id($project_id);
    return $self;
}

# System Project Update
sub flush {
    my ($self,$project_id,$args) = @_;
    my $validation = $self->validation->input({
        project_id=>$project_id,
    });
    $validation->required('project_id')->like(qr/^[0-9]+$/x)->id('project_id');
    $self->api->utils->error_validation($validation);

    my ($sql, @bind) = $self->api->utils->sql->update(
        -table=>'project',
        -set=>{ date_update => ["current_timestamp"] },
        -where=>$validation->output
    );
    $self->app->pg->db->query($sql,@bind);
    $self->project_id($project_id);
    return $self;
}

sub as_hash {
    return shift->_result;
}

1;
