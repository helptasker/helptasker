package HelpTasker::Controller::API;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(dumper);

sub test {
    my $self = shift;
    my $date = $self->app->pg->db->query("SELECT now() as date")->hash->{'date'};
    return $self->reply->api({date=>$date});
}

sub project {
    my $self = shift;
    if($self->req->method eq 'POST'){
        my $validation = $self->validation->input($self->req->json);
        $validation->required('name');
        $validation->required('fqdn');
        $self->app->api->utils->error_validation($validation);

        my $project = $self->app->api->project->create(%{$validation->output})->to_hash;
        return $self->reply->api($project);
    }
    elsif($self->req->method eq 'DELETE'){
        $self->validation->required('project_id','trim')->like(qr/^[0-9]+$/x)->id;
        $self->app->api->utils->error_validation($self->validation);
        $self->app->api->project->delete(%{$self->validation->output});
        return $self->reply->api({});
    }
    elsif($self->req->method eq 'PUT'){
        my $validation = $self->validation->input($self->req->json);
        $validation->required('project_id','trim')->like(qr/^[0-9]+$/x)->id;
        $validation->required('name');
        $validation->required('fqdn');
        $self->app->api->utils->error_validation($validation);
        my $project = $self->app->api->project->update(%{$validation->output});
        return $self->reply->api($project);
    }
    elsif($self->req->method eq 'GET'){
        $self->validation->required('project_id','trim')->like(qr/^[0-9]+$/x)->id;
        $self->app->api->utils->error_validation($self->validation);

        my $project = $self->app->api->project->get(%{$self->validation->output});
        return $self->reply->api($project);
    }
    return $self->reply->api('Invalid http method', {status=>400});
}


sub projects {
    my $self = shift;
    if($self->req->method eq 'POST'){
        my $json = $self->req->json;
        $self->app->api->project->create(%{$json});
        return $self->reply->api({data=>1});
    }
    else{
        return $self->reply->api({data=>1});
    }

    #say $self->pg->db->query('select version() as version')->hash->{version};
    #$self->app->api->projects->create;
    #say dumper $self->app->api->projects->create(name=>'test');
    return $self->reply->api({data=>1});
}

1;

