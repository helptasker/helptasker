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

CREATE TABLE project (
    project_id  SERIAL    PRIMARY KEY,
    name        TEXT      NOT NULL,
    date_create TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    date_update TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    fqdn        TEXT      UNIQUE NOT NULL,
    settings    JSON      NOT NULL
);

CREATE TABLE session (
    session_id   SERIAL    PRIMARY KEY,
    key          TEXT      UNIQUE NOT NULL,
    name         TEXT      NOT NULL,
    date_create  TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    date_update  TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    date_expire  TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    expire       INTEGER   NOT NULL,
    ip           INET      NULL DEFAULT NULL,
    data         JSON      NOT NULL
);

CREATE TABLE cache (
    cache_id    SERIAL    PRIMARY KEY,
    date_create TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    date_expire TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    key         TEXT      UNIQUE NOT NULL,
    value       JSON      NOT NULL
);

CREATE TABLE queue (
    queue_id    SERIAL    PRIMARY KEY,
    project_id  INTEGER   REFERENCES project ON DELETE CASCADE,
    date_create TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    date_update TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    name        TEXT      NOT NULL,
    type        SMALLINT  NOT NULL,
    settings    JSON      NOT NULL
);

CREATE TABLE "user" (
    user_id     SERIAL    PRIMARY KEY,
    date_create TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    date_update TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    lastname    TEXT      NOT NULL,
    firstname   TEXT      NOT NULL,
    login       TEXT      UNIQUE NOT NULL,
    password    TEXT      NOT NULL,
    email       TEXT      NOT NULL,
    settings    JSON      NOT NULL
);

CREATE INDEX index1 ON "user" (login);
CREATE INDEX index2 ON "user" (email);

CREATE TABLE user_log (
    user_log_id SERIAL      PRIMARY KEY,
    date_create TIMESTAMP with time zone NOT NULL DEFAULT current_timestamp,
    user_id     INTEGER     REFERENCES "user" ON DELETE CASCADE,
    code        INTEGER     NOT NULL,
    args        JSON        NOT NULL
);

-- 1 down
DROP TABLE IF EXISTS test;
DROP TABLE IF EXISTS session;
DROP TABLE IF EXISTS cache;
DROP TABLE IF EXISTS queue;
DROP TABLE IF EXISTS project;

DROP TABLE IF EXISTS user_log;
DROP TABLE IF EXISTS "user";



