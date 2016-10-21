package HelpTasker::Controller::Manifest;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(dumper);

sub manifest {
    my $self = shift;
    return $self->render(json=>{
        short_name=>"HelpTasker",
        name=>"HelpTasker Ticket System",
        start_url=>"/auth/",
        display=>"standalone",
        background_color=>"#8290a3",
    });
}

1;
