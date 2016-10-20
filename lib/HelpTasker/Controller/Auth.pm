package HelpTasker::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(dumper sha1_sum);

sub login {
    my $self = shift;
    return $self->render() if($self->req->method eq 'GET');

	return $self->redirect_to('/') if($self->validation->csrf_protect->has_error('csrf_token'));
    $self->validation->required('login','gap','lc')->exist('login');
    $self->validation->required('password','trim');
    my @error = ();
    for my $field (@{$self->validation->failed}){
        my ($check, $result, @args) = @{$self->validation->error($field)};
        push(@error, {sorting=>1, msg=>$self->l('Field is not filled').' «'.$self->l('Username').'»'}) if($field eq 'login' && $check eq 'required');
        push(@error, {sorting=>2, msg=>$self->l('Field is not filled').' «'.$self->l('Password').'»'}) if($field eq 'password' && $check eq 'required');
        push(@error, {sorting=>3, msg=>$self->l('Incorrect username or password')}) if($field eq 'login' && $check eq 'exist');
    }
    @error = sort { $a->{'sorting'} cmp $b->{'sorting'} } @error;
    return $self->render(error=>shift(@error)->{'msg'}) if(@error);

    my $user = $self->api->user->search($self->validation->param('login'));
    $user = shift @{$user->as_hash->{'result'}};
    if($user->{'password'} ne sha1_sum($self->validation->param('password'))){
        return $self->render(error=>$self->l('Incorrect username or password'));
    }

    return $self->render();
}

sub registration {
    my $self = shift;
    return $self->render();
}


1;

