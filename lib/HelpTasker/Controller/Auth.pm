package HelpTasker::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(dumper);

sub login {
    my $self = shift;
    return $self->render() if($self->req->method eq 'GET');

    $self->validation->required('login','gap','lc');
    $self->validation->required('password','trim');
    my @error = ();
    for my $field (@{$self->validation->failed}){
        my ($check, $result, @args) = @{$self->validation->error($field)};
        push(@error, {sorting=>1, msg=>$self->l('Field is not filled').' «'.$self->l('Username').'»'}) if($field eq 'login' && $check eq 'required');
        push(@error, {sorting=>2, msg=>$self->l('Field is not filled').' «'.$self->l('Password').'»'}) if($field eq 'password' && $check eq 'required');
    }
    @error = sort { $a->{'sorting'} cmp $b->{'sorting'} } @error;
    return $self->render(error=>shift(@error)->{'msg'}) if(@error);
    return $self->render();
}

sub registration {
    my $self = shift;
    return $self->render();
}


1;

