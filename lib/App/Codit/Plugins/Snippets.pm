package App::Codit::Plugins::Snippets;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 DESCRIPTION

Quick and easy code samples.

Not yet implemented

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'ToolPanel');
	return undef unless defined $self;
	
	return $self;
}




1;

