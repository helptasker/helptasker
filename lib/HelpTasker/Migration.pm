package HelpTasker::Migration;
use Mojo::Base 'Mojolicious';
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

-- 1 down
DROP TABLE test;

