package HelpTasker::Email;
use Mojo::Base 'Mojolicious';
use Mojo::Util qw(dumper);

use HelpTasker::Email::Parse;
use HelpTasker::Email::Message;

has 'parse' => sub { HelpTasker::Email::Parse->new(app=>shift->app) };
has 'message' => sub { HelpTasker::Email::Message->new(app=>shift->app) };

1;
