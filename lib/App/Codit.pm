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
		-extensions => [qw[Art Balloon CoditMDI ToolBar StatusBar MenuBar Navigator Help Settings Plugins]],
		-documentinterface => 'CoditMDI',

		-contentmanagerclass => 'CodeTextManager',
		-contentmanageroptions => [
			'-contentbackground', 
			'-contentfont', 
			'-contentforeground', 
			'-contentindent', 
			'-contenttabs', 
			'-contentwrap',
			'-showfolds',
			'-shownumbers',
			'-showstatus',
			'-themefile',
		],

		-contentindent => 'tab',
		-contenttabs => '8m',
		-contentwrap => 'none',
		-showfolds => 1,
		-shownumbers => 1,
		-showstatus => 1,


		-mainmenuitems => [
#This table is best viewed with tabsize 3.
	#			 type					menupath			label						cmd						icon					keyb			config variable
			[	'menu', 				'View',			"~Edit" 	], 
			[	'menu_normal',		'Edit::',		"~Copy",					'<Control-c>',			'edit-copy',		'*CTRL+C'			], 
			[	'menu_normal',		'Edit::',		"C~ut",					'<Control-x>',			'edit-cut',			'*CTRL+X'			], 
			[	'menu_normal',		'Edit::',		"~Paste",				'<Control-v>',			'edit-paste',		'*CTRL+V'			], 
			[	'menu_separator',	'Edit::', 		'e1' ], 
			[	'menu_normal',		'Edit::',		"U~ndo",					'<Control-z>',			'edit-undo',		'*CTRL+Z'			], 
			[	'menu_normal',		'Edit::',		"~Redo",					'<Control-Z>',			'edit-redo',		'*CTRL+SHIFT+Z'	], 
			[	'menu_separator',	'Edit::', 		'e2' ], 
			[	'menu_normal',		'Edit::',		"Co~mment",				'<Control-g>',			undef,				'*CTRL+G'	], 
			[	'menu_normal',		'Edit::',		"~Uncomment",			'<Control-G>',			undef,				'*CTRL+SHIFT+G'	], 
			[	'menu_separator',	'Edit::', 		'e3' ], 
			[	'menu_normal',		'Edit::',		"~Indent",				'<Control-j>',			undef,				'*CTRL+J'	], 
			[	'menu_normal',		'Edit::',		"Unin~dent",			'<Control-J>',			undef,				'*CTRL+SHIFT+J'	], 
			[	'menu_separator',	'Edit::', 		'e4' ], 
			[	'menu_normal',		'Edit::',		"~Select all",			'<Control-a>',			'edit-select-all','*CTRL+A'			], 
		],
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
			-contenttabs => ['text', 'Tab size'],
			-contentwrap => ['radio', 'Wrap', -values => [qw[none char word]]],
			'*end',
			'*section' => 'Indicators',
			-showfolds => ['boolean', 'Show fold indicators'],
			-shownumbers => ['boolean', 'Show line numbers'],
			-showstatus => ['boolean', 'Show document status'],
			'*end',

			'*page' => 'GUI',
			'*section' => 'Menubar',
			-menuiconsize => ['list', 'Icon size', -values => $iconsizes],
			'*end',
			'*section' => 'Toolbar',
			-toolbarvisible => ['boolean', 'Visible at launch'],
			-tooliconsize => ['list', 'Icon size', -values => $iconsizes],
			-tooltextposition => ['radio', 'Text position', -values => [qw[none left right top bottom]]],
			'*end',
			'*section' => 'Statusbar',
			-statusbarvisible => ['boolean', 'Visible at launch'],
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

sub SetThemeFile {
	my $self = shift;
	my $name = 'highlight_theme.ctt';
	my $themefile = $self->extGet('ConfigFolder')->ConfigFolder ."/$name";
	print "themefile $themefile\n";
	unless (-e $themefile) {
		my $default = Tk::findINC("App/Codit/$name");
		print "default $default\n";
		my $theme = Tk::CodeText::Theme->new;
		$theme->load($default);
		$theme->save($themefile);
	}
	$self->configPut(-themefile => $themefile);
}

1;
