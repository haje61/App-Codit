package App::Codit::Plugins::FileBrowser;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 DESCRIPTION

Browse your file system.

Not yet implemented

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'Navigator');
	return undef unless defined $self;
	
	return $self;
}




1;

