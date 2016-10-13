package HelpTasker::API::Utils;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper decode);
use Carp qw(croak confess);
use SQL::Abstract::More;

sub error_tx {
    my ($self, $tx) = @_;
    croak 'not object Mojo::Transaction::HTTP' if (ref $tx ne 'Mojo::Transaction::HTTP');
    if (my $error = $tx->error) {
        my $code    = $error->{'code'};
        my $message = $error->{'message'};
        $message = decode 'UTF-8', $message;

        my $url = Mojo::URL->new($tx->req->url->to_abs->to_string);
        $url->userinfo('hidden:hidden') if ($url->userinfo);

        croak "code:$code, message:$message, url:$url" if $code;
        croak "connection error: $message url:$url";
    }
    return $tx;
}

sub error_validation {
    my ($self, $validation) = @_;
    croak qq/not object Mojolicious::Validator::Validation/ if (ref $validation ne 'Mojolicious::Validator::Validation');
    for my $field (@{$validation->failed}) {
        my ($check, $result, @args) = @{$validation->error($field)};
        my ($pkg, $line) = (caller())[0, 2];
        #($pkg, $line) = (caller(1))[0, 2] if $pkg eq ref $self;
        croak qq/invalid param field:$field, check:$check, package $pkg\[$line\]/;
    }
    return;
}

sub sql {
    my ($self) = @_;
    return SQL::Abstract::More->new();
;
}

1;

