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

#sub Populate {
#	my ($self,$args) = @_;
#	
#	$self->SUPER::Populate($args);
#	my $xt = $self->Subwidget('XText');
#
#	$self->ConfigSpecs(
#		DEFAULT => [$xt],
#	);
#	$self->Delegates(
#		DEFAULT => $xt,
#	);
#}

sub export {
	my ($self, $file) = @_;

	unless (open OUTFILE, '>', $file) { 
		warn "cannot open $file";
		return 0
	};
	my $index = '1.0';
	while ($self->compare($index,'<','end')) {
		my $end = $self->index("$index lineend + 1c");
		my $line = $self->get($index,$end);
		print OUTFILE $line;
		$index = $end;
	}
	close OUTFILE;
	return 1
}

sub save {
	my ($self, $file) = @_;
	if ($self->export($file)) {
		$self->clearModified;
		$self->log("Saved $file");
		return 1
	}
	return 0
}
1;


