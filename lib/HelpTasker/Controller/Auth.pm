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
    @error = sort { $a->{'sorting'} <=> $b->{'sorting'} } @error;
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
    return $self->render() if($self->req->method eq 'GET');

    return $self->redirect_to('/') if($self->validation->csrf_protect->has_error('csrf_token'));
    $self->validation->required('lastname','trim');
    $self->validation->required('firstname','trim');
    $self->validation->required('email','gap','lc')->email({mxcheck=>1, tldcheck=>1});
    $self->validation->required('login','gap','lc')->size(4,50)->like(qr/^[a-z]{1}[a-z0-9]+[\-\_]?[a-z0-9]+$/x)->not_exist('login');
    $self->validation->required('password','trim')->size(6,50);
    $self->validation->required('re_password','trim');

    my @error = ();
    for my $field (@{$self->validation->failed}){
        my ($check, $result, @args) = @{$self->validation->error($field)};
        push(@error, {sorting=>1, msg=>$self->l('Field is not filled').' «'.$self->l('Last Name').'»'})  if($field eq 'lastname' && $check eq 'required');
        push(@error, {sorting=>2, msg=>$self->l('Field is not filled').' «'.$self->l('First Name').'»'}) if($field eq 'firstname' && $check eq 'required');
        push(@error, {sorting=>3, msg=>$self->l('Field is not filled').' «'.$self->l('Email').'»'})      if($field eq 'email' && $check eq 'required');
        push(@error, {sorting=>4, msg=>$self->l('Invalid Email')})                                       if($field eq 'email' && $check eq 'email');
        push(@error, {sorting=>5, msg=>$self->l('Field is not filled').' «'.$self->l('Login').'»'})      if($field eq 'login' && $check eq 'required');
        if($field eq 'login' && $check eq 'size'){
            push(@error, {sorting=>6, msg=>$self->l('Minimum login length of at least [_1] characters and no more than [_2] characters',shift @args,shift @args)});
        }

        if($field eq 'login' && $check eq 'like'){
            push(@error, {sorting=>7, msg=>$self->l('Invalid login. The login can consist of Latin characters, digits, and single hyphens. It must begin with a letter, end with a letter or digit.')});
        }

        push(@error, {sorting=>8, msg=>$self->l('Login already exists in the system')}) if($field eq 'login' && $check eq 'not_exist');
        push(@error, {sorting=>9, msg=>$self->l('Field is not filled').' «'.$self->l('Password').'»'}) if($field eq 'password' && $check eq 'required');

        if($field eq 'password' && $check eq 'size'){
            push(@error, {sorting=>10, msg=>$self->l('Minimum password length of at least [_1] characters and no more than [_2] characters',shift @args,shift @args)});
        }

        push(@error, {sorting=>11, msg=>$self->l('Field is not filled').' «'.$self->l('Re-Password').'»'}) if($field eq 're_password' && $check eq 'required');
    }
    @error = sort { $a->{'sorting'} <=> $b->{'sorting'} } @error;
    return $self->render(error=>shift(@error)->{'msg'}) if(@error);

    if($self->validation->param('password') ne $self->validation->param('re_password')){
        return $self->render(error=>$self->l('Passwords and Re-Password do not match'));
    }
    return $self->render();
}


1;

