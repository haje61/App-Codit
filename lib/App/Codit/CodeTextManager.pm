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
#require App::Codit::CoditText;
require Tk::CodeText;

use base qw(Tk::Derived Tk::AppWindow::BaseClasses::ContentManager);
Construct Tk::Widget 'CodeTextManager';

sub Populate {
	my ($self,$args) = @_;
	
	$self->SUPER::Populate($args);
	my $text = $self->CodeText(
		-scrollbars => 'ose',
	)->pack(-expand => 1, -fill => 'both');
	$self->CWidg($text);
	my $xt = $text->Subwidget('XText');

	$self->ConfigSpecs(
		-contentautoindent => [{-autoindent => $xt}],
		-contentbackground => [{-background => $xt}],
		-contentforeground => [{-foreground => $xt}],
		-contentfont => [{-font => $xt}],
		-contentindent => [{-indentstyle => $xt}],
		-contentposition => [{-position => $text}],
		-contentsyntax => [{-syntax => $text}],
		-contenttabs => [{-tabs => $xt}],
		-contentwrap => [{-wrap => $xt}],
		-showfolds => [$text],
		-shownumbers => [$text],
		-showstatus => [$text],
		-highlight_themefile => [{ -themefile => $text}],
		DEFAULT => [$text],
	);
	$self->Delegates(
		DEFAULT => $text,
	);
}

# sub ConfigureCM {
# 	my $self = shift;
# 	my $ext = $self->Extension;
# 	my $cmopt = $ext->configGet('-contentmanageroptions');
# 	
# 	my @o = @$cmopt; #Hack preventing from the original being modified. No idea why this is needed.
# 	for (@o) {
# 		my $key = $_;
# # 		print "option $key\n";
# 		my $val = $ext->configGet($key);
# 		if ((defined $val) and ($val ne '')) {
# # 			print "configuring $key with value $val\n";
# 			$self->configure($key, $val) ;
# 		}
# 	}
# }


sub doClear {
	$_[0]->CWidg->clear
}

sub doLoad {
	my ($self, $file) = @_;
	return $self->CWidg->load($file);
}

sub doSave {
	my ($self, $file) = @_;
	return $self->CWidg->save($file);
}

sub doSelect {
	$_[0]->CWidg->focus
}


sub IsModified {
	return $_[0]->CWidg->Subwidget('XText')->editModified;	
}

1;


