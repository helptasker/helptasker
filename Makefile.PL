use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	VERSION   => '0.01',
	PREREQ_PM => {
		'Mojolicious' => '6.14',
		'Minion::Backend::mysql' => '0.05',
		'Try::Tiny' => '0.24',
	},
	test=>{TESTS => 't/*.t'}
);


