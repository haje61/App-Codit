package App::Codit::Plugins::Bookmarks;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 DESCRIPTION

What's an editor without bookmarks?.

Not yet implemented

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	return undef unless defined $self;
	
	return $self;
}




1;

