package App::Codit::Plugins::Backups;

use strict;
use warnings;
use File::Basename;
use File::Path qw(make_path);

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 DESCRIPTION

Protect yourself against crashes. This plugin keeps backups of your unsaved files.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	
	$self->{INTERVAL} = 20000;
	
	$self->cmdHookAfter('doc_open', 'openDocAfter', $self);
	$self->cmdHookBefore('doc_new', 'openDocBefore', $self);

	$self->backupFolder;
	$self->{AFTERID} = $self->after($self->Interval, ['backupCycle', $self]);
	return $self;
}

sub backupCycle {
	my $self = shift;
	my $mdi = $self->extGet('CoditMDI');
	my @list = $mdi->docList;
	for (@list) {
		my $name = $_;
		next if $name =~/^Untitled/;
		if ($mdi->docModified($name)) {
			$self->backupSave($name);
		} else {
			$self->backupRemove($name);
		}
	}
	$self->backupCycleResume;
}

sub backupCyclePause {
	my $self = shift;
	$self->afterCancel($self->{AFTERID});
}

sub backupCycleResume {
	my $self = shift;
	$self->{AFTERID} = $self->after($self->Interval, ['backupCycle', $self]);
}

sub backupExists {
	my ($self, $name) = @_;
	my @list = $self->backupList;
	for (@list) {
		return 1 if $_ eq $name
	}
	return 0;
}

sub backupFile {
	my ($self, $name) = @_;
	$name =~ s/^\///;
	$name =~ s/\//_-_/g;
	return $self->backupFolder . "/$name";
}

sub backupFolder {
	my $self = shift;
	my $config = $self->extGet('ConfigFolder')->ConfigFolder . '/Backups';
	make_path($config) unless -e $config;
	return $config
}

sub backupList {
	my $self = shift;
	my $folder = $self->backupFolder;
	my @names = ();
	if (opendir my $dh, $folder) {
		while (my $file = readdir $dh) {
			push @names, $self->backupName($file);
		}
		closedir $dh
   }
   return @names
}

sub backupName {
	my ($self, $file) = @_;
	$file =~ s/_-_/\//g;
	$file = "/$file";
	return $file
}

sub backupRemove {
	my ($self, $name) = @_;
	my $file = $self->backupFile($name);
	unlink $file if -e $file;
}

sub backupRestore {
	my ($self, $name) = @_;
	my $file = $self->backupFile($name);
	my $mdi = $self->extGet('CoditMDI');
	my $widg = $mdi->docGet($name)->CWidg;
	if ($widg->load($file)) {
		$widg->editModified(1);
		return 1
	}
	return 0
}

sub backupSave {
	my ($self, $name) = @_;
	my $file = $self->backupFile($name);
	my $mdi = $self->extGet('CoditMDI');
	my $widg = $mdi->docGet($name)->CWidg;
	$widg->saveExport($file);
	return 0;
}

sub Interval {
	my $self = shift;
	$self->{INTERVAL} = shift if @_;
	return $self->{INTERVAL}
}

sub openDocAfter {
	my $self = shift;
	my $name = $self->{DOCNAME};
	if (defined $name) {
		if ($self->backupExists($name)) {
			my $title = 'Backup exists';
			my $text = 'A backup for ' . basename($name) . " exists.\nDo you want to recover?";
			my $icon = 'dialog-question';
			my $response = $self->popDialog($title, $text, $icon, qw/Yes No/);
			$self->after(300, ['backupRestore', $self, $name]) if $response eq 'Yes';
		}
		$self->backupCycleResume;
	}
	return @_;
}

sub openDocBefore {
	my $self = shift;
	
	my ($name ) = @_;
	$self->{DOCNAME} = undef;
	if (defined $name) {
		$self->{DOCNAME} = $name;
		$self->backupCyclePause;
	}
	return @_;
}

sub Unload {
	my $self = shift;
	$self->backupCyclePause;
	$self->cmdUnhookAfter('doc_open', 'openDocAfter', $self);
	$self->cmdUnhookBefore('doc_new', 'openDocBefore', $self);
}

1;







