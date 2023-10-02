package App::Codit::Plugins::Sessions;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

use File::Path qw(make_path);
require App::Codit::SessionManager;

my @saveoptions = (
	'-contentindent',
	'-contentposition',
	'-contentsyntax',
	'-contenttabs',
	'-contentwrap',
	'-showfolds',
	'-shownumbers',
	'-showstatus',
);

=head1 DESCRIPTION

Manage your sessions. Saves your named session on exit and reloads it on start.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'ConfigFolder', 'MenuBar');
	return undef unless defined $self;
	
	$self->sessionFolder;
	
	$self->{CURRENT} = '';
	$self->{DATA} = {};

	$self->cmdConfig(
		session_dialog => ['sessionDialog', $self],
		session_fill_menu => ['sessionFillMenu', $self],
		session_new => ['sessionNew', $self],
		session_open => ['sessionOpen', $self],
		session_save => ['sessionSave', $self],
		session_save_as => ['sessionSave', $self],
	);
	$self->cmdHookAfter('set_title', 'AdjustTitle', $self);
	return $self;
}

sub AdjustTitle {
	my $self = shift;
	my $mdi = $self->extGet('CoditMDI');
	my $doc = $mdi->docSelected;
	my $name = $self->configGet('-appname');
	if (defined $doc) {
		my $label = $mdi->docTitle($doc);
		$name = "$label - $name";
	}
	my $current = $self->sessionCurrent;
	if ($current ne '') {
		$name =  "$current: $name" ;
	}
	$self->configPut(-title => $name);
}

sub CanQuit {
	my $self = shift;
	$self->sessionSave unless $self->sessionCurrent eq '';
	$self->extGet('CoditMDI')->docForceClose(1);
	return 1
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label						cmd						icon					keyb			config variable
 		[	'menu', 				undef,			"~Session"], 
 		[	'menu', 				'Session::',	"~Open session",		'session_fill_menu'],
		[	'menu_normal',		'Session::',	"~New session",		'session_new',			'document-new'],
		[	'menu_separator',	'Session::',	'se1'],
		[	'menu_normal',		'Session::',	"~Save session",		'session_save',		'document-save'],
		[	'menu_normal',		'Session::',	"~Save session as",	'session_save_as',	'document-save'],
		[	'menu_separator',	'Session::',	'se1'],
		[	'menu_normal',		'Session::',	"~Manage sessions",	'session_dialog',		'configure'],
	)
}

sub sessionClose {
	my $self = shift;
	my $session = $self->sessionCurrent;
	my $mdi = $self->extGet('CoditMDI');
	if ($mdi->docConfirmSaveAll) {
		$self->sessionSave unless $session eq '';
		$self->sessionCurrent('');
		my @list = $self->sessionDocList;
		my $fc = $mdi->docForceClose;
		$mdi->docForceClose(1);
		my $if = $mdi->Interface;
		$mdi->selectDisabled(1);
		my $autoupdate = $if->autoupdate;
		$if->autoupdate(0);
		my $size = @list;
		my $count = 0;
		$self->progressAdd('multi_close', 'Close session', $size, \$count);
		for (@list) {
			$mdi->CmdDocClose($_);
			$count ++;
			$self->update;
		}
		$self->progressRemove('multi_close');
		$mdi->selectDisabled(0);
		$if->autoupdate($autoupdate);
		$mdi->docForceClose($fc);
		$self->AdjustTitle;
		return 1;
	}
	return 0
}

sub sessionCurrent {
	my $self = shift;
	$self->{CURRENT} = shift if @_;
	return $self->{CURRENT}
}

sub sessionDelete {
	my ($self, $name) = @_;
	return if $name eq $self->sessionCurrent;
	my $file = $self->sessionFolder . "/$name";
	unlink $file if -e $file;
}

sub sessionDocList {
	my $self = shift;
	my $interface = $self->extGet('CoditMDI')->Interface;
	my $disp = $interface->{DISPLAYED};
	my $undisp = $interface->{UNDISPLAYED};
	return @$disp, @$undisp;
}

sub sessionDialog {
	my $self = shift;
	my $d = $self->SessionManager(
		-plugin => $self,
		-popover => $self->toplevel,
	);
	$d->Show;
	$d->destroy;
}

sub sessionExists {
	my ($self, $name) = @_;
	return 1 if -e $self->sessionFolder . "/$name";
	return 0
}

sub sessionFillMenu {
	my $self = shift;
	my $mnu = $self->extGet('MenuBar');
	my @list = $self->sessionList;
	my $var = $self->sessionCurrent;
# 	print "current $var\n";
	my ($menu, $index) = $mnu->FindMenuEntry('Session::Open session');
	if (defined($menu)) {
		my $submenu = $menu->entrycget($index, '-menu');
		$submenu->delete(1, 'last');
		for (@list) {
			my $f = $_;
			$submenu->add('radiobutton',
				-variable => \$var,
				-value => $f,
				-label => $f,
				-command => sub { $self->sessionOpen($f) }
			);
		}
	}
}

sub sessionFolder {
	my $self = shift;
	my $config = $self->extGet('ConfigFolder')->ConfigFolder . '/Sessions';
	make_path($config) unless -e $config;
	return $config
}

sub sessionList {
	my $self = shift;
	my $dir = $self->sessionFolder;
	if (opendir(my $dh, $dir)) {
		my @list = ();
		while (my $thing = readdir $dh) {
			push @list, $thing unless $thing =~ /^\.+$/;
		}
		return sort @list
	}
}

sub sessionNew {
	my $self = shift;
	$self->sessionClose;
}

sub sessionOpen {
	my ($self, $name) = @_;

	my $file = "Sessions/$name";
	my $cff = $self->extGet('ConfigFolder');

	return if $name eq $self->sessionCurrent;
	return unless $cff->confExists($file);
	return unless $self->sessionClose;

	my @list = $cff->loadSectionedList($file, 'cdt session');

	my $mdi = $self->extGet('CoditMDI');
	my $if = $mdi->Interface;
	$mdi->selectDisabled(1);
	my $autoupdate = $if->autoupdate;
	$if->autoupdate(0);
	my $count = 0;
	my $size = @list;
	$self->progressAdd('multi_open', 'Open session', $size, \$count);
	my $select;
	for (@list) {
		my ($file, $options) = @$_;
		if ($file eq 'general') {
			$select = $options->{'selected'};
			$count ++
		} else {
			if ($self->cmdExecute('doc_open', $file)) {
				$mdi->deferredOptions($file, $options);
			}
			$count ++;
			$self->update;
		}
	}
	$self->progressRemove('multi_open');
	$self->sessionCurrent($name);
	$self->AdjustTitle;
	$mdi->selectDisabled(0);
	$if->autoupdate($autoupdate);
	$mdi->docSelect($select) if defined $select;
}

sub sessionSave {
	my $self = shift;
# 	print "sessionSave\n";

	my $name = $self->sessionCurrent;
	return $self->sessionSaveAs if $name eq '';

	my $file = "Sessions/$name";
	my $cff = $self->extGet('ConfigFolder');
	my $mdi = $self->extGet('CoditMDI');

	#getting all document names ordered as they are on the tab bar.
	my @items = $self->sessionDocList;
	my @list = (['general', {selected => $mdi->docSelected}]);
	for (@items) {
		my $item = $_;
		if ($mdi->deferredExists($item)) {
			my $options = $mdi->deferredOptions($item);
			my %h = %$options;
			push @list, [$item, \%h]
		} else {
			my $doc = $mdi->docGet($item);
			my %h = ();
			for (@saveoptions) { $h{$_} = $doc->cget($_) }
			push @list, [$item, \%h]
		}
	}
	$cff->saveSectionedList($file, 'cdt session', @list)
}

sub sessionSaveAs {
	my $self = shift;
	my $dialog = $self->YADialog(
		-buttons => ['Ok', 'Cancel'],
	);
	$dialog->Label(
		-text => 'Please enter a session name',
		-justify => 'left',
	)->pack(-fill => 'x', -padx => 3, -pady => 3);
	my $text = '';
	$dialog->Entry(
		-textvariable => \$text,
	)->pack(-fill => 'x', -padx => 3, -pady => 3);
	my $but = $dialog->show(-popover => $self->toplevel);
	if (($but eq 'Ok') and ($text ne '')) {
		$self->sessionCurrent($text);
		$self->sessionSave;
		$self->AdjustTitle;
	}
	
}

sub sessionValidateName {
	my ($self, $name) = @_;
	return 0 if $name eq '';
	return 0 if $name +~ /\//;
	return 0 if $name +~ /\\/;
	return 1
}

sub Unload {
	my $self = shift;
	for (qw/
		session_dialog
		session_fill_menu
		session_new
		session_open
		session_save
		session_save_as
	/) {
		$self->cmdRemove($_);
	}
	$self->sessionCurrent('');
	$self->cmdUnhookAfter('set_title', 'AdjustTitle', $self);
	$self->AdjustTitle;
	return 1
}



1;



