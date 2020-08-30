package Neovim::Ext::VIMCompat::Buffer;

use strict;
use warnings;
use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors (qw/buffer/);


sub new
{
	my ($this, $buffer) = @_;

	my $class = ref ($this) || $this;
	my $self =
	{
		buffer => $buffer,
	};

	return bless $self, $class;
}



sub Name
{
	my ($this) = @_;
	return tied (@{$this->buffer})->name;
}



sub Number
{
	my ($this) = @_;
	return tied (@{$this->buffer})->number;
}



sub Count
{
	my ($this) = @_;
	return scalar (@{$this->buffer});
}



sub Get
{
	my ($this, @lineNumbers) = @_;

	my @result;
	foreach my $lineNumber (@lineNumbers)
	{
		my $line = $this->buffer->[$lineNumber-1];
		push @result, $line if defined ($line);
	}

	if (scalar (@lineNumbers) == 1)
	{
		return shift @result;
	}

	return @result;
}



sub Delete
{
	my ($this, $start, $end) = @_;

	my $count = 1;
	if (defined ($end) && $end > $start)
	{
		if ($end > scalar (@{$this->buffer}))
		{
			$end = scalar (@{$this->buffer});
		}

		$count = $end - $start + 1;
	}

	while ($count--)
	{
		delete $this->buffer->[$start-1];
	}
}



sub Append
{
	my ($this, $start, @lines) = @_;

	if (scalar (@lines))
	{
		splice (@{$this->buffer}, $start, 0, @lines);
	}
}



sub Set
{
	my ($this, $start, @lines) = @_;

	if (scalar (@lines))
	{
		foreach my $line (@lines)
		{
			$this->buffer->[$start-1] = $line;
			++$start;
		}
	}
}

=head1 NAME

Neovim::Ext::VIMCompat::Buffer - Neovim legacy VIM perl compatibility layer

=head1 SYNPOSIS

	use Neovim::Ext;

=head1 DESCRIPTION

A compatibility layer for the legacy VIM perl interface.

=head1 METHODS

=head2 Name( )

Get the buffer name.

=head2 Number( )

Get the buffer number.

=head2 Count( )

Get the number of lines in the buffer.

=head2 Get( @lineNumbers )

Get the lines represented by C<@lineNumbers>.

=head2 Delete( $start, [$end] )

Delete line C<$start> in the buffer. If C<$end> is specified, the range C<$start>
to C<$end> will be deleted.

=head2 Append( $start, @lines )

Appends each line in C<@lines> after C<$start>.

=head2 Set( $start, @lines )

Replaces C<@lines> starting at C<$start>.

=cut

1;
