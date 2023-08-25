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
	$self->ConfigSpecs(
		DEFAULT => [$self->Subwidget('XText')],
	);
}

sub themefile {
	my ($self, $file) = @_;
	print "themefile $file\n" if defined $file;
	return $self->SUPER::themefile($file) if defined $file;
	return $self->SUPER::themefile;
}

# sub themeUpdate {
# 	my $self = shift;
# 	print "themeUpdate\n";
# 	$self->SUPER::themeUpdate(@_);
# 	$self->highlightPurge(1);
# }

1;
