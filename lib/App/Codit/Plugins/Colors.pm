package App::Codit::Plugins::Colors;

use strict;
use warnings;
require Tk::ColorPicker;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 DESCRIPTION

Easily select and insert colors.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'ToolPanel');
	return undef unless defined $self;
	
	my $tp = $self->extGet('ToolPanel');
	my $page = $tp->addPage('Colors', 'fill-color', 'Select and insert colors');
	
	my $color = '';
	my @padding = (-padx => 3, -pady => 3);
	my $picker;
	my $indicator;

	my $eframe = $page->Frame->pack(-fill => 'x');

	my $fframe = $eframe->Frame->pack(-side => 'left');

	my $entry = $fframe->Entry(
		-textvariable => \$color,
	)->pack(@padding, -fill => 'x');
	$entry->bind('<Key>', sub {
		if ($picker->validate($color)) {
			$indicator->configure(-background => $color);
			$entry->configure(-foreground => $self->configGet('-foreground'));
			$picker->put($color);
		} else {
			$indicator->configure(-background => $self->configGet('-background'));
			$entry->configure(-foreground => $self->configGet('-errorcolor'));
		}
	});

	my $bframe = $fframe->Frame->pack(-fill => 'x');

	$bframe->Button(
		-text => 'Insert',
		-command => sub {
			if ($picker->validate($color)) {
				$self->cmdExecute('edit_insert', 'insert', $color);
				$picker->historyAdd($color);
				$picker->historyUpdate;
			}
		},
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');

	$bframe->Button(
		-text => 'Copy',
		-command => sub {
			if ($picker->validate($color)) {
				$self->clipboardClear;
				$self->clipboardAppend($color);
				$picker->historyAdd($color);
				$picker->historyUpdate;
			}
		},
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'x');

	$indicator = $eframe->Label(
		-width => 4,
		-relief => 'sunken',
		-borderwidth => 2,
	)->pack(@padding, -side => 'left', -expand => 1, -fill => 'both');

	$picker = $page->ColorPicker(
		-depthselect => 1,
		-historyfile => $self->extGet('ConfigFolder')->ConfigFolder . '/color_history',
		-updatecall => sub {
			$color = shift;
			$indicator->configure(-background => $color);
		}
	)->pack(-padx => 2, -pady => 2, -expand => 1, -fill => 'both');
	return $self;
}


sub Unload {
	my $self = shift;
	$self->extGet('ToolPanel')->deletePage('Colors');
	return 1
}


1;
