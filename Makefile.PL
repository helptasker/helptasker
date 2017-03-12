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
        'DBI' => '1.631',
        'Mojo::Pg' => '2.30',
        'EV' => '4.22',
        'IO::Socket::Socks' => '0.68',
        'IO::Socket::SSL' => '2.036',
        'Net::DNS::Native' => '0.15',
        'MIME::Tools' => '5.507',
        'MIME::Lite' => '3.030',
        'Data::Random' => '0.12',
        'File::Type' => '0.22',
        'Net::SMTP_auth' => '0.08',
        'Email::Valid' => '1.202',
        'Net::Domain::TLD' => '1.74',
        'Text::Iconv' => '1.7',
        'Net::IP' => '1.26',
        'HTML::Strip' => '2.10',
        'Data::Random' => '0.12',
        'Mojo::ACME' => '0.07',
        'SQL::Abstract::More' => '1.28',
        'Cache::Memcached::Fast' => '0.23',
        'Data::Pageset' => '1.06',
        'GeoIP2' => '2.003001',
        'Locale::Maketext' => '1.28',
        'Text::Xslate' => '3.3.9',
    },
    EXE_FILES => ['script/helptasker'],
    test=>{TESTS => 't/*.t t/*/*.t'}
);


