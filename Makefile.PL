use ExtUtils::MakeMaker;

use strict;
my %prereq = (
	'Test::Tk'							=> '3.02',
	'Tk'									=> '804.023',
	'Tk::AppWindow'					=> '0.02',
	'Tk::CodeText'						=> '0.18',
);

WriteMakefile(
	NAME					=> 'App::Codit',
	VERSION_FROM		=> 'lib/App/Codit.pm',
	PREREQ_PM			=> \%prereq,
	ABSTRACT_FROM		=> 'lib/App/Codit.pm',
	AUTHOR				=> 'Hans Jeuken <hanje at cpan dot org>',
	EXE_FILES => ['bin/codit'],
	LICENSE				=> 'perl',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
         repository => {
            type => 'git',
            url  => 'git://github.com/haje61/App-Codit.git',
            web  => 'https://github.com/haje61/App-Codit',
         },
      }}
    ) : () ),
);

