package Tk::AppWindow::Ext::CoditMDI;

=head1 NAME

Tk::AppWindow::Ext::CoditMDI - Multiple Document Interface

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.01";

use base qw( Tk::AppWindow::Ext::MDI );

require App::Codit::CoditTagsEditor;
require Tk::YADialog;

=head1 SYNOPSIS

 my $app = new App::Codit(@options,
    -extensions => ['CoditMDI'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

=head1 CONFIG VARIABLES

=over 4

none

=back

=head1 METHODS

=over 4

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->cmdConfig(
		highlightdialog => ['HighlightDialog', $self],
# 		doc_open_multi => ['CmdMultiOpen', $self],
	);
	return $self;
}

# sub CmdMultiOpen {
# 	my $self = shift;
# 	my $res = 1;
# 	my $count = 0;
# 	my $size = @_;
# 	my $sb = $self->extGet('StatusBar');
# 	$sb->AddProgressItem('multi_open',
# 		-from => 0,
# 		-to => $size,
# 		-variable => \$count,
# 	) if defined $sb;
# 	for (@_) {
# 		my $file = $_;
# 		$res = 0 unless $self->cmdExecute('doc_open', $file);
# 		$count ++;
# 		$self->update;
# 	}
# 	$sb->Delete('multi_open') if defined $sb;
# 	return $res
# }

sub HighlightDialog {
	my $self = shift;

	my $doc = $self->CurDoc;
 	unless (defined $doc) {
		$self->popMessage("You need one open document\nfor this to work.\n"); 
		return
 	}

 	my $themefile = $self->configGet('-highlight_themefile');
	my $historyfile = $self->extGet('ConfigFolder')->ConfigFolder . '/color_history';

	my $dialog = $self->YADialog(
		-title => 'Configure highlighting',
		-buttons => ['Ok', 'Close'],
	);

	my $editor = $dialog->CoditTagsEditor(
		-defaultbackground => $doc->cget('-contentbackground'),
		-defaultforeground => $doc->cget('-contentforeground'),
		-defaultfont => $doc->cget('-contentfont'),
		-historyfile => $historyfile,
		-themefile => $themefile,
	)->pack(-expand => 1, -fill => 'both');
	
	my $bf = $dialog->Subwidget('buttonframe');
	my $def = $bf->Button(
		-text => 'Defaults',
		-command => sub {
			$self->SetDefaultTheme;
			$editor->load($self->GetThemeFile);
			$editor->updateAll;
		}
	);
	$dialog->ButtonPack($def);
	my $save = $bf->Button(
		-text => 'Save',
		-command => sub {
			my $file = $self->getSaveFile(
				-filetypes => [
					['Highlight Theme' => '.ctt'],
				],
			);
			$editor->save($file) if defined $file;
		},
	);
	$dialog->ButtonPack($save);
	my $load = $bf->Button(
		-text => 'Load',
		-command => sub {
			my $file = $self->getOpenFile(
				-filetypes => [
					['Highlight Theme' => '.ctt'],
				],
			);
			if (defined $file) {
				my $obj = Tk::CodeText::Theme->new;
				$obj->load($file);
				$editor->put($obj->get);
				$editor->updateAll
			}
		},
	);
	$dialog->ButtonPack($load);

	my $button = $dialog->Show(-popover => $self->GetAppWindow);
	if ($button eq 'Ok') {
		$editor->save($themefile);
		my @list = $self->DocList;
		for (@list) {
			my $d = $self->docGet($_);
			$d->configure(-themefile => $themefile);
		}
	}

	$dialog->destroy;
}

sub MenuItems {
	my $self = shift;
	my @items = $self->SUPER::MenuItems;
	return (@items,
		[	'menu_normal',		'appname::Settings',		'~Highlighting',	'highlightdialog',	'configure',		'F10',	], 
	);
}

# sub SettingsPage {
# 	my $self = shift;
# 	my $doc = $self->CurDoc;
# 	return () unless defined $doc;
# 	my $themefile = $self->configGet('-themefile');
# 	print "themefile $themefile\n";
# 	my $historyfile = $self->extGet('ConfigFolder')->ConfigFolder . '/color_history';
# 	print "historyfile $historyfile\n";
# 	my @opt = (
# 		-defaultbackground => $doc->cget('-contentbackground'),
# 		-defaultforeground => $doc->cget('-contentforeground'),
# 		-defaultfont => $doc->cget('-contentfont'),
# 		-historyfile => $historyfile,
# 		-themefile => $themefile,
# 	);
# 	push @opt, -balloon => $self->extGet('Balloon')->Balloon if $self->extExists('Balloon');
# 	return (
# 		'Highlighting' => ['CoditTagsEditor', @opt]
# 	)
# }

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4


=back

=cut

1;
