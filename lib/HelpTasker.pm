package HelpTasker;
use Mojo::Base 'Mojolicious';
use Mojo::Util qw(dumper);
use Mojo::mysql;

sub startup {
	my $self = shift;

	#$self->moniker('helptasker');
	#$self->mode('development');

	#$self->namespaces;
	#$self->type;
	$self->default_config;
	$self->helper(mysql => sub { state $mysql = Mojo::mysql->new($self->config('mysql'))});

	my $r = $self->routes;
	$r->get('/')->to('example#welcome');
}


sub namespaces {
	my ($self) = @_;
	push @{$self->app->commands->namespaces}, 'HelpTasker::command';
	push @{$self->app->plugins->namespaces},  'HelpTasker::plugin';
	return;
}

sub type {
	my ($self) = @_;
	$self->app->types->type(txt=>'text/plain; charset=utf-8');
	$self->app->types->type(html=>'text/html; charset=utf-8');
	$self->app->types->type(xml=>'text/xml; charset=utf-8');
	$self->app->types->type(json=>'application/json; charset=utf-8');
	return;
}

sub default_config {
	my $self = shift;

	my $config = {
	};

	if(defined $ENV{'TRAVIS'}){
		$config = $self->app->plugin('Config', {default=>$config});
		$config->{'mysql'} = 'mysql://root@/test';
		return $config;

	}
	elsif(defined $ENV{'MOJO_TEST'} && $ENV{'MOJO_TEST'} == 1){
		$config = $self->app->plugin('Config', {default=>$config});
		$config->{'mysql'} = 'mysql://test@/test';
		return $config;
	}
	elsif(-f '/etc/helptasker.conf'){
		return $self->app->plugin('Config', {default=>$config, file=>'/etc/helptasker.conf'});
	}
	else{
		return $self->app->plugin('Config', {default=>$config});
	}

}

1;
