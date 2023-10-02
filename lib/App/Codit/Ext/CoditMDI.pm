package App::Codit::Ext::CoditMDI;

=head1 NAME

App::Codit::Ext::CoditMDI - Multiple Document Interface

=cut

use strict;
use warnings;
use Carp;
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
	$self->configInit(
		-doc_autoindent => ['docAutoIndent', $self],
		-doc_wrap => ['docWrap', $self],
		-doc_view_folds => ['docViewFolds', $self],
		-doc_view_numbers => ['docViewNumbers', $self],
		-doc_view_status => ['docViewStatus', $self],
	);
	$self->cmdConfig(
		doc_autoindent => ['docAutoIndent', $self],
		doc_select => ['docSelect', $self],
		doc_find => ['docPopFindReplace', $self, 1],
		doc_replace => ['docPopFindReplace', $self, 0],
		doc_wrap => ['docWrap', $self],
		edit_delete => ['editDelete', $self],
		edit_insert => ['editInsert', $self],
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

sub deferredList {
	my $self = shift;
	my $deferred = $self->{DEFERRED}; 
	return sort keys %$deferred;
}

sub deferredExists {
	my ($self, $name) = @_;
	my $deferred = $self->{DEFERRED}; 
	return 1 if exists $deferred->{$name};
	return 0
}

sub docAutoIndent {
	my $self = shift;
	return $self->docOption('-contentautoindent', @_);
}

sub docOption {
	my $self = shift;
	my $item = shift;
	croak 'Option is not defined' unless defined $item;
	return if $self->configMode;
	my $sel = $self->docSelected;
	return unless defined $sel;
	my $doc = $self->docGet($sel);
	if (@_) {
		print "configuring $sel\n";
		$doc->configure($item, shift);
	}
	return $doc->cget($item);
}

sub docPopFindReplace {
	my ($self, $event, $flag) = @_;
	my $sel = $self->docSelected;
	return unless defined $sel;
	my $doc = $self->docGet($sel);
	$doc->CWidg->FindAndOrReplace($flag);
}

sub docViewFolds {
	my $self = shift;
	return $self->docOption('-showfolds', @_);
}

sub docViewNumbers {
	my $self = shift;
	return $self->docOption('-shownumbers', @_);
}

sub docViewStatus {
	my $self = shift;
	return $self->docOption('-showstatus', @_);
}

sub docWrap {
	my $self = shift;
	return $self->docOption('-contentwrap', @_);
}

sub editDelete {
	my $self = shift;
	my $doc = $self->docSelected;
	$self-docGet($doc)->delete(@_) if defined $doc;
}


sub editInsert {
	my $self = shift;
	my $doc = $self->docSelected;
	$self-docGet($doc)->insert(@_) if defined $doc;
}


sub HighlightDialog {
	my $self = shift;

	my @doclist = $self->docList;
 	unless (@doclist) {
		$self->popMessage("You need one open document\nfor this to work.\n"); 
		return
 	}
 	my $doc = $self->docGet($doclist[0]);

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
		my @list = $self->docList;
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
      [ 'menu_normal',    'appname::Settings', '~Highlighting',   'highlightdialog',     'configure', 'F10',],
      [ 'menu',           undef,             '~Edit'], 
      [ 'menu_normal',    'Edit::',           '~Copy',             '<Control-c>',	      'edit-copy',      '*CTRL+C'], 
      [ 'menu_normal',    'Edit::',          'C~ut',					'<Control-x>',			'edit-cut',	      '*CTRL+X'], 
      [ 'menu_normal',    'Edit::',          '~Paste',            '<Control-v>',	      'edit-paste',     '*CTRL+V'], 
      [ 'menu_separator', 'Edit::',          'e1' ], 
      [ 'menu_normal',    'Edit::',          'U~ndo',             '<Control-z>',       'edit-undo',      '*CTRL+Z'], 
      [ 'menu_normal',    'Edit::',          '"~Redo',            '<Control-Z>',       'edit-redo',      '*CTRL+SHIFT+Z'], 
      [ 'menu_separator', 'Edit::',          'e2'], 
      [ 'menu_normal',    'Edit::',          'Co~mment',          '<Control-g>',       undef,            '*CTRL+G'], 
      [ 'menu_normal',    'Edit::',          '~Uncomment',        '<Control-G>',       undef,            '*CTRL+SHIFT+G'], 
      [ 'menu_separator', 'Edit::',          'e3' ], 
      [ 'menu_normal',    'Edit::',          '~Indent',           '<Control-j>',       undef,            '*CTRL+J'], 
      [ 'menu_normal',    'Edit::',          'Unin~dent',         '<Control-J>',       undef,            '*CTRL+SHIFT+J'], 
      [ 'menu_separator', 'Edit::',          'e4' ], 
      [ 'menu_normal',    'Edit::',          '~Select all',       '<Control-a>',       'edit-select-all','*CTRL+A'], 
      [ 'menu_separator', 'View::',          'v1' ],
      [ 'menu_check',     'View::',          'Show ~folds',          undef,   '-doc_view_folds', undef, 0, 1], 
      [ 'menu_check',     'View::',          'Show ~line numbers',   undef,   '-doc_view_numbers', undef, 0, 1], 
      [ 'menu_check',     'View::',          'Show ~document status',undef,   '-doc_view_status', undef, 0, 1], 
      [ 'menu',           undef,             '~Tools'],
      [ 'menu_normal',    'Tools::',         '~Find',             'doc_find',          'edit-find',      'CTRL+F',],
      [ 'menu_normal',    'Tools::',         '~Replace',	         'doc_replace',       'edit-find-replace','CTRL+R',],
      [ 'menu_separator', 'Tools::',          't1' ],
      [ 'menu_check',     'Tools::',          'A~uto indent',     undef,   '-doc_autoindent', undef, 0, 1], 
#       [ 'menu',           'Tools::',          '~Wrap'],
      [ 'menu_radio_s',   'Tools::',          '~Wrap',  [qw/char word none/],  undef, '-doc_wrap'], 
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



