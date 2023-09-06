package App::Codit::SessionManager;

=head1 NAME

App::Codit - IDE for and in Perl

=cut

use strict;
use warnings;
use Carp;
require Tk::YAMessage;
use File::Copy;
use vars qw($VERSION);
$VERSION="0.01";

use base qw(Tk::Derived Tk::YADialog);
Construct Tk::Widget 'SessionManager';


sub Populate {
	my ($self,$args) = @_;
	
	my $plug = delete $args->{'-plugin'};
	die 'You must specify the -plugin option' unless defined $plug;

	$self->SUPER::Populate($args);

	my @padding = (-padx => 4, -pady => 4);

	my $art = $plug->extGet('Art');
	my $mb = $plug->extGet('MenuBar');
	
	my @sessions = ();
	$self->{SESSIONS} = \@sessions;
	$self->{PLUGIN} = $plug;
	my $lb = $self->Scrolled('Listbox',
		-scrollbars => 'osoe',
		-listvariable => \@sessions,
		-selectmode => 'single',
	)->pack(-side => 'left', @padding, -fill => 'y',);
	$self->Advertise('Listbox', $lb);

	my $bf = $self->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(-side => 'left', -fill => 'y', @padding);

	$bf->Button(
		-image => $art->CreateCompound(
			-text => 'Open',
			-image => $art->GetIcon('document-open', 22),
		),
		-anchor => 'w',
		-command => ['Open', $self],
	)->pack(@padding, -fill => 'x');
	$bf->Button(
		-image => $art->CreateCompound(
			-text => 'New session',
			-image => $art->GetIcon('document-new', 22),
		),
		-anchor => 'w',
		-command => ['NewSession', $self],
	)->pack(@padding, -fill => 'x');
	$bf->Label(-text => ' ')->pack(@padding);
	$bf->Button(
		-image => $art->CreateCompound(
			-text => 'Duplicate',
			-image => $mb->CreateEmptyImage(22, 22),
		),
		-anchor => 'w',
		-command => ['Duplicate', $self],
	)->pack(@padding, -fill => 'x');
	$bf->Button(
		-image => $art->CreateCompound(
			-text => 'Rename',
			-image => $mb->CreateEmptyImage(22, 22),
		),
		-anchor => 'w',
		-command => ['Rename', $self],
	)->pack(@padding, -fill => 'x');
	$bf->Label(-text => ' ')->pack(@padding);
	$bf->Button(
		-image => $art->CreateCompound(
			-text => 'Delete',
			-image => $art->GetIcon('edit-delete', 22),
		),
		-anchor => 'w',
		-command => ['Delete', $self],
	)->pack(@padding, -fill => 'x');

	$self->ConfigSpecs(
		-background => ['SELF', 'DESCENDANTS'],
		DEFAULT => [$self],
	);
	$self->Refresh;
}

sub Delete {
	my $self = shift;
	my $sel = $self->GetSelected;
	return unless defined $sel;
	my $plug = $self->{PLUGIN};
	return if $sel eq $plug->sessionCurrent;

	my $q = $self->YAMessage(
		-title => 'Deleting session',
		-image => $plug->getArt('dialog-warning', 32),
		-buttons => [qw(Yes No)],
		-text => "Deleting $sel.\nAre you sure?",
		-defaultbutton => 'No',
	);

	my $answer = $q->Show(-popover => $self);
	if ($answer eq 'Yes') {
		$plug->sessionDelete($sel);
		$self->Refresh;
	}
}

sub Duplicate {
	my $self = shift;
	my ($sel) = $self->GetSelected;
	return unless defined $sel;
	my $name = $self->NameDialog("Enter duplicate name:");
	my $plug = $self->{PLUGIN};
	return unless defined $name;
	return if $plug->sessionExists($name);
	my $f = $plug->sessionFolder;
	copy("$f/$sel", "$f/$name");
	$self->Refresh;
}

sub GetSelected {
	my $self = shift;
	my ($sel) = $self->Subwidget('Listbox')->curselection;
	return unless defined $sel;
	return $self->{SESSIONS}->[$sel]
}

sub NameDialog {
	my ($self, $text) = @_;
	my @padding = (-padx => 10, -pady => 10);
	my $plug = $self->{PLUGIN};
	my $q = $self->YADialog(
		-title => 'Session name',
# 		-image => $self->getArt('dialog-information', 32),
		-buttons => [qw(Ok Cancel)],
# 		-text => $text,
		-defaultbutton => 'Ok',
	);
	$q->Label(-image => $plug->getArt('dialog-information', 32))->pack(-side => 'left', @padding);
	my $f = $q->Frame->pack(-side => 'left', @padding);
	$f->Label(
		-anchor => 'w',
		-text => $text,
	)->pack(-fill => 'x', -padx => 2, -pady => 2);
	my $e = $f->Entry->pack(-padx => 2, -pady => 2);
	
	my $name;
	my $answer = $q->Show(-popover => $self);
	$name = $e->get if $answer eq 'Ok';

	$q->destroy;
	return $name
}

sub NewSession {
	my $self = shift;
	$self->{PLUGIN}->sessionNew;
	$self->Pressed('Close');
}

sub Open {
	my $self = shift;
	my $sel = $self->GetSelected;
	my $plug = $self->{PLUGIN};
	return unless defined $sel;
	return if $sel eq $plug->sessionCurrent;
	$plug->sessionOpen($sel);
	$self->Pressed('Close');
}

sub Refresh {
	my $self = shift;
	my $sessions = $self->{SESSIONS};
	while (@$sessions) { pop @$sessions }
	my @list = $self->{PLUGIN}->sessionList;
	for (@list) { push @$sessions, $_ }
}

sub Rename {
	my $self = shift;
	my ($sel) = $self->GetSelected;
	return unless defined $sel;
	my $name = $self->NameDialog("Rename session to:");
	return unless defined $name;
	my $plug = $self->{PLUGIN};
	return if $plug->sessionExists($name);
	my $f = $plug->sessionFolder;
	move("$f/$sel", "$f/$name");
	$self->Refresh;
}


1;
