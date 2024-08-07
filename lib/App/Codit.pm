package App::Codit;

=head1 NAME

App::Codit - IDE for and in Perl

=head1 DESCRIPTION

Codit is a versatile text editor / integrated development environment aimed at the Perl programming language.

It is written in Perl/Tk and based on the L<Tk::AppWindow> application framework.

It uses the L<Tk::CodeText> text widget for editing.

Codit has been under development for about one year now. And even though it is considered
alpha software, it already has gone quite some miles on our systems.

It features a multi document interface that can hold an unlimited number of documents,
navigable through the tab bar at the top and a document list in the left side panel. 

It has a plugin system designed to invite users to write their own plugins.

It is fully configurable through a configuration window, allowing you to set defaults
for editing, the graphical user interface, syntax highlighting and (un)loading plugins.

L<Tk::CodeText> offers syntax highlighting and code folding in plenty formats and languages.
It has and advanced word based undo/redo stack that keeps track of selections and save points.
It does auto indent, comment, uncomment, indent and unindent. Tab size and indent style are
fully user configurable.

=head1 RUNNING CODIT

You can launch Codit from the command line as follows:

 codit [options] [files]

The following command line options are available:

=over 4

=item I<-c> or I<-config>

Specifies the configfolder to use. If the path does not exist it will be created.

=item I<-h> or I<-help>

Displays a help message on the command line and exits.

=item I<-i> or I<-iconpath>

Point to the folders where your icon libraries are located.*

=item I<-t> or I<-icontheme>

Icon theme to load.

=item I<-P> or I<-noplugins>

Launch without any plugins loaded. This supersedes the -plugins option.

=item I<-p> or I<-plugins>

Launch with only these plugins .*

=item I<-s> or I<-session>

Loads a session at launch. The plugin Sessions must be loaded for this to work.

=item I<-y> or I<-syntax>

Specify the default syntax to use for syntax highlighting. Codit will determine the syntax 
of documents by their extension. This options comes in handy when the file you are 
loading does not have an extension.

=item I<-v> or I<-version>

Displays the version number on the command line and exits.

=back

* You can specify a list of items by separating them with a ':'.

=head1 TROUBLESHOOTING

Just hoping you never need this.

=head2 General troubleshooting

If you encounter problems and error messages using Codit here are some general troubleshooting steps:

=over 4

=item Use the -config command line option to point to a new, preferably fresh settingsfolder.

=item Use the -noplugins command line option to launch Codit without any plugins loaded.

=item Use the -plugins command line option to launch Codit with only the plugins loaded you specify here.

=back

=head2 No icons

If Codit launches without any icons do one or more of the following:

=over 4

=item Check if your icon theme is based on scalable vectors. Install Icons::LibRSVG if so. See also the Readme.md that comes with this distribution.

=item Locate where your icons are located on your system and use the -iconpath command line option to point there.

=item Select an icon library by using the -icontheme command line option.

=back

=head2 Session will not load

Sometimes it happens that a session file gets corrupted. You solve it like this:

=over 4

=item Launch the session manager. Menu->Session->Manage sessions.

=item Remove the affected session.

=item Rebuild it from scratch.

=back

Sorry, that is all we have to offer.

=head3 Report a bug

If all fails you are welcome to open a ticket here: L<https://github.com/haje61/App-Codit/issues>.

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.09";
use Tk;
require App::Codit::CodeTextManager;

use base qw(Tk::Derived Tk::AppWindow);
Construct Tk::Widget 'Codit';

sub Populate {
	my ($self,$args) = @_;

	$self->geometry('800x600+150+150');

	my $rawdir = Tk::findINC('App/Codit/Icons');
	my %opts = (
#		-appname => 'Codit',
		-logo => Tk::findINC('App/Codit/codit_logo.png'),
		-extensions => [qw[Art CoditMDI ToolBar StatusBar MenuBar Navigator ToolPanel Help Settings Plugins]],
		-documentinterface => 'CoditMDI',
		-namespace => 'App::Codit',
		-rawiconpath => [ $rawdir ],
		-savegeometry => 1,
		-updatesmenuitem => 1,

		-aboutinfo => {
#			version => $VERSION,
			author => 'Hans Jeuken',
			components => [
				'FreeDesktop::Icons',
				'Imager',
				'Syntax::Kamelon', 
				'Tk', 
				'Tk::AppWindow', 
				'Tk::CodeText',
				'Tk::ColorEntry',
				'Tk::DocumentTree',
				'Tk::FileBrowser',
				'Tk::QuickForm',
				'Tk::Terminal',
				'Tk::YADialog',
				'Tk::YANoteBook',
			],
			http => 'https://github.com/haje61/App-Codit',
#			license => 'Same as Perl',
		},
		-helpfile => 'https://www.perlgui.org/wp-content/uploads/2024/07/codit_manual.pdf',

		-contentmanagerclass => 'CodeTextManager',
		-contentmanageroptions => [
			'-contentautoindent', 
			'-contentbackground',
			'-contentbgdspace',
			'-contentbgdtab',
			'-contentfont', 
			'-contentforeground', 
			'-contentindent', 
			'-contentinsertbg', 
			'-contentmatchbg', 
			'-contentmatchfg', 
			'-contentsyntax', 
			'-contenttabs', 
			'-contentwrap',
#			'-contentxml',
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

		-useroptions => [
			'*page' => 'Editing',
			'*section' => 'Editor settings',
			-contentfont => ['font', 'Font'],
			-contentautoindent => ['boolean', 'Auto indent'],
#			-contentindent => ['text', 'Indent style', -width => 4],
			-contentindent => ['text', 'Indent style', -regex => qr/^\d+|tab$/, -width => 4],
#			'*column',
#			-contenttabs => ['text', 'Tab size', -width => 4],
			-contenttabs => ['text', 'Tab size', -regex => qr/^\d+\.?\d*[c|i|m|p]$/, -width => 4],
			-contentwrap => ['radio', 'Wrap', -values => [qw[none char word]]],
			-doc_show_spaces => ['boolean', 'Show spaces'],
			'*end',
			'*section' => 'Show indicators',
			-showfolds => ['boolean', 'Fold indicators'],
			-shownumbers => ['boolean', 'Line numbers'],
			-showstatus => ['boolean', 'Doc status'],
			'*end',

			'*page' => 'Colors',
			'*section' => 'Editing',
			-contentforeground => ['color', 'Foreground', -width => 8],
			-contentbackground => ['color', 'Background', -width => 8],
			-contentinsertbg => ['color', 'Insert bg', -width => 8],
			'*end',
			'*section' => 'Spaces and tabs',
			-contentbgdspace => ['color', 'Space bg', -width => 8],
			-contentbgdtab => ['color', 'Tab bg', -width => 8],
			'*end',
			'*section' => 'Matching {}, [] and ()',
			-contentmatchfg => ['color', 'Foreground', -width => 8],
			-contentmatchbg => ['color', 'Background', -width => 8],
			'*end',

			'*page' => 'GUI',
			'*section' => 'Icon sizes',
			-iconsize => ['spin', 'General', -width => 4],
			-sidebariconsize => ['spin', 'Side bars', -width => 4],
			'*column',
			-menuiconsize => ['spin', 'Menu bar', -width => 4],
			-tooliconsize => ['spin', 'Tool bar', -width => 4],
			'*end',
			'*section' => 'Visibility at lauch',
			'-tool barvisible' => ['boolean', 'Tool bar'],
			'-status barvisible' => ['boolean', 'Status bar'],
			'*column',
			'-navigator panelvisible' => ['boolean', 'Navigator panel'],
			'-tool panelvisible' => ['boolean', 'Tool panel'],
			'*end',
			'*section' => 'Geometry',
			-savegeometry => ['boolean', 'Save on exit',],
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

	$self->addPostConfig('DoPostConfig', $self);
	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
}

sub DoPostConfig {
	my $self = shift;
	$self->SetThemeFile;
	$self->cmdExecute('doc_new');
#	$self->mdi->createContextMenu;
}

sub GetThemeFile {
	return $_[0]->extGet('ConfigFolder')->ConfigFolder .'/highlight_theme.ctt';
}

sub mdi {
	return $_[0]->extGet('CoditMDI');
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


















