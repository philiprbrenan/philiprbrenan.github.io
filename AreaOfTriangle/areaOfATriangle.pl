#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Formula for the area of a triangle from the length of its sides.
# G. H. Hardy: "Beauty is the first test:
# There is no permanent place in this world for ugly mathematics"
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2022
#-------------------------------------------------------------------------------
use v5.30;
use Test::More qw(no_plan);
use Math::Algebra::Symbols;

my ($A, $B, $C) = symbols(qw(A B C));

my $d    = ($C - ($B*$B - $A*$A) / $C) / 2;                                     # See:
my $e    = sqrt($A*$A - $d*$d);
my $area = $C*$e/2;

say STDERR $area;

sub area($$$)                                                                   # Area of a triangle
 {my ($A, $B, $C) = @_;
  1/2*$C * sqrt(1/2*$A**2 + 1/2*$A**2*$B**2/$C**2 + 1/2*$B**2 -
                1/4*$C**2 - 1/4*$A**4/$C**2 - 1/4*$B**4/$C**2);
 }

is_deeply area(3,4,5), 6;
is_deeply area(2,2,2), sqrt(3);

# 1/2*$C*sqrt(1/2*$A**2+1/2*$A**2*$B**2/$C**2+1/2*$B**2-1/4*$C**2-1/4*$A**4/$C**2-1/4*$B**4/$C**2)

# ok 1
# ok 2
# 1..2
