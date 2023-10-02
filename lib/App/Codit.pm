package App::Codit;

=head1 NAME

App::Codit - IDE for and in Perl

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;
require App::Codit::CodeTextManager;

use base qw(Tk::Derived Tk::AppWindow);
Construct Tk::Widget 'Codit';

sub Populate {
	my ($self,$args) = @_;

	my $iconsizes = sub  { return $self->cmdExecute('available_icon_sizes') };
	my %opts = (
		-appname => 'Codit',
		-logo => Tk::findINC('App/Codit/codit.png'),
		-extensions => [qw[Art Balloon CoditMDI ToolBar StatusBar MenuBar Navigator ToolPanel Help Settings Plugins]],
		-availableplugs => [qw/Backups Bookmarks Colors Console FileBrowser Git 
			PerlSubs PodViewer SearchReplace Sessions Snippets WordCompletion/],
		-documentinterface => 'CoditMDI',
		-namespace => 'App::Codit',
#		-plugins => [qw/Sessions/],

		-aboutinfo => {
			version => $VERSION,
			author => 'Hans Jeuken',
			license => 'Same as Perl',
		},
		-helpfile => Tk::findINC('App/Codit/Help/index.html'),
		-helptype => 'html',

		-contentmanagerclass => 'CodeTextManager',
		-contentmanageroptions => [
			'-contentautoindent', 
			'-contentbackground', 
			'-contentfont', 
			'-contentforeground', 
			'-contentindent', 
			'-contenttabs', 
			'-contentwrap',
			'-showfolds',
			'-shownumbers',
			'-showstatus',
			'-highlight_themefile',
		],

		-contentautoindent => 1, 
		-contentindent => 'tab',
		-contenttabs => '8m',
		-contentwrap => 'none',
		-showfolds => 1,
		-shownumbers => 1,
		-showstatus => 1,


		-toolitems => [
	#			 type					label			cmd					icon					help		
			[	'tool_separator' ],
			[	'tool_button',		'Copy',		'<Control-c>',		'edit-copy',		'Copy selected text to clipboard'], 
			[	'tool_button',		'Cut',		'<Control-x>',		'edit-cut',			'Move selected text to clipboard'], 
			[	'tool_button',		'Paste',		'<Control-v>',		'edit-paste',		'Paste clipboard content into document'], 
			[	'tool_separator' ],
			[	'tool_button',		'Undo',		'<Control-z>',		'edit-undo',		'Undo last action'], 
			[	'tool_button',		'Redo',		'<Control-Z>',		'edit-redo',		'Cancel undo'], 
		],

		-useroptions => [
			'*page' => 'Editing',
			'*section' => 'Text',
			-contentforeground => ['color', 'Foreground'],
			-contentbackground => ['color', 'Background'],
			-contentfont => ['font', 'Font'],
			'*end',
			'*section' => 'Editor settings',
			-contentautoindent => ['boolean', 'Auto indent'],
			-contentindent => ['text', 'Indent style'],
			-contenttabs => ['text', 'Tab size'],
			-contentwrap => ['radio', 'Wrap', -values => [qw[none char word]]],
			'*end',
			'*section' => 'Indicators',
			-showfolds => ['boolean', 'Show fold indicators'],
			-shownumbers => ['boolean', 'Show line numbers'],
			-showstatus => ['boolean', 'Show document status'],
			'*end',

			'*page' => 'GUI',
			'*section' => 'Icon sizes',
			-iconsize => ['list', 'General', -values => $iconsizes],
			-menuiconsize => ['list', 'Menu bar', -values => $iconsizes],
			-tooliconsize => ['list', 'Tool bar', -values => $iconsizes],
			-navigatorpaneliconsize => ['list', 'Navigator panel', -values => $iconsizes],
			-toolpaneliconsize => ['list', 'Tool panel', -values => $iconsizes],
			'*end',
			'*section' => 'Visibility at lauch',
			-toolbarvisible => ['boolean', 'Tool bar'],
			-statusbarvisible => ['boolean', 'Status bar'],
			-navigatorpanelvisible => ['boolean', 'Navigation panel'],
			-toolpanelvisible => ['boolean', 'Tool panel'],
			'*end',
			'*section' => 'Tool bar',
			-tooltextposition => ['radio', 'Text position', -values => [qw[none left right top bottom]]],
			'*end',
		],
	);
	for (keys %opts) {
		$args->{$_} = $opts{$_}
	}
	$self->SUPER::Populate($args);

	$self->addPostConfig('SetThemeFile', $self);
	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
}

sub GetThemeFile {
	my $self = shift;
	return $self->extGet('ConfigFolder')->ConfigFolder .'/highlight_theme.ctt';
}

sub SetThemeFile {
	my $self = shift;
	my $themefile = $self->GetThemeFile;
	$self->SetDefaultTheme unless -e $themefile;
	$self->configPut(-highlight_themefile => $themefile);
}

sub SetDefaultTheme {
	my $self = shift;
	my $themefile = $self->GetThemeFile;
	my $default = Tk::findINC('App/Codit/highlight_theme.ctt');
	my $theme = Tk::CodeText::Theme->new;
	$theme->load($default);
	$theme->save($themefile);
}

1;



