package Neovim::Ext::Plugin::ScriptHost;

use strict;
use warnings;
use List::Util qw/min/;
use base 'Neovim::Ext::Plugin';
use Neovim::Ext::ErrorResponse;

__PACKAGE__->mk_accessors (qw/current/);
__PACKAGE__->register;


sub perl_execute :nvim_rpc_export('perl_execute', sync => 1)
{
	my ($this, $script, $range_start, $range_stop) = @_;

	# Bringe $current, $vim and $nvim into lexical scope
	my $current = $this->_get_range ($range_start, $range_stop);
	my ($vim, $nvim) = ($this->nvim, $this->nvim);

	eval "package main;\n$script;1\n";
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

	my $sub = sub
	{
		my ($linenr, $line) = @_;
		local $_ = $line;
		eval "package main;\n$code;1\n";
		return $_;
	};

	# Bringe $vim and $nvim into lexical scope
	my $current = $this->_get_range ($start, $stop);
	my ($vim, $nvim) = ($this->nvim, $this->nvim);

	$start -= 1;

	while ($start < $stop)
	{
		my $sstart = $start;
		my $sstop = min ($start + 5000, $stop);
		my $lines = tied (@{$vim->current->buffer})->api->get_lines ($sstart, $sstop, 1);

		my @newlines;
		my $linenr = $sstart + 1;
		foreach my $line (@$lines)
		{
			my $result = $sub->($linenr, $line);
			push @newlines, $result;
			++$linenr;
		}

		$start = $sstop;

		tied (@{$nvim->current->buffer})->api->set_lines ($sstart, $sstop, 1, \@newlines);
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

sub _get_range
{
	my ($this, $start, $stop) = @_;

	my $current = $this->nvim->current;
	$current->{range} = tied (@{$current->buffer})->range ($start, $stop);
	return $current;
}

=head1 NAME

Neovim::Ext::Plugin::ScriptHost - Neovim Legacy perl Plugin

=head1 SYNOPSIS

	use Neovim::Ext;

	my $host = Neovim::Ext::Plugin::Host->new ($nvim);
	$host->start ('/path/to/Plugin1.pm', '/path/to/Plugin2.pm');

=head1 METHODS

=head2 perl_execute( $script, $range_start, $range_stop )

=head2 perl_execute_file( $file_path, $range_start, $range_stop )

=head2 perl_do_range( $start, $stop, $code )

=head2 perl_eval( $expr )

=head2 perl_chdir( $cwd )

=cut

1;

