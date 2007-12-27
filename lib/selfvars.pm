package selfvars;
use 5.004;
use strict;
use Exporter ();
use base 'Exporter';
use vars qw( @EXPORT $VERSION $self @args );

BEGIN {
    @EXPORT  = qw( $self @args );
    $VERSION = '0.01';
}

package selfvars::self;

sub TIESCALAR {
    my $x;
    bless \$x => shift;
}

sub FETCH {
    my $level = 1;
    my @c     = ();
    while ( !defined( $c[3] ) || $c[3] eq '(eval)' ) {
        @c = do {
            package DB;
            @DB::args = ();
            caller($level);
        };
        $level++;
    }
    return $DB::args[0];
}

sub STORE {
    require Carp;
    Carp::croak('Modification of a read-only $self attempted');
}

package selfvars::args;
use Tie::Array ();
use vars qw(@ISA);
BEGIN { @ISA = 'Tie::Array' }

sub _args {
    my $level = 2;
    my @c     = ();
    while ( !defined( $c[3] ) || $c[3] eq '(eval)' ) {
        @c = do {
            package DB;
            @DB::args = ();
            caller($level);
        };
        $level++;
    }
    \@DB::args;
}

sub TIEARRAY  { my $x; bless \$x, $_[0] }
sub FETCHSIZE { scalar $#{ _args() } }
sub STORESIZE { $#{ _args() } = $_[1] + 1 }
sub STORE     { _args()->[ $_[1] + 1 ] = $_[2] }
sub FETCH     { _args()->[ $_[1] + 1 ] }
sub CLEAR     { $#{ _args() } = 0 }
sub POP       { my $o = _args(); return if @$o <= 1; pop(@$o) }
sub PUSH      { my $o = _args(); push( @$o, @_ ) }
sub SHIFT     { splice( @{ _args() }, 1, 1 ) }
sub UNSHIFT   { my $o = _args(); unshift( @$o, @_ ) }
sub EXISTS    { exists _args()->[ $_[1] + 1 ] }
sub DELETE    { delete _args()->[ $_[1] + 1 ] }

sub SPLICE {
    my $ob  = shift;
    my $sz  = $ob->FETCHSIZE;
    my $off = @_ ? shift : 0;
    $off += $sz if $off < 0;
    my $len = @_ ? shift : $sz - $off;
    return splice( @$ob, $off + 1, $len, @_ );
}

package selfvars;

BEGIN {
    tie $self => __PACKAGE__ . '::self';
    tie @args => __PACKAGE__ . '::args';
}

1;

__END__

=head1 NAME

selfvars - Provide $self and @args variables for OO programs

=head1 SYNOPSIS

    package MyModule;
    use selfvars;

    # Write constructor as usual.
    sub new {
        return bless({}, shift);
    }

    # Use $self in place of $_[0].
    sub foo {
        $self->{foo};
    }

    # Use @args in place of @_[1..$#_].
    sub set {
        my ($foo, $bar) = @args;
        $self->{foo} = $foo;
        $self->{bar} = $bar;
    }

=head1 DESCRIPTION

This moudles adds C<$self> and C<@args> keywords to your Perl OO module.

They are really just handy helpers to get rid of:

    my $self = shift;

Behind the scenes, C<$self> is simply tied to C<$_[0]>, and C<@args> to
C<@_[1..$#_]>.

Note that they are variables, not barewords.

=head1 INTERFACE

=over 4

=item $self

Return the current object.

=item @args

Return the argument list.

=back

=head1 DEPENDENCIES

None.

=head1 SEE ALSO

L<self>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

Inspired and based on Kang-min Liu's C<self.pm>.

=head1 COPYRIGHT

Copyright 2007 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
