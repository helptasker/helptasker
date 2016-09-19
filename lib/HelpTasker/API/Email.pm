package HelpTasker::API::Email;
use Mojo::Base 'HelpTasker::API::Base';
use Mojo::Util qw(dumper);

use HelpTasker::API::Email::Parse;
use HelpTasker::API::Email::Message;
use HelpTasker::API::Email::Send;
use HelpTasker::API::Email::Utils;

has 'parse' => sub { HelpTasker::API::Email::Parse->new(app=>shift->app) };
has 'message' => sub { HelpTasker::API::Email::Message->new(app=>shift->app) };
has 'send' => sub { HelpTasker::API::Email::Send->new(app=>shift->app) };
has 'utils' => sub { HelpTasker::API::Email::Utils->new(app=>shift->app) };


1;
