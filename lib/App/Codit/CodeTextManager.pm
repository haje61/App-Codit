package App::Codit::CodeTextManager;

=head1 NAME

App::Codit - IDE for and in Perl

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;
require App::Codit::CoditText;

use base qw(Tk::Derived Tk::AppWindow::BaseClasses::ContentManager);
Construct Tk::Widget 'CodeTextManager';

sub Populate {
	my ($self,$args) = @_;
	
	$self->SUPER::Populate($args);
	my $text = $self->CoditText(
		-scrollbars => 'ose',
	)->pack(-expand => 1, -fill => 'both');
	$self->CWidg($text);

	$self->ConfigSpecs(
		-contentbackground => [{-background => $text->Subwidget('XText')}],
		-contentforeground => [{-foreground => $text->Subwidget('XText')}],
		-contentfont => [{-font => $text->Subwidget('XText')}],
		-contentindent => [{-indentstyle => $text->Subwidget('XText')}],
		-contenttabs => [{-tabs => $text->Subwidget('XText')}],
		-contentwrap => [{-wrap => $text->Subwidget('XText')}],
		-showfolds => [$text],
		-shownumbers => [$text],
		-showstatus => [$text],
		-highlight_themefile => [{ -themefile => $text}],
		DEFAULT => [$text],
	);
	$self->Delegates(
		DEFAULT => [$text],
	);
}

sub ConfigureCM {
	my $self = shift;
	my $ext = $self->Extension;
	my $cmopt = $ext->configGet('-contentmanageroptions');
	
	my @o = @$cmopt; #Hack preventing from the original being modified. No idea why this is needed.
	for (@o) {
		my $key = $_;
# 		print "option $key\n";
		my $val = $ext->configGet($key);
		if ((defined $val) and ($val ne '')) {
# 			print "configuring $key with value $val\n";
			$self->configure($key, $val) ;
		}
	}
}


sub doClear {
	my $self = shift;
	my $t = $self->CWidg;
	$t->clear
# 	$t->editReset;
}

sub doLoad {
	my ($self, $file) = @_;
	my $t = $self->CWidg;
	$t->load($file);
# 	$t->editModified(0);
	return 1
}

sub doSave {
	my ($self, $file) = @_;
	my $t = $self->CWidg;
	$t->save($file);
# 	$t->editModified(0);
	return 1
}

sub Focus {
	my $self = shift;
	$self->CWidg->focus;
}

sub IsModified {
	my $self = shift;
	return $self->CWidg->editModified;	
}

1;
