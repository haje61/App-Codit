
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 3;
use File::Spec;
$mwclass = 'App::Codit';
$delay = 1500;

BEGIN { use_ok('App::Codit') };

createapp(
	-configfolder => File::Spec->rel2abs('t/settings'),
);


starttesting;


