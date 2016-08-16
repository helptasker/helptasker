use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	VERSION   => '0.01',
    PREREQ_PM    => {
		'Mojolicious' => '7.01',
		'DBI' => '1.631',
        'Mojo::Pg' => '2.29',
        'EV' => '4.22',
        'IO::Socket::Socks' => '0.68',
        'IO::Socket::SSL' => '2.036',
        'Net::DNS::Native' => '0.15',
        'MIME::Tools' => '5.507',
        'MIME::Lite' => '3.030',
        'Data::Random' => '0.12',
	},
	test=>{TESTS => 't/*.t'}
);


