package App::Codit::Plugins::WordCompletion;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 DESCRIPTION

Make your life easy with word completion.

Not yet implemented

=cut

my @deliminators = (
	'.',	'(', ')',	':',	'!',	'+',	',',	'-',	'<',	'=',	'>',	'%',	'&',	'*', '"', '\'',
	'/',	';',	'?',	'[',	']',	'^',	'{',	'|',	'}',	'~',	'\\', '$', '@', '#', '`'
);
my $reg = '';
for (@deliminators) {
	$reg = $reg . quotemeta($_) . '|';
}
$reg = $reg . '\s';
$reg = qr/$reg/;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_,);
	return undef unless defined $self;
	$self->{INTERVAL} = 20;
	$self->{WORDDATA} = {};
	$self->{LINEDATA} = {};
	$self->{CURDOC} = '';
	
	$self->Cycle;
	return $self;
}

sub Cycle {
	my $self = shift;
	my $mdi = $self->extGet('CoditMDI');
	my $name = $mdi->docSelected;
	if (defined $name) {
		my $widg = $mdi->docGet($name)->CWidg;
		my $data = $self->{WORDDATA}->{$name};
		$data = {} unless defined $data;
		my $line = $self->{LINEDATA}->{$name};
		$line = 1 unless defined $line;

#		if ($line eq 1) {
#			use Data::Dumper;
#			print Dumper $data;
#		}
		my $content = $widg->get("$line.0", "$line.0 lineend");
		while ($content ne '') {
			if ($content =~ /^([^$reg]+)/) {
				my $word = $1;
				$content = substr($content, length($word));
				if (length($word) > 3) {
					$data->{$word} = 1;
				}
			} else {
				$content =~ s/^.//;
			}
		}
		my $lastline = $widg->linenumber('end - 1c');
		$line ++;
		$line = 1 if $line > $lastline;
		$self->{WORDDATA}->{$name} = $data;
		$self->{LINEDATA}->{$name} = $line
	}
	$self->CycleResume;
}

sub CyclePause {
	my $self = shift;
	$self->afterCancel($self->{AFTERID});
}

sub CycleResume {
	my $self = shift;
	$self->{AFTERID} = $self->after($self->Interval, ['Cycle', $self]);
}

sub Interval {
	my $self = shift;
	$self->{INTERVAL} = shift if @_;
	return $self->{INTERVAL}
}

sub Unload {
	my $self = shift;
	$self->CyclePause;
}


1;





