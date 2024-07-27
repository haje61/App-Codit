
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 6;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$delay = 3000;
$quitdelay = 1000;
$delay = 5000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::Sessions') };

createapp(
	-plugins => ['Sessions'],
	-width => 800,
	-height => 600,
	-configfolder => File::Spec->rel2abs('t/settings'),
);

my $pext;
if (defined $app) {
	$pext = $app->extGet('Plugins');
}
push @tests, (
	[ sub { 
		return $pext->plugExists('Sessions') 
	}, 1, 'Plugin Sessions loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('Sessions');
		my $b = $pext->plugGet('Sessions');
		return defined $b 
#		return $pext->plugExists('Sessions') 
	}, '', 'Plugin Sessions unloaded' ],
	[ sub {
		$pext->plugLoad('Sessions');
		return $pext->plugExists('Sessions') 
	}, 1, 'Plugin Sessions reloaded' ],
);

starttesting;

