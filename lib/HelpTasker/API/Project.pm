package HelpTasker::API::Project;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper);
use Carp qw(croak);
use overload bool => sub {1}, fallback => 1;

has [qw(project_id _result)];

# New project
sub create {
    my ($self,$name,$args) = @_;
    my $validation = $self->validation->input({
        name=>$name,
        fqdn=>delete $args->{'fqdn'},
    });
    $validation->required('name');
    $validation->required('fqdn','trim')->like(qr/^[a-z]{1}[a-z0-9_]+$/x);
    $self->api->utils->error_validation($validation);

    my ($sql, @bind) = $self->api->utils->sql->insert(
        -into=>'project',
        -values=>$validation->output,
        -returning=>'project_id',
    );
    my $pg = $self->app->pg->db->query($sql,@bind);
    return $pg->hash->{'project_id'};
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
        -columns=>[qw/project_id name fqdn date_create date_update/],
        -from=>'project',
        -where=>$validation->output,
    );
    my $pg = $self->app->pg->db->query($sql,@bind);
    my $result = $pg->hash;
    $self->app->pg->db->query($sql,@bind);
    $self->_result($result);
    return $self;
}

# Updating project
sub update {
    my ($self,$project_id,$args) = @_;
    my $validation = $self->validation->input({
        project_id=>$project_id,
        name=>delete $args->{'name'},
        fqdn=>delete $args->{'fqdn'},
    });

    $validation->required('project_id')->like(qr/^[0-9]+$/x)->id('project_id');
    $validation->optional('name');
    $validation->optional('fqdn','trim')->like(qr/^[a-z]{1}[a-z0-9_]+$/x);
    $self->api->utils->error_validation($validation);

    my $set = {date_update => ["current_timestamp"]};
    $set->{'name'} = $validation->param('name') if($validation->param('name'));
    $set->{'fqdn'} = $validation->param('fqdn') if($validation->param('fqdn'));

    my ($sql, @bind) = $self->api->utils->sql->update(
        -table=>'project',
        -set=>$set,
        -where=>{project_id=>$validation->param('project_id')}
    );
    $self->app->pg->db->query($sql,@bind);
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
    return $self;
}

sub as_hash {
    return shift->_result;
}

1;
__END__

# Get project
sub get {
    my ($self,%param) = @_;
    $param{'project_id'} ||= $self->project_id;

    my $validation = $self->validation->input(\%param);
    $validation->required('project_id','trim')->id;
    $self->app->api->utils->error_validation($validation);

    my $pg = $self->app->pg->db->query("SELECT project_id, name, fqdn, date_create, date_update FROM projects WHERE project_id = ? LIMIT 1",$validation->param('project_id'));

    my $project = $pg->hash;
    for my $item (qw/project_id name fqdn date_create date_update/){
        $self->$item($project->{$item});
    }
    return $self->to_hash;
}

# Delete project
sub remove {
    my ($self,%param) = @_;
    $param{'project_id'} ||= $self->project_id;

    my $validation = $self->validation->input(\%param);
    $validation->required('project_id','trim')->id;
    $self->app->api->utils->error_validation($validation);

    $self->project_id($validation->param('project_id'));
    $self->app->pg->db->query("DELETE FROM projects WHERE project_id = ?",$validation->param('project_id'));
    return $self;
}

# System Project Update
sub flush {
    my ($self,%param) = @_;
    $param{'project_id'} ||= $self->project_id;

    my $validation = $self->validation->input(\%param);
    $validation->required('project_id','trim')->id;

    $self->app->api->utils->error_validation($validation);

    $self->project_id($validation->param('project_id'));
    $self->app->pg->db->query("UPDATE projects SET date_update = current_timestamp WHERE project_id = ?",$validation->param('project_id'));
    $self->get;
    return $self;
}

sub update {
    my ($self,%param) = @_;
    $param{'project_id'} ||= $self->project_id;
    $param{'name'}       ||= $self->name;
    $param{'fqdn'}       ||= $self->fqdn;

    my $validation = $self->validation->input(\%param);
    $validation->required('project_id','trim')->id;
    $validation->required('name');
    $validation->required('fqdn','trim')->like(qr/^[a-z]{1}[a-z0-9_]+$/x);
    $self->app->api->utils->error_validation($validation);

    my @id = ();
    for my $item (qw/name fqdn project_id/){
        push(@id, $validation->param($item));
        $self->$item($validation->param($item));
    }

    $self->app->pg->db->query('UPDATE projects SET name = ?, fqdn = ? WHERE project_id = ?',@id);
    $self->flush(project_id=>$validation->param('project_id'));
    return $self->get;
}

# Print hash
sub to_hash {
    my $self = shift;
    my $return = {};
    for my $item (qw/project_id name fqdn date_create date_update/){
        $return->{$item} = $self->$item;
    }
    return $return;
}

1;



