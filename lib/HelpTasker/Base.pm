package HelpTasker::Base;
use Mojo::Base -base;
use Mojo::Util qw(dumper);

has ['pg','log','validation','ua','config','lib','model','sql'];

1;
