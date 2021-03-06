use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Mojolicious::Plugin::BootstrapHelpers',
  VERSION_FROM => 'lib/Mojolicious/Plugin/BootstrapHelpers.pm',
  AUTHOR       => 'Quim Rovira <met@cpan.org>',
  PREREQ_PM    => {'Mojolicious' => '4.91'},
  test         => {TESTS => 't/*.t'}
);
