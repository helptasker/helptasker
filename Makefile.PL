use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	VERSION   => '0.01',
	PREREQ_PM => {
		'Mojolicious' => '6.66',
		'DBD::mysql' => '4.034',
		'Mojo::mysql' => '0.14',
	},
	test=>{TESTS => 't/*.t'}
);


