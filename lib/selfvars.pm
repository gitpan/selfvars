package selfvars;
use 5.004;
use strict;
use vars qw( $VERSION $self @args );

BEGIN {
    $VERSION = '0.06';
}

sub import {
    my $class = shift; # The irony!

    # Avoid 'odd numbers of values in hash assignment' warnings.
    push @_, undef if @_ % 2;

    my %opts = (@_ ? @_ : (-self => undef, -args => undef));
    my $pkg  = caller;

    no strict 'refs';
    if (exists $opts{'-self'}) {
        $opts{'-self'} = 'self' unless defined $opts{'-self'};
        *{"$pkg\::$opts{'-self'}"} = \$self;
    }
    if (exists $opts{'-args'}) {
        $opts{'-args'} = 'args' unless defined $opts{'-args'};
        *{"$pkg\::$opts{'-args'}"} = \@args;
    }
}

package selfvars::self;

sub TIESCALAR {
    my $x;
    bless \$x => $_[0];
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
    $DB::args[0];
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
    my @c;
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

sub TIEARRAY  { my $x; bless \$x => $_[0] }
sub FETCHSIZE { scalar $#{ _args() } }
sub STORESIZE {
    require Carp;
    Carp::croak('Modification of a read-only @args attempted');
    # $#{ _args() } = $_[1] + 1;
}
sub STORE     { _args()->[ $_[1] + 1 ] = $_[2] }
sub FETCH     { _args()->[ $_[1] + 1 ] }
sub CLEAR     {
    require Carp;
    Carp::croak('Modification of a read-only @args attempted');
    # $#{ _args() } = 0;
}
sub POP       {
    require Carp;
    Carp::croak('Modification of a read-only @args attempted');
    # my $o = _args(); (@$o > 1) ? pop(@$o) : undef
}
sub PUSH      {
    require Carp;
    Carp::croak('Modification of a read-only @args attempted');
    # my $o = _args(); push( @$o, @_ )
}
sub SHIFT     {
    require Carp;
    Carp::croak('Modification of a read-only @args attempted');
    # my $o = _args(); splice( @$o, 1, 1 )
}
sub UNSHIFT   {
    require Carp;
    Carp::croak('Modification of a read-only @args attempted');
    # my $o = _args(); unshift( @$o, @_ )
}
sub EXISTS    {
    require Carp;
    Carp::croak('Modification of a read-only @args attempted');
    # my $o = _args(); exists $o->[ $_[1] + 1 ]
}
sub DELETE    {
    require Carp;
    Carp::croak('Modification of a read-only @args attempted');
    # my $o = _args(); delete $o->[ $_[1] + 1 ]
}

sub SPLICE {
    require Carp;
    Carp::croak('Modification of a read-only @args attempted');
    # my $ob  = shift;
    # my $sz  = $ob->FETCHSIZE;
    # my $off = @_ ? shift : 0;
    # $off += $sz if $off < 0;
    # my $len = @_ ? shift : $sz - $off;
    # splice( @$ob, $off + 1, $len, @_ );
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

    package MyClass;

    ### Import $self and @args into your package:
    use selfvars;

    ### Or name the variables explicitly:
    # use selfvars -self => 'self', -args => 'args';

    ### Write the constructor as usual:
    sub new {
        return bless({}, shift);
    }

    ### Use $self in place of $_[0]:
    sub foo {
        $self->{foo};
    }

    ### Use @args in place of @_[1..$#_]:
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
C<@_[1..$#_]>.  Note that they are variables, not barewords.

Currently, both C<$self> and C<@args> are read-only; this means you cannot
mutate them:

    $self = 'foo';              # error
    my $foo = shift @args;      # error

This restriction may be lifted at a later version of this module, or turned
into a configurable option instead.

=head1 INTERFACE

=over 4

=item $self

Return the current object.

=item @args

Return the argument list.

=back

=head2 Choosing non-default names 

You can choose alternative variable names with explicit import arguments:

    # Use $this and @opts instead of $self and @args:
    use selfvars -self => 'this', -args => 'opts';

    # Use $this but leave @args alone:
    use selfvars -self => 'this', -args;

    # Use @opts but leave $self alone:
    use selfvars -args => 'opts', -self;

You may also omit a variable name from the explicit import arguments:

    # Import $self but not @args:
    use selfvars -self => 'self';

    # Same as the above:
    use selfvars -self;

=head1 DEPENDENCIES

None.

=head1 ACKNOWLEDGEMENTS 

This module was inspired and based on Kang-min Liu (gugod)'s C<self.pm>.

As seen on #perl:

    <gugod> audreyt: selfvars.pm looks exactly like what I want self.pm to be in the beginning
    <gugod> audreyt: but I can't sort out the last BEGIN{} block like you did.
    <gugod> audreyt: that's a great job :D

=head1 SEE ALSO

L<self>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

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
