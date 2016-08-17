package HelpTasker::Email;
use Mojo::Base 'HelpTasker::Base';
use Mojo::Util qw(dumper);

use HelpTasker::Email::Parse;
use HelpTasker::Email::Message;
use HelpTasker::Email::Send;
use HelpTasker::Email::Utils;

has 'parse' => sub { HelpTasker::Email::Parse->new(app=>shift->app) };
has 'message' => sub { HelpTasker::Email::Message->new(app=>shift->app) };
has 'send' => sub { HelpTasker::Email::Send->new(app=>shift->app) };
has 'utils' => sub { HelpTasker::Email::Utils->new(app=>shift->app) };


1;
