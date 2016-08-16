package HelpTasker::command::postfixmime;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw(dumper spurt);

has description => 'Processor email messages ';
has usage       => "Usage: APPLICATION postfixmime [TARGET]\n";

sub run {
    my ($self, @args) = @_;

    #my $bytes = dumper(\@args);
    #while(<STDIN>) {
    #    $bytes .= $_
    #}; 

    #$bytes = spurt($bytes, '/tmp/email.msg');
    return;
}

1;
