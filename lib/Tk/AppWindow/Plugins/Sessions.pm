package Tk::AppWindow::Plugins::Sessions;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

use File::Path qw(make_path);
require App::Codit::SessionManager;

my @saveoptions = ('-indentstyle', '-position', '-showfolds', '-shownumbers', '-showstatus', '-syntax', '-tabs', '-wrap');

=head1 DESCRIPTION

Manage your sessions. Saves your named session on exit and reloads it on start.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'ConfigFolder', 'MenuBar', 'Navigator');
	return undef unless defined $self;
	
	$self->sessionFolder;
	
	$self->{CURRENT} = '';

	$self->cmdConfig(
		session_dialog => ['sessionDialog', $self],
		session_fill_menu => ['sessionFillMenu', $self],
		session_new => ['sessionNew', $self],
		session_open => ['sessionOpen', $self],
		session_save => ['sessionSave', $self],
		session_save_as => ['sessionSave', $self],
	);
	return $self;
}

sub CanQuit {
	my $self = shift;
	$self->sessionSave unless $self->sessionCurrent eq '';
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
	$self->sessionSave unless $session eq '';
	$self->sessionCurrent('');
	my $mdi = $self->extGet('CoditMDI');
	if ($mdi->CanQuit) {
		my @list = $mdi->docList;
		my $fc = $mdi->docForceClose;
		$mdi->docForceClose(1);
		for (@list) {
			$mdi->CmdFileClose($_);
		}
		$mdi->docForceClose($fc);
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
	return if $name eq $self->sessionCurrent;
	my $file = $self->sessionFolder . "/$name";
	if (open(OFILE, "<", $file)) {
		my @list = ();
		my $section;
		my %inf = ();
		while (<OFILE>) {
			my $line = $_;
			chomp $line;
			if ($line =~ /^\[([^\]]+)\]/) { #new section
# 				print "new section $1\n";
				if (defined $section) {
# 					print "pushing $section\n";
					my %o = %inf;
					push @list, [$section, \%o]
				}
				$section = $1;
				%inf = ();
			} elsif ($line =~ s/^([^=]+)=//) { #new key
				$inf{$1} = $line;
			}
		}
		push @list, [$section, \%inf] if (%inf) and (defined $section);
		close OFILE;
		return unless $self->sessionClose;
		my $mdi = $self->extGet('CoditMDI');
		my $if = $mdi->Interface;
		my $seloncreate = $mdi->selectOnCreate;
		my $autoupdate = $if->AutoUpdate;
		$if->AutoUpdate(0);
		$mdi->selectOnCreate(0);
		my $count = 0;
		my $size = @list;
		my $sb = $self->extGet('StatusBar');
		$sb->AddProgressItem('multi_open',
			-label => 'Opening session',
			-length => 150,
			-from => 0,
			-to => $size,
# 			-blocks => int($size/2),
			-variable => \$count,
		) if defined $sb;
# 		use Data::Dumper; print Dumper \@list;
		my $select;
		for (@list) {
			my ($file, $options) = @$_;
			if ($file eq 'general') {
				$select = $options->{'selected'};
				$count ++
			} else {
				if ($self->cmdExecute('file_open', $file)) {
					my $doc = $mdi->docGet($file);
					for (@saveoptions) {
						$doc->configure($_, $options->{$_});
					}
				}
				$count ++;
				$self->update;
			}
# 			print $count , "\n";
		}
		$sb->Delete('multi_open') if defined $sb;
		$self->sessionCurrent($name);
		$mdi->selectOnCreate($seloncreate);
		$if->AutoUpdate($autoupdate);
		$mdi->Select($select) if defined $select;
		return 1
	} else {
		warn "Cannot open session file: $file"
	}
	return 0;
}

sub sessionSave {
	my $self = shift;
# 	print "sessionSave\n";

	my $name = $self->sessionCurrent;
	return $self->sessionSaveAs if $name eq '';

	my $file = $self->sessionFolder . "/$name";

	#getting all document names ordered as they are on the tab bar.
	my $mdi = $self->extGet('CoditMDI');
	my $interface = $mdi->Interface;
	my $disp = $interface->{DISPLAYED};
	my $undisp = $interface->{UNDISPLAYED};
	my @items = (@$disp, @$undisp);

	#writing to file
	if (open(OFILE, ">", $file)) {
		for (@items) {
			my $docname = $_;
			if (-e $docname) {
				print OFILE "[$docname]\n";
				my $doc = $mdi->docGet($docname);
				for (@saveoptions) {
					print OFILE $_, '=', $doc->cget($_), "\n";
				}
			}
		}
		print OFILE "[general]\n";
		print OFILE "selected=", $mdi->docSelected, "\n";
		close OFILE;
		return 1
	}
	return 0
}

sub sessionSaveAs {
	my $self = shift;
	print "sessionSave as\n";
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
	return 1
}



1;
