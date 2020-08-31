package Neovim::Ext::Plugin::ScriptHost;

use strict;
use warnings;
use List::Util qw/min/;
use base 'Neovim::Ext::Plugin';
use Neovim::Ext::ErrorResponse;
use Neovim::Ext::VIMCompat::Buffer;
use Neovim::Ext::VIMCompat::Window;
use Eval::Safe;

__PACKAGE__->mk_accessors (qw/current env/);
__PACKAGE__->register;

BEGIN
{
	eval "package VIM;\n use Neovim::Ext::VIMCompat;\n;1;\n";
};

our $VIM;
our $curbuf;
our $curwin;
our $_;
our $line;
our $linenr;
our $current;
our $vim;
our $nvim;


sub new
{
	my ($this, $nvim, $host) = @_;

	$VIM = $nvim;

	my $obj = $this->SUPER::new ($nvim, $host);
	$obj->env (Eval::Safe->new());
	$obj->env->share ('$curbuf');
	$obj->env->share ('$curwin');
	$obj->env->share ('$_');
	$obj->env->share ('$line');
	$obj->env->share ('$linenr');
	$obj->env->share ('$current');
	$obj->env->share ('$vim');
	$obj->env->share ('$nvim');

	return $obj;
}

sub perl_execute :nvim_rpc_export('perl_execute', sync => 1)
{
	my ($this, $script, $range_start, $range_stop) = @_;

	$this->_eval ($range_start, $range_stop, $script);
	if ($@)
	{
		die Neovim::Ext::ErrorResponse->new ($@);
	}

	return undef;
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
	return undef;
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
	return undef;
}

sub perl_eval :nvim_rpc_export('perl_eval', sync => 1)
{
	my ($this, $expr) = @_;

	$this->_setup_current();
	return $this->env->eval ($expr) // 0;
}

sub perl_chdir :nvim_rpc_export('perl_chdir', sync => 0)
{
	my ($this, $cwd) = @_;
	chdir ($cwd);
}

sub _eval
{
	my ($this, $start, $stop, $code, $line_, $linenr_) = @_;

	$this->_setup_current ($start, $stop, $line_, $linenr_);
	$this->env->eval ($code);
	return $_;
}

sub _setup_current
{
	my ($this, $start, $stop, $line_, $linenr_) = @_;

	$vim = $this->nvim;
	$nvim = $this->nvim;

	$current = $this->nvim->current;
	$current->range (tied (@{$current->buffer})->range ($start, $stop)) if (defined ($start) && defined ($stop));
	$curbuf = Neovim::Ext::VIMCompat::Buffer->new ($current->buffer);
	$curwin = Neovim::Ext::VIMCompat::Window->new ($current->window);
	$main::curbuf = $curbuf;
	$main::curwin = $curwin;

	$_ = $line_;
	$line = $line_;
	$linenr = $linenr_;
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

