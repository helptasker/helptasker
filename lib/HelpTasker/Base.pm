package HelpTasker::Base;
use Mojo::Base -base;
use Mojolicious::Validator;
use Mojo::Util qw(dumper);
use SQL::Abstract::More;

has ['lib', 'pg', 'log', 'defaults', 'validation', 'ua'];

sub sql {
    my ($self) = @_;
    my $sql = SQL::Abstract::More->new();
    return $sql;
}

sub config {
    my ($self,$name) = @_;
    return $self->defaults->{'config'}->{$name};
}


1;
