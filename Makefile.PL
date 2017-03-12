use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    VERSION   => '0.01',
    META_MERGE => {
        dynamic_config => 0,
        'meta-spec'    => {version => 2},
        no_index       => {directory => ['t']},
        prereqs        => {
            runtime => {
                requires => {perl => '5.010001'}
            }
        },
        resources      => {
            bugtracker => {
                web => 'https://github.com/helptasker/helptasker/issues'
            },
            homepage   => 'http://helptasker.org',
            license    => ['http://www.perlfoundation.org/artistic_license_2_0'],
            repository => {
                type => 'git',
                url  => 'https://github.com/helptasker/helptasker.git',
                web  => 'https://github.com/helptasker/helptasker/',
            },
        },
    },
    PREREQ_PM    => {
        'Mojolicious' => '7.28',
        'Mojo::Pg' => '3.05',
        'EV' => '4.22',
        'IO::Socket::Socks' => '0.73',
        'IO::Socket::SSL' => '2.047',
        'Net::DNS::Native' => '0.15',
        'Number::Phone'=>'3.3000',
        'Text::Xslate' => '3.4.0',
        'SQL::Abstract::More' => '1.28',
        'Email::Valid' => '1.202',
    },
    EXE_FILES => ['script/helptasker'],
    test=>{TESTS => 't/*.t t/*/*.t'}
);


