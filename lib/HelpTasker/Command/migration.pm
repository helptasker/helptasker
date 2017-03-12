package HelpTasker::Command::migration;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw(dumper getopt);
use Term::ANSIColor qw(:constants);

# Short description
has description => 'Migration DB';
 
# Usage message from SYNOPSIS
has usage => sub { shift->extract_usage };
 
sub run {
    my ($self, @args) = @_;

    my $args = {};
    getopt \@args,
        'v|verbose' => \$args->{'verbose'},
        'r|reset'   => \$args->{'reset'},
        'i|info'    => \$args->{'info'},
        'm|migrate' => \$args->{'migrate'}
    ;

    my $migrations = $self->app->pg->migrations;
    $migrations->name('helptasker');
    $migrations->from_data('HelpTasker::Command::migration','helptasker');

    if(defined $args->{'reset'}){
        $migrations->migrate(0)->migrate;
        say BOLD, RED, "Reset DB", RESET if(!defined $args->{'verbose'});
        return;
    }
    elsif(defined $args->{'info'}){
        say BOLD, GREEN, "Currently active version ".$migrations->active.RESET;
        say BOLD, GREEN, "Latest version available ".$migrations->latest.RESET;
        return;
    }
    elsif(defined $args->{'migrate'}){
        return $migrations->migrate;
    }
    return $self->help;
}
 
1;
 
=encoding utf8
 
=head1 NAME
 
HelpTasker::Command::migration - Migration DB
 
=head1 SYNOPSIS
 
  Usage: APPLICATION migration [OPTIONS]
 
    helptasker migration
 
  Options:
    -r, --reset     Reset
    -i, --info      Information
    -m, --migrate   Migrate
    -h, --help      Show this summary of available options
    -v, --verbose   Print request and response headers to STDERR

=head1 SEE ALSO
 
L<HelpTasker>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.
 
=cut


__DATA__

@@ helptasker

-- 1 up

/* Table users */
CREATE TABLE users (
    user_id         SERIAL    PRIMARY KEY,
    date_create     TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    date_update     TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    login           TEXT      NOT NULL,
    lastname        TEXT      NOT NULL,
    firstname       TEXT      NOT NULL,
    email           TEXT      NULL,
    password        TEXT      NULL,
    is_active       BOOLEAN   NOT NULL DEFAULT FALSE
);

CREATE UNIQUE INDEX idx_login ON users USING btree(login);
CREATE UNIQUE INDEX idx_email ON users USING btree(email);

/* Table sessions */
CREATE TABLE sessions (
    session_id   SERIAL    PRIMARY KEY,
    date_create  TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    date_update  TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    date_expire  TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    session_key  TEXT      NULL,
    name         TEXT      NOT NULL,
    user_id      INTEGER   NULL,
    expiration   INTEGER   NOT NULL,
    ip           INET      NULL,
    data         JSON      NOT NULL
);

CREATE INDEX idx_session_key ON sessions(session_key);
ALTER TABLE sessions ADD FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE ON UPDATE CASCADE;

/* CREATE VIEW v_test AS SELECT user_id FROM users; */


-- 1 down
/* DROP VIEW  IF EXISTS v_test; */
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS users;


