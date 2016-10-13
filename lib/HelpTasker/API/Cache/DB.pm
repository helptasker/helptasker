package HelpTasker::API::Cache::DB;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper);
use Carp qw(croak);
use overload bool => sub {1}, fallback => 1;

sub save {
    my ($self,$key,$value,$expire) = @_;
    my $validation = $self->validation->input({key=>$key, value=>$value, expire=>$expire});
    $validation->required('key');
    $validation->required('value');
    $validation->optional('expire')->like(qr/^[0-9]+$/x);
    $self->api->utils->error_validation($validation);

    $validation->output->{'expire'} ||= 60*60*24;
    $validation->output->{'value'} = [ "?::json", {json => $validation->param('value') } ];
    $validation->output->{'date_expire'} = Mojo::Date->new(time+delete $validation->output->{'expire'});

    # Force delete key
    $self->remove($key);

    my ($sql, @bind) = $self->api->utils->sql->insert(
        -into=>'cache',
        -values=>$validation->output,
        -returning=>'cache_id',
    );
    my $pg = $self->app->pg->db->query($sql,@bind);
    return $pg->rows > 0 ? 1 : undef;
}

sub get {
    my ($self,$key) = @_;
    my $validation = $self->validation->input({key=>$key});
    $validation->required('key');
    $self->api->utils->error_validation($validation);

    my @columns = qw/value/;
    push(@columns,'extract(epoch FROM age(date_expire,current_timestamp)) as age');

    my ($sql, @bind) = $self->api->utils->sql->select(-columns=>\@columns, -from=>'cache', -where=>{key=>$validation->param('key')} );
    my $pg = $self->app->pg->db->query($sql,@bind);
    return if($pg->rows == 0);

    my $result = $pg->expand->hash;
    if(delete $result->{'age'} <= 0){
        $self->remove($key);
        return;
    }
    return $result->{'value'};
}

sub remove {
    my ($self,$key) = @_;
    my $validation = $self->validation->input({key=>$key});
    $validation->required('key');
    $self->api->utils->error_validation($validation);

    my ($sql, @bind) = $self->api->utils->sql->delete(-from=>'cache', -where=>{key=>$validation->param('key')});
    my $pg = $self->app->pg->db->query($sql,@bind);
    return if($pg->rows == 0);
    return 1;
}

1;
