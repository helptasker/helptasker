package HelpTasker::API::Utils;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper decode);
use Carp qw(croak confess);
use SQL::Abstract::More;
use Data::Pageset;

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
        croak qq/invalid param field:$field, check:$check, package $pkg\[$line\]/;
    }
    return;
}

sub sql {
    my ($self) = @_;
    return SQL::Abstract::More->new();
}

sub page {
    my ($self,$total_entries,$args,$cb) = @_;

    if(ref $total_entries eq 'HASH'){
        my ($sql, @bind) = $self->api->utils->sql->select(%{$total_entries});
        my $pg = $self->app->pg->db->query($sql,@bind);
        $total_entries = $pg->rows;
    }
    elsif(ref $total_entries eq 'Mojo::Pg::Results'){
        $total_entries = $total_entries->rows;
    }

    my $validation = $self->validation->input({
        total_entries=>$total_entries,
        entries_per_page=>delete $args->{'entries_per_page'},
        current_page=>delete $args->{'current_page'},
        pages_per_set=>delete $args->{'pages_per_set'},
        mode=>delete $args->{'mode'},
    });

    $validation->required('total_entries','gap')->like(qr/^[0-9]+$/x);
    $validation->optional('entries_per_page','gap')->like(qr/^[0-9]+$/x);
    $validation->optional('current_page','gap')->like(qr/^[0-9]+$/x);
    $validation->optional('pages_per_set','gap')->like(qr/^[0-9]+$/x);
    $validation->optional('mode','gap')->in(qw/fixed slide/);
    $self->api->utils->error_validation($validation);

    $total_entries       = $validation->param('total_entries');
    my $entries_per_page = $validation->param('entries_per_page') || 10;
    my $current_page     = $validation->param('current_page')     || 1;
    my $pages_per_set    = $validation->param('pages_per_set')    || 7;
    my $mode             = $validation->param('mode')             || 'slide';

    my $page = Data::Pageset->new({
        total_entries       => $total_entries,
        entries_per_page    => $entries_per_page,
        current_page        => $current_page,
        pages_per_set       => $pages_per_set,
        mode                => $mode,
    });

    my @pages_in_set = ();
    for my $page (@{$page->pages_in_set()}) {
        if(ref $cb eq 'CODE'){
            push(@pages_in_set, $self->$cb($page));
        }
        else{
            push(@pages_in_set, $page);
        }
    }

    return {
        first_page=>$page->first_page,
        last_page=>$page->last_page,
        next_page=>$page->next_page,
        previous_page=>$page->previous_page,
        previous_set=>$page->previous_set,
        next_set=>$page->next_set,
        offset=>$page->skipped,
        limit=>$page->entries_per_page,
        pages_in_set=>\@pages_in_set,
    };
}

sub stringify {
    my ($self,$stringify) = @_;
    my @log = ();
    $stringify = $stringify->output if(ref $stringify eq 'Mojolicious::Validator::Validation');
    while(my($k,$v) = each(%{$stringify})){
        next if(ref $v eq 'HASH');
        next if(ref $v eq 'ARRAY');
        push(@log, "$k:$v");
    }
    return join(", ",sort { $a cmp $b } @log);
}

1;

