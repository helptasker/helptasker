package HelpTasker::command::maxmind;
use Mojo::Base 'Mojolicious::Command';
use Mojo::Util qw(dumper spurt);
use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use File::Path qw(make_path);
use File::stat;
use Carp qw(croak);

has description => 'Loading geodatabase (maxmind.com)';
has usage       => sub { shift->extract_usage };


sub run {
    my ($self, @args) = @_;

    my %param = ();
    my $options = {
        'v|verbose'=>\($param{'verbose'}),
    };
    GetOptionsFromArray(\@args,%{$options});

    # Dir create from maxmind files
    my $path = Mojo::Path->new($self->app->config('api_geo_module_maxmind_base_dir'))->canonicalize;
    my $filename = Mojo::Path->new($self->app->config('api_geo_module_maxmind_base_dir').'/GeoLite2-City.mmdb')->canonicalize;
    make_path($path) if(!-d $path);

    croak qq/Permission denied $path/ if(!-w $path);

    if(-r $filename){
        my $st = stat($filename);
        my $age = time() - $st->ctime;
        if($age <= 60*60*24*7){
            say 'Database not updated, age:'.$age if(defined $param{'verbose'});
            return;
        }
    }

    my $tx = $self->app->ua->build_tx(GET=>'https://geolite.maxmind.com/download/geoip/database/GeoLite2-City.mmdb.gz');
    $tx->res->max_message_size(0);

    my $count = 0;
    $tx->res->content->on(read => sub {
        my ($content, $bytes) = @_;
        $count = $count + length($bytes);
        print "\rProcessing download ".int($count / 1024).' Kb' if(defined $param{'verbose'});
    });

    # Process transaction
    $tx = $self->app->ua->start($tx);
    $self->app->api->utils->error_tx($tx);

    my $asset = $tx->res->content->asset;
    if(defined $asset->is_file && $asset->is_file == 1){
        my $output;
        gunzip($tx->res->content->asset->path => \$output) or croak "gunzip failed!\n";
        spurt($output, $filename);
        my $size = int($count / 1024 / 1024);
        print "\rLoading is complete (file size $size MB), path:$filename\n" if(defined $param{'verbose'});
        return;
    }
    return;
}

1;

=encoding utf8
 
=head1 NAME
 
HelpTasker::command::maxmind - Loading geodatabase (maxmind.com)
 
=head1 SYNOPSIS
 
  Usage: APPLICATION maxmind [OPTIONS]
 
    ./myapp.pl maxmind
 
  Options:
    -h, --help      Show this summary of available options
    -v, --verbose   Print verbose debug information to STDERR
 
=head1 DESCRIPTION
 
L<Mojolicious::Command::test> runs application tests from the C<t> directory.
 
This is a core command, that means it is always enabled and its code a good
example for learning to build new commands, you're welcome to fork it.
 
See L<Mojolicious::Commands/"COMMANDS"> for a list of commands that are
available by default.
 
=head1 ATTRIBUTES
 
L<Mojolicious::Command::test> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.
 
=head2 description
 
  my $description = $test->description;
  $test           = $test->description('Foo');
 
Short description of this command, used for the command list.
 
=head2 usage
 
  my $usage = $test->usage;
  $test     = $test->usage('Foo');
 
Usage information for this command, used for the help screen.
 
=head1 METHODS
 
L<Mojolicious::Command::test> inherits all methods from L<Mojolicious::Command>
and implements the following new ones.
 
=head2 run
 
  $test->run(@ARGV);
 
Run this command.
 
=head1 SEE ALSO
 
L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.
 
=cut

