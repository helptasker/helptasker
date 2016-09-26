package HelpTasker::API::Migration;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper);

sub migrate {
	my $self = shift;
	$self->app->pg->migrations->from_data->migrate;
	return;
}

sub clear {
	my $self = shift;
	$self->app->pg->migrations->from_data->migrate(0)->migrate;
	return;
}

1;

__DATA__
@@ migrations
-- 1 up
CREATE TABLE test (message_text varchar(200));
CREATE TABLE projects (
    project_id  SERIAL    PRIMARY KEY,
    name        TEXT      NOT NULL,
    date_create TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    date_update TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    fqdn        TEXT      UNIQUE NOT NULL
);

CREATE TABLE session (
    session_id   SERIAL    PRIMARY KEY,
    key          TEXT      UNIQUE NOT NULL,
    name         TEXT      NOT NULL,
    date_create  TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    date_update  TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    date_expiry  TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    ip           INET      NULL DEFAULT NULL,
    data         JSON      NOT NULL
);

-- 1 down
DROP TABLE IF EXISTS test;
DROP TABLE IF EXISTS projects;
DROP TABLE IF EXISTS session;


