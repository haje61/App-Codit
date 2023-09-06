package App::Codit::CoditText;

=head1 NAME

App::Codit - IDE for and in Perl

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.01";

use base qw(Tk::Derived Tk::CodeText);
Construct Tk::Widget 'CoditText';

sub Populate {
	my ($self,$args) = @_;
	
	$self->SUPER::Populate($args);

	my $xt = $self->Subwidget('XText');
	$xt->bind('<FocusIn>', [$self, 'OnFocusIn']);
	$xt->bind('<FocusOut>', [$self, 'OnFocusOut']);

	$self->ConfigSpecs(
		-position => ['METHOD'],
		DEFAULT => [$xt],
	);
}

sub OnFocusIn {
	my $self = shift;
# 	print "focus in $self\n";
	my $flag = $self->{'nohl_save'};
	$self->NoHighlighting($flag) if defined $flag;
	$self->highlightLoop;
# 	my $is = $self->{'interval_save'};
# 	if (defined $is) {
# 		$self->configure(-statusinterval => $is);
# 		delete $self->{'interval_save'};
# 	}
}

sub OnFocusOut {
	my $self = shift;
# 	print "focus out $self\n";
	$self->{'nohl_save'} = $self->NoHighlighting;
	$self->NoHighlighting(1);
# 	$self->{'interval_save'} = $self->cget('-statusinterval');
# 	$self->configure(-statusinterval => 100000)
}

sub position {
	my ($self, $pos) = @_;
	if (defined $pos) {
		$self->goTo($pos);
		$self->see($pos);
	}
	return $self->index('insert');
}

sub themeUpdate {
	my $self = shift;
	$self->SUPER::themeUpdate(@_);
	$self->highlightPurge(1);
}

1;
