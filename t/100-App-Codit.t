
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 3;
$mwclass = 'App::Codit';
$delay = 1500;

BEGIN { use_ok('App::Codit') };

createapp(
);


starttesting;

