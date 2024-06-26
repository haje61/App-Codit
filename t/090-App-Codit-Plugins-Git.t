
use strict;
use warnings;
use Tk;

use Test::Tk;
use Test::More tests => 5;
use File::Spec;
use Config;
my $mswin = $Config{'osname'} eq 'MSWin32';
$mwclass = 'App::Codit';

$quitdelay = 1000 if $mswin;

BEGIN { use_ok('App::Codit::Plugins::Git') };

createapp(
	-plugins => ['Git'],
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
		return $pext->plugExists('Git') 
	}, 1, 'Plugin Git loaded' ],
	[ sub {
		pause(100);
		$pext->plugUnload('Git');
		my $b = $pext->plugGet('Git');
		return defined $b 
#		return $pext->plugExists('Git') 
	}, '', 'Plugin Git unloaded' ],
);

starttesting;

