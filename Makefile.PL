use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::PgAsync',
  VERSION_FROM => 'lib/Mojolicious/Plugin/PgAsync.pm',
  AUTHOR       => 'Alexander Romanenko <romanenko@cpan.org>',
  PREREQ_PM    => {
	  				'Mojolicious' => '4.30',
					'DBD::Pg' => '2.19.0',
				},
  test         => {TESTS => 't/*.t'}
);
