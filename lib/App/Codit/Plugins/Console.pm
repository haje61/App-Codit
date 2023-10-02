package Tk::AppWindow::Plugins::Console;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 DESCRIPTION

Test your code and run system commands

Not yet implemented

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'ToolPanel');
	return undef unless defined $self;
	
	return $self;
}




1;


