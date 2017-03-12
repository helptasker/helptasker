package HelpTasker::Lib::Sessions;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper);
use Mojo::JSON qw(true false);
use Carp qw(croak);

sub create {
    my ($self,%param) = @_;
    $self->validation->input(\%param);
    $self->validation->optional('name','lc');

    $self->validation->optional('password','trim');
    $self->validation->optional('is_active')->in(0,1);
    $self->lib->utils->validation_error($self->validation);

    $self->validation->output->{'is_active'} ||= false;
    $self->validation->output->{'password'} = sha1_sum(encode('UTF-8',$self->validation->output->{'password'}));

    my ($sql, @bind) = $self->sql->insert(
        -into      => 'users',
        -values    => $self->validation->output,
        -returning => 'user_id',
    );
    my $user_id = $self->pg->db->query($sql,@bind)->hash->{'user_id'};
    return $self->get(user_id=>$user_id);
}


1;
