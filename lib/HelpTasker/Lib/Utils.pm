package HelpTasker::Lib::Utils;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper decode);
use Carp qw(croak confess);
use Data::Random qw(rand_chars);

sub error_tx {
    my ($self, $tx) = @_;
    croak 'not object Mojo::Transaction::HTTP' if (ref $tx ne 'Mojo::Transaction::HTTP');

    if (my $error = $tx->error) {
        my $code    = $error->{'code'};
        my $message = decode 'UTF-8', $error->{'message'};

        my $url = Mojo::URL->new($tx->req->url->to_abs->to_string);
        $url->userinfo('hidden:hidden') if ($url->userinfo);

        croak "$code $message, $url" if $code;
        croak "connection error: $message $url";
    }
    return $tx;
}

sub validation_error {
    my ($self,$validation) = @_;
    croak 'not object Mojolicious::Validator::Validation' if (ref $validation ne 'Mojolicious::Validator::Validation');

    if($validation->has_error){
        for my $field (@{$validation->failed}){
            my ($check, $result, @args) = @{$validation->error($field)};
            my ($pkg, $line) = (caller())[0, 2];
            croak qq/invalid param field:$field, check:$check, package $pkg\[$line\]/;
        }
    }
    return;
}

sub declination_by_numbers {
    my ($self,$count, $form1, $form2, $form3) = @_;
    $count = abs($count) % 100;
    my $lcount = $count % 10;
    return ($form3) if ($count >= 11 && $count <= 19);
    return ($form2) if ($lcount >= 2 && $lcount <= 4);
    return ($form1) if ($lcount == 1);
    return $form3;
}

1;
