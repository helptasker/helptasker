use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	VERSION   => '0.01',
    PREREQ_PM    => {'Mojolicious' => '6.11', 'DBD::mysql' => '4.028', 'DBI' => '1.631', 'Mojo::mysql' => 0},
	test=>{TESTS => 't/*.t'}
);


