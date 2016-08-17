package HelpTasker::Email::Parse;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper);
use MIME::Parser;

sub parse {
    my ($self,%param) = @_;
    my $validation = $self->app->validation->input(\%param);
    $validation->required('message');

    my $message  = $validation->param('message');


    #say dumper $message;
    return;
}


1;

