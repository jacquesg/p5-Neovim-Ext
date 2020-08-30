package Neovim::Ext::Plugin::ScriptHost;

use strict;
use warnings;
use List::Util qw/min/;
use base 'Neovim::Ext::Plugin';
use Neovim::Ext::ErrorResponse;
use Neovim::Ext::VIMCompat::Buffer;
use Neovim::Ext::VIMCompat::Window;

__PACKAGE__->mk_accessors (qw/current/);
__PACKAGE__->register;

BEGIN
{
	eval "package VIM;\n use Neovim::Ext::VIMCompat;\n;1;\n";
};

our $VIM;


sub new
{
	my ($this, $nvim, $host) = @_;

	$VIM = $nvim;

	return $this->SUPER::new ($nvim, $host);
}

sub perl_execute :nvim_rpc_export('perl_execute', sync => 1)
{
	my ($this, $script, $range_start, $range_stop) = @_;

	$this->_eval ($range_start, $range_stop, $script);
	if ($@)
	{
		die Neovim::Ext::ErrorResponse->new ($@);
	}
}

sub perl_execute_file :nvim_rpc_export('perl_execute_file', sync => 1)
{
	my ($this, $file_path, $range_start, $range_stop) = @_;

	my $script;
	{
		open my $fh, '<', $file_path or
			die Neovim::Ext::ErrorResponse->new ("Could not open '$file_path': $!");
		local $/ = undef;
		$script = <$fh>;
		close $fh;
	}

	$this->perl_execute ($script, $range_start, $range_stop);
}

sub perl_do_range :nvim_rpc_export('perl_do_range', sync => 1)
{
	my ($this, $start, $stop, $code) = @_;

	$start -= 1;

	while ($start < $stop)
	{
		my $sstart = $start;
		my $sstop = min ($start + 5000, $stop);
		my $lines = tied (@{$this->nvim->current->buffer})->api->get_lines ($sstart, $sstop, 1);

		my @newlines;
		my $linenr = $sstart + 1;
		foreach my $line (@$lines)
		{
			my $result = $this->_eval ($start, $stop, $code, $line, $linenr);
			push @newlines, $result;
			++$linenr;
		}

		$start = $sstop;

		tied (@{$this->nvim->current->buffer})->api->set_lines ($sstart, $sstop, 1, \@newlines);
	}
}

sub perl_eval :nvim_rpc_export('perl_eval', sync => 1)
{
	my ($this, $expr) = @_;

	# Bringe $current, $vim and $nvim into lexical scope
	my ($vim, $nvim) = ($this->nvim, $this->nvim);

	return eval $expr;
}

sub perl_chdir :nvim_rpc_export('perl_chdir', sync => 0)
{
	my ($this, $cwd) = @_;
	chdir ($cwd);
}

sub _eval
{
	my ($this, $start, $stop, $code, $line, $linenr) = @_;

	# Bringe $vim and $nvim into lexical scope
	my $current = $this->nvim->current;
	my ($vim, $nvim) = ($this->nvim, $this->nvim);

	$current->range (tied (@{$current->buffer})->range ($start, $stop));

	my $curbuf = Neovim::Ext::VIMCompat::Buffer->new ($current->buffer);
	my $curwin = Neovim::Ext::VIMCompat::Window->new ($current->window);

	$main::curbuf = $curbuf;
	$main::curwin = $curwin;

	local $_ = $line if ($line);

	my $script =
		"package main;\n".
		"no strict;\n".
		"no warnings;\n";

	if (defined ($line) && defined ($linenr))
	{
		$script .=
			"my \$line = \"$line\";\n".
			"my \$linenr = $linenr;\n".
			"\$_ = \$line;\n";
	}

	$script .=
		"$code;\n".
		"1;\n";

	eval $script;
	return $_;
}

=head1 NAME

Neovim::Ext::Plugin::ScriptHost - Neovim Legacy perl Plugin

=head1 SYNOPSIS

	use Neovim::Ext;

=head1 METHODS

=head2 perl_execute( $script, $range_start, $range_stop )

=head2 perl_execute_file( $file_path, $range_start, $range_stop )

=head2 perl_do_range( $start, $stop, $code )

=head2 perl_eval( $expr )

=head2 perl_chdir( $cwd )

=cut

1;

