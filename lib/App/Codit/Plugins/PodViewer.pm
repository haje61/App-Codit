package App::Codit::Plugins::PodViewer;

=head1 NAME

App::Codit::Plugins::PodViewer - plugin for App::Codit

=cut

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::PluginJobs );

require Tk::NoteBook;
require Tk::Pod::Text;

=head1 DESCRIPTION

Add a Perl pod viewer to your open files.

=head1 DETAILS

PodViewer adds a I<Pod> button to the toolbar. 
When you click it the frame of the current selected document 
will split and the bottom half will show the pod documentation
in your document.

The viewer is refreshed after you make an edit.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'ToolBar');
	return undef unless defined $self;

	$self->{DOCS} = {};
	$self->{MODIFIEDSAVE} = {};
	$self->interval(1000);
	$self->cmdHookAfter('doc_close', 'docCloseAfter', $self);
	$self->cmdHookBefore('doc_close', 'docBefore', $self);
	$self->cmdConfig(
		flip_pod => ['FlipPod', $self],
	);
	$self->jobStart('PodViewer', 'RefreshCycle', $self);
	return $self;
}

sub docCloseAfter {
	my ($self, $result) = @_;
	my $name = $self->{DOCNAME};
	$self->{DOCNAME} = undef;
	return 0 unless $result;
	if ((defined $name) and $result) {
		$self->PodRemove($name);
		delete $self->{DOCS}->{$name}
	}
	return $result
}

sub docBefore {
	my $self = shift;
	my ($name ) = @_;
	if (defined $name) {
		$self->{DOCNAME} = $name;
	}
	return @_;
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
		$self->Refresh;
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
	return unless defined $d;
	my ($pod, $adj, $podframe) = @$d;
	$adj->destroy if defined $adj;
	$podframe->destroy if defined $podframe;
	delete $docs->{$name};
	delete $self->{MODIFIEDSAVE}->{$name};
}

sub Refresh {
	my ($self, $name) = @_;
	my $mdi = $self->extGet('CoditMDI');
	my $widg = $mdi->docGet($name)->CWidg;
	my $file = $self->PodFile;
	my $pod = $self->{DOCS}->{$name}->[0];
	$widg->saveExport($file);
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
				$self->Refresh($name) if $em ne $modified
			} else {
				$self->Refresh($name)
			}
			$self->{MODIFIEDSAVE}->{$name} = $em;
		}
	}
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
	$self->SUPER::Unload;
	my @pods = $self->PodList;
	for (@pods) { $self->PodRemove($_) }
	unlink $self->PodFile;
	$self->cmdRemove('flip_pod');
	return 1
}

=head1 LICENSE

Same as Perl.

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 TODO

=over 4

=back

=head1 BUGS AND CAVEATS

If you find any bugs, please contact the author.

=head1 SEE ALSO

=over 4

=back

=cut


1;









