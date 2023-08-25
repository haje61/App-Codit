package App::Codit::CoditTagsEditor;

=head1 NAME

App::Codit - IDE for and in Perl

=cut

use strict;
use warnings;
use Carp;
use vars qw($VERSION);
$VERSION="0.01";
use Tk;
use Tie::Watch;

use base qw(Tk::Derived Tk::CodeText::TagsEditor);
Construct Tk::Widget 'CoditTagsEditor';

sub Populate {
	my ($self,$args) = @_;
	
	my $themefile = delete $args->{'-themefile'};
	die 'You must specify the -themefile option' unless defined $themefile;
	
	$self->SUPER::Populate($args);
	$self->ConfigSpecs(
		DEFAULT => ['SELF'],
	);
	$self->after(2000, sub { 
		my $theme = Tk::CodeText::Theme->new;
		$theme->load($themefile);
		$self->put($theme->get) 
	});
}

1;
