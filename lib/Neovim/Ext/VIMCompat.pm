package Neovim::Ext::VIMCompat;

use strict;
use warnings;
use Exporter 'import';
use Neovim::Ext::VIMCompat::Buffer;
use Neovim::Ext::VIMCompat::Window;

our @EXPORT = qw/
	Msg
	SetOption
	DoCommand
	Eval
	Buffers
	Windows
/;


sub Msg
{
	my ($msg) = @_;

	# TODO: Support $group
	my $vim = $Neovim::Ext::Plugin::ScriptHost::VIM;

	$msg .= "\n" if ((substr $msg, -1) ne "\n");
	$vim->err_write ($msg);
}



sub SetOption
{
	my ($option) = @_;

	my $vim = $Neovim::Ext::Plugin::ScriptHost::VIM;
	$vim->command ("set $option");
}



sub DoCommand
{
	my ($cmd) = @_;

	my $vim = $Neovim::Ext::Plugin::ScriptHost::VIM;
	$vim->command ($cmd);
}



sub Eval
{
	my (@expr) = @_;

	my $vim = $Neovim::Ext::Plugin::ScriptHost::VIM;

	my $result;
	eval
	{
		$result = $vim->eval (join ("\n", @expr));
	};

	if ($@)
	{
		if (wantarray)
		{
			return (0, undef);
		}

		return undef;
	}

	if (wantarray)
	{
		return (1, $result);
	}

	return $result;
}



sub Buffers
{
	my (@names) = @_;

	my $vim = $Neovim::Ext::Plugin::ScriptHost::VIM;

	my @buffers;
	if (scalar (@names) == 0)
	{
		@buffers = @{$vim->buffers};
	}
	else
	{
		my @all = @{$vim->buffers};
		foreach my $name (@names)
		{
			my $real = $vim->eval ('bufname ("'.$name.'")');
			my ($buffer) = grep { tied (@{$_})->name eq $real } @all;
			if ($buffer)
			{
				push @buffers, $buffer;
			}
		}
	}

	if (wantarray)
	{
		return map { Neovim::Ext::VIMCompat::Buffer->new ($_) } @buffers;
	}

	return scalar (@buffers);
}



sub Windows
{
	my (@numbers) = @_;

	my $vim = $Neovim::Ext::Plugin::ScriptHost::VIM;

	my @windows;
	if (scalar (@numbers) == 0)
	{
		@windows = @{$vim->windows};
	}
	else
	{
		my @all = @{$vim->windows};
		foreach my $number (@numbers)
		{
			my ($window) = grep { $_->number == $number } @all;
			if ($window)
			{
				push @windows, $window;
			}
		}
	}

	if (wantarray)
	{
		return map { Neovim::Ext::VIMCompat::Window->new ($_) } @windows;
	}

	return scalar (@windows);
}

=head1 NAME

Neovim::Ext::VIMCompat - Neovim legacy VIM perl compatibility layer

=head1 SYNPOSIS

	use Neovim::Ext;

=head1 DESCRIPTION

A compatibility layer for the legacy VIM perl interface.

=head1 METHODS

=head2 Msg( $msg )

Display the message C<$msg>.

=head2 SetOption( $option )

Sets a vim option. C<$option> can be any argument that the C<:set> command
accepts. No spaces are allowed in C<$option>.

=head2 DoCommand( $cmd )

Execute the Ex command C<$cmd>.

=head2 Eval( @expr )

Evaluate C<@expr> and returns C<($success, $result)> in list context or just
C<$result> in scalar context.

=head2 Buffers( [@names] )

Return a list of buffers in list context or the number of buffers in scalar
context. C<@names> may optionally specify the list of buffers of interest.
Neovim's C<bufname()> function is executed on each entry in C<@names> prior
to comparing the buffer names.

=head2 Windows( [@numbers] )

Returns a list of windows in list context or the number of windows in scalar
context. C<@numbers> may optionally specify the list of windows of interest.

=cut

1;
