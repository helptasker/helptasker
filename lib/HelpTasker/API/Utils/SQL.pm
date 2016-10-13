package HelpTasker::API::Utils::SQL;
use Mojo::Base 'HelpTasker::API::Base';
use Carp qw(croak);

sub insert {
    my ($self, $validation) = @_;
    croak qq/not object Mojolicious::Validator::Validation/ if (ref $validation ne 'Mojolicious::Validator::Validation');

    my @fields = ();
    my @values = ();
    while( my ($key,$val) = each(%{$validation->output}) ){
        push(@fields,$key);
        push(@values,$val);
    }
    return (join(",",@fields), @values);
}

sub sel {
    my ($self, $validation) = @_;
    return
}

1;
