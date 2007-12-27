use strict;
use inc::Module::Install;

name            'selfvars';
all_from        'lib/selfvars.pm';
build_requires  'Test::More';

auto_include_deps;

sign; WriteAll;
