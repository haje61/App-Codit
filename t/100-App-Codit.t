
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 3;
$mwclass = 'App::Codit';

BEGIN { use_ok('App::Codit') };

createapp(
);


starttesting;

