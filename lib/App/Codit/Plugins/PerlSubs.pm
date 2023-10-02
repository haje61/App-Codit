package App::Codit::Plugins::PerlSubs;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 DESCRIPTION

Easily find the subs in your document.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'NavigatorPanel');
	return undef unless defined $self;
	
	my $tp = $self->extGet('NavigatorPanel');
	my $page = $tp->addPage('PerlSubs', 'code-context', 'Find your subs');
	
	my $autorefresh = 1;
	$self->{AUTOREFRESH} = \$autorefresh;
	my $interval = 3;
	$self->{INTERVAL} = \$interval;
	my @list = ();
	$self->{LIST} = \@list;
	$self->{POSITIONS} = {};
	$self->{REFRESHID} = undef;
	
	my @padding = (-padx => 2, -pady => 2);
	my $cframe = $page->Frame(
		-relief => 'groove',
		-borderwidth => 2,
	)->pack(-fill => 'x');
	$cframe->Checkbutton(
		-variable => \$autorefresh,
		-text => 'Auto refresh',
		-command => ['AutoEnable', $self],
	)->pack(-anchor => 'w', @padding);
	my $bframe = $cframe->Frame->pack(-fill => 'x');
	$bframe->Label(
		-text => 'Interval',
	)->pack(-side => 'left', @padding);
	my $spin = $bframe->Spinbox(
		-textvariable => \$interval,
		-from => 1,
		-to => 60,
		-width => 3,
	)->pack(-side => 'left', @padding);
	$self->{SPIN} = $spin;
	$bframe->Label(
		-text => 'sec',
	)->pack(-side => 'left', @padding);
	$cframe->Button(
		-text => 'Refresh',
		-command => ['Refresh', $self],
	)->pack(@padding, -fill => 'x');
	my $listbox = $page->Scrolled('Listbox',
		-listvariable => \@list,
		-scrollbars => 'osoe',
	)->pack(@padding, -expand => 1, -fill => 'both');
	$self->{LISTBOX} = $listbox;
	$listbox->bind('<ButtonRelease-1>', [$self, 'Select']);

	$self->Refresh;
	return $self;
}

sub AutoEnable {
	my ($self, $flag) = @_;
	if ($self->AutoRefresh) {
		$self->{SPIN}->configure(-state => 'normal');
		$self->Refresh;
	} else {
		$self->{SPIN}->configure(-state => 'disabled');
		my $id = $self->{REFRESHID};
		$self->afterCancel($id) if defined $id;
	}
}

sub AutoRefresh {
	my $self = shift;
	my $var = $self->{AUTOREFRESH};
	$$var = shift if @_;
	return $$var
}

sub GetDocument {
	my $self = shift;
	my $mdi = $self->extGet('CoditMDI');
	my $sel = $mdi->docSelected;
	return undef unless defined $sel;
	return $mdi->docGet($sel)->CWidg;
}

sub Refresh {
	my $self = shift;
	my $doc = $self->GetDocument;
	my $listbox = $self->{LISTBOX};
	if (defined $doc) {
		my $end = $doc->index('end - 1c');
		my $numlines = $end;
		$numlines =~ s/\.\d+$//;
		my $list = $self->{LIST};
		my $current;
		if (defined $listbox->curselection) {
			my ($sel) = $listbox->curselection;
			$current = $listbox->get($sel);
			$current =~ s/\s\(\d+\)$//;
		}
		my $lastvisible = $listbox->index('@2,' . $listbox->height) - 1;
		while (@$list) { pop @$list }
		$self->{DATA} = {};
		my $count = 0;
		for (1 .. $numlines) {
			my $num = $_;
			my $line = $doc->get("$num.0", "$num.0 lineend");
			if ($line =~ /^\s*sub\s+([^\s|^\{]+)/) {
				my $name = $1;
			}
		}
		#first remove deleted subs
		for (1 .. $numlines) {
			my $num = $_;
			my $line = $doc->get("$num.0", "$num.0 lineend");
			if ($line =~ /^\s*sub\s+([^\s|^\{]+)/) {
				my $name = $1;
				if ($count >= @$list) {
					push @$list, "$name ($num)";
				} elsif (! $list->[$count] =~ /^$name/) {
					splice @$list, $count - 1, 0, "$name ($num)"; 
				} else {
					$list->[$count] = "$name ($num)";
				}
				$self->{DATA}->{$name} = $num;
				$count ++
			}
		}
		my $listsize = @$list;
		#find and set selection
		if (defined $current) {
			for (0 .. $listsize - 1) {
				my $count = $_;
				my $label = $listbox->get($count);
				my $reg = "^$current";
				if ($label =~ /$reg/) {
					$listbox->selectionSet($count);
					last
				}
			}
		}
		$listbox->see($lastvisible);
	}

	if ($self->AutoRefresh) {
		my $interval = $self->{INTERVAL};
		$self->{REFRESHID} = $self->after($$interval * 1000, ['Refresh', $self]);
	}
}

sub Select {
	my $self = shift;
	my $listbox = $self->{LISTBOX};
	my $doc = $self->GetDocument;
	if (defined $doc) {
		my $item = $listbox->get($listbox->curselection);
		$item =~ /\((\d+)\)/;
		my $line = $1;
		my $index = "$line.0";
		$doc->goTo($index);
# 		$doc->see($index);
	}
}

sub Unload {
	my $self = shift;
	$self->extGet('NavigatorPanel')->deletePage('PerlSubs');
	my $id = $self->{REFRESHID};
	$self->afterCancel($id) if defined $id;
	return 1
}


1;




