package App::Codit::Plugins::PodViewer;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

require Tk::NoteBook;
require Tk::Pod::Text;

=head1 DESCRIPTION

Add a Perl pod viewer to your open files.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'ToolBar');
	return undef unless defined $self;

	$self->{DOCS} = {};
	$self->{MODIFIEDSAVE} = {};
	$self->{INTERVAL} =3;
	$self->{REFRESHID} = undef;
	$self->cmdConfig(
		flip_pod => ['FlipPod', $self],
	);
	return $self;
}

sub FlipPod {
	my $self = shift;
	my $mdi = $self->extGet('CoditMDI');
	my $name = $mdi->docSelected;
	return unless defined $name;
	my $page = $mdi->Interface->getPage($name);
	if (exists $self->{DOCS}->{$name}) {
		$self->PodRemove($name);
	} else {
		$self->PodAdd($name);
	}
}

sub PodAdd {
	my ($self, $name) = @_;
	my $mdi = $self->extGet('CoditMDI');
	my $page = $mdi->Interface->getPage($name);
	my $title = $self->configGet('-title');
	my $widg = $mdi->docGet($name)->CWidg;
	my $pod;
	my $podframe = $page->Frame->pack(-fill => 'both');
	my $bframe = $podframe->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(-fill => 'x');
	my $balloon = $self->extGet('Balloon');
	my $art = $self->extGet('Art');
	my $pr = $bframe->Button(
		-image => $art->CreateCompound(
			-image => $self->getArt('go-previous', 22),
			-text => 'Previous'
		),
		-relief => 'flat',
		-command => sub { $pod->history_move(-1) }
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$balloon->Attach($pr, -statusmsg => 'Previous document');
	my $nxt = $bframe->Button(
		-image => $art->CreateCompound(
			-image => $self->getArt('go-next', 22),
			-text => 'Next'
		),
		-relief => 'flat',
		-command => sub { $pod->history_move }
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$balloon->Attach($nxt, -statusmsg => 'Next document');
	my $zi = $bframe->Button(
		-image => $art->CreateCompound(
			-image => $self->getArt('zoom-in', 22),
			-text => 'Zoom in'
		),
		-relief => 'flat',
		-command => sub { $pod->zoom_in }
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$balloon->Attach($zi, -statusmsg => 'Zoom in');
	my $zo = $bframe->Button(
		-image => $art->CreateCompound(
			-image => $self->getArt('zoom-out', 22),
			-text => 'Zoom out'
		),
		-relief => 'flat',
		-command => sub { $pod->zoom_out }
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$balloon->Attach($zo, -statusmsg => 'Zoom out');
	my $zr = $bframe->Button(
		-image => $art->CreateCompound(
			-image => $self->getArt('zoom-original', 22),
			-text => 'Reset zoom'
		),
		-relief => 'flat',
		-command => sub { $pod->zoom_normal }
	)->pack(-side => 'left', -padx => 2, -pady => 2);
	$balloon->Attach($zr, -statusmsg => 'Reset zoom');
	$pod = $podframe->PodText(
		-file => $self->PodFile,
		-width => 20,
		-height => 10,
		-scrollbars => 'oe',
	)->pack(-expand => 1, -fill => 'both');
	$self->configPut(-title => $title);
	my $adj = $page->Adjuster(
		-side => 'bottom',
		-widget => $podframe,
	)->pack(-fill => 'x', -before => $podframe);
	$self->{DOCS}->{$name} = [$pod, $adj, $podframe];
	$self->RefreshCycle;
}

sub PodFile {
	my $self = shift;
	my $podfile = $self->extGet('ConfigFolder')->configGet('-configfolder') . '/temppod.pod';
	unless (-e $podfile) {
		if (open FH, ">", $podfile) {
			print FH "\n";
			close FH;
		}
	}
	return $podfile
}

sub PodList {
	my $self = shift;
	my $docs = $self->{DOCS};
	return keys %$docs
}

sub PodRemove {
	my ($self, $name) = @_;
	my $docs = $self->{DOCS};  
	my $d = $docs->{$name};
	my ($pod, $adj, $podframe) = @$d;
	$adj->destroy;
	$podframe->destroy;
	delete $docs->{$name};
	delete $self->{MODIFIEDSAVE}->{$name};
	my @l = keys %$docs;
	$self->RefreshCancel unless @l;
}

sub Refresh {
	my ($self, $name, $em) = @_;
	my $mdi = $self->extGet('CoditMDI');
	my $widg = $mdi->docGet($name)->CWidg;
	my $file = $self->PodFile;
	my $pod = $self->{DOCS}->{$name}->[0];
	$widg->saveExport($file);
	$self->{MODIFIEDSAVE}->{$name} = $em;
	my $title = $self->configGet('-title');
	$pod->reload;
	$self->configPut(-title => $title);
}

sub RefreshCycle {
	my $self = shift;
	my $mdi = $self->extGet('CoditMDI');
	my $name = $mdi->docSelected;
	my $docs = $self->{DOCS};
	if (defined $name) {
		if (exists $docs->{$name}) {
			my $widg = $mdi->docGet($name)->CWidg;
			my $em = $widg->editModified;
			my $modified = $self->{MODIFIEDSAVE}->{$name};
			if (defined $modified) {
				$self->Refresh($name, $em) if $em ne $modified
			} else {
				$self->Refresh($name, $em)
			}
		}
	}
	my $interval = $self->{INTERVAL};
	$self->{REFRESHID} = $self->after($interval * 1000, ['RefreshCycle', $self]);
}

sub RefreshCancel {
	my $self = shift;
	my $id = $self->{REFRESHID};
	$self->afterCancel($id) if defined $id;
}

sub ToolItems {
	return (
		[	'tool_separator',],
		[	'tool_button',	'Pod',	'flip_pod',	'documentation',	'Add or remove pod viewer'],
	)
}

sub Quit {
	my $self = shift;
	unlink $self->PodFile;
}

sub Unload {
	my $self = shift;
	my @pods = $self->PodList;
	for (@pods) { $self->PodRemove($_) }
	$self->RefreshCancel;
	unlink $self->PodFile;
	$self->cmdRemove('flip_pod');
	return 1
}

1;







