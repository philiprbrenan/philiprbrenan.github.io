#!/usr/bin/perl
#-------------------------------------------------------------------------------
# A hardest problem on https://open.kattis.com/problems/magicalmysteryknight
# Generate code to find a semi magical knights tour in less than 3 seconds
# Philip R Brenan at gmail dot com, 2022
#-------------------------------------------------------------------------------
sub develop    {0}                                                              # Development mode from just before this step if true
sub kattis     {1}                                                              # On kattis if true
sub STEPS      {develop ? 1e4 : 1e9}                                            # Steps allowed
sub EVERY      {develop ? 1   : 1e8}                                            # How often to show progress
sub Predict    {5};                                                             # How many set squares we need to predict that a row or column cannot be completed - too few and we waste time - too many and it is less effective than it could be.
sub Keep       {19};                                                            # How many values to fix at the start of each test

=pod

 Final board check passed
             0 Step      64 Knights1 to: 64      Squares    Knights  Squares0:  0 to: 63 line: 503
  0:  *50 *11 *24 *63 *14 *37 *26 *35  =260   8  11111111   11111111
  8:  *23 *62 *51 *12 *25 *34 *15 *38  =260   8  11111111   11111111
 16:  *10 *49 *64 *21 *40 *13 *36 *27  =260   8  11111111   11111111
 24:  *61 *22 * 9 *52 *33 *28 *39 *16  =260   8  11111111   11111111
 32:  *48 * 7 *60 * 1 *20 *41 *54 *29  =260   8  11111111   11111111
 40:  *59 * 4 *45 * 8 *53 *32 *17 *42  =260   8  11111111   11111111
 48:  * 6 *47 * 2 *57 *44 *19 *30 *55  =260   8  11111111   11111111
 56:  * 3 *58 * 5 *46 *31 *56 *43 *18  =260   8  11111111   11111111
     =260=260=260=260=260=260=260=260
        8   8   8   8   8   8   8   8
 Time:     2.7464 seconds

 Arrays are used to map knights to squares and squares to knights. The occupied
 squares are held as bit masks.  The sums of the rows and columns are cached.

 To find the squares we can reach from a square we apply a bit mask that
 selects all the squares that can be reached from a square - this combined with
 the squares in use mask tells us which squares we can go to. The position of
 each bit can be determined by __builtin_ctzl and likewise the number of
 occupied squares by __builtin_popcountl.  If only one square is available in
 possible jump mask we can deduce the knight that most go there.

 Once a square is occupied we use row and column masks to determine how many
 squares in the current row and column are left - if there is only one it is
 filled in by computing the remainder from the desired sum.  If this produces a
 valid knight it is added  to the board at that location.  The newly placed
 knight might lead to further possible placements so these are checked as well
 to see if, having complete the current row, it might be possible to complete
 the current column (or vice versa).

 Partially filled rows and columns are checked to see if there are knights
 available that could possibly fill them.

 The main program has 64 for loops nested inside each other, one loop per
 knight to be placed. If the placement of a knight does not lead to an internal
 contradiction, than the next inner loop is allowed to proceed, else the outer
 loop moves to the next possibility.

 Internally the knights are numbered 0..63 so they can be represented compactly
 as characters.  Externally they are represented as 1..64.  This dichotomy can
 easily cause confusion in the trace output so suffices of 0 and 1 are used
 where appropriate to indicate the base of a printed value.

 Perl is used to generate the C code to reduce the amount of recursion needed
 as recursion, due to its compact nature, is difficult to debug and difficult
 to optimize.  It would be even better if we generated AVX512 assembler.

 This problem is delightful because it is easy to visualize which makes it easy
 to hypothesis and test new strategies.  Success relies on bringing together a
 number of different, competing, interacting strategies to create a harmonious
 whole.

=cut
use v5.30;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Time::HiRes qw(time);
use Test::More qw(no_plan);

my $home       = currentDirectory;                                              # Home folder
my $input      = fpe $home, qw(zzz0 txt);                                       # Input file holding initial configuration - for Output file containing C
my $program    = q(MagicalMysteryKnightsTour);                                  # Program file name
my $outputC    = fpe $home, $program, q(c);                                     # Output file containing C
my $outputB    = fpe $home, qw(zzz1 txt);                                       # Output file containing winning board
my $outputE    = fpe $home, qw(zzz2 txt);                                       # Error/Trace output

sub N    {8}                                                                    # Width of a board
sub N1   {&N+1}                                                                 # 0 based upper limit of a row
sub Nm1  {&N-1}                                                                 # 0 based upper limit of a row
sub NN   {&N*&N}                                                                # Area of a board
sub NN1  {&N*&N+1}                                                              # Area of a board
sub NNm1 {&N*&N-1}                                                              # Area of a board
sub SUM  {&N/2 * (&NN+1)}                                                       # Sum we wish to reach

my @k = &startCode;                                                             # The generated code

sub square2Coords($)                                                            # Converts a square number from 0..63 to a pair of coordinates 0..7 in row major order.
 {my ($s) = @_;                                                                 # Square
  (($s - $s % &N) / &N, $s % &N)
 }

is_deeply [square2Coords(19)], [2, 3];
is_deeply [square2Coords(17)], [2, 1];
is_deeply [square2Coords( 0)], [0, 0];

sub square2CoordsCM($)                                                          # Converts a square number from 0..63 to a pair of coordinates 0..7 in column major order.
 {my ($S) = @_;                                                                 # Square
  (reverse square2Coords($S));
 }

is_deeply [square2CoordsCM(19)], [3, 2];
is_deeply [square2CoordsCM(0)],  [0, 0];

sub coords2Square($$)                                                           # Converts a pair of coordinates to a square number(0..63) in row major order
 {my ($r, $c) = @_;                                                             # Row, column
  $r*&N+$c
 }
is_deeply coords2Square(2, 3), 19;

sub coords2SquareCM($$)                                                         # Converts a pair of coordinates to a square number(0..63) in column major order
 {my ($r, $c) = @_;                                                             # Row, column
  $c*&N+$r
 }
is_deeply coords2SquareCM(2, 3), 26;

sub isAJump($$)                                                                 # Given two squares 0..63 determines whether they are a jump apart - the square numbers are in row major order.
 {my ($p, $q) = @_;                                                             # Squares
  my ($r, $c) = square2Coords($p);
  my ($R, $C) = square2Coords($q);

  ($R - $r)**2+($C-$c)**2 == 5;
 }

ok  isAJump( 1, 11);
ok  isAJump(53, 63);
ok  isAJump(21, 15);
ok  isAJump(15, 21);
ok !isAJump(21, 16);
ok  isAJump(17,  0);
ok  isAJump(15,  5);

sub jumpsFromSquare($)                                                          # The squares reachable from the specified square in one jump - the square number is in row major order.
 {my ($p) = @_;                                                                 # Square
  my @j;
  for my $i(0..&NNm1)
   {next unless isAJump($i, $p);
    push @j, $i;
   }
  @j
 }

is_deeply [jumpsFromSquare(15)], [qw(5 21 30)];
is_deeply [jumpsFromSquare(17)], [qw(0 2 11 27 32 34)];

sub createJump($)                                                               # Jumps from a square represented in row major order.
 {my ($s) = @_;                                                                 # Square
  my $j = 0;
  for my $s(jumpsFromSquare($s))
   {$j += 1<<$s;
   }
  $j
 }

is_deeply sprintf("0b%b", createJump(15)), "0b1000000001000000000000000100000";

sub createJumps()                                                               # Create jump description variables
 {my @j;
  for my $s(1..&NN)
   {push @j, createJump($s-1);
   }
  my $j = join ', ',  map {$_."UL"} @j;
  push @k, <<END;
const unsigned long long jump[] = {$j, 0};
END
 }

sub rowMasks()                                                                  # Create a mask to select each row
 {my @m;
  for my $i(1..&N)
   {push @m, (2**&N - 1) << (($i-1)*&N);
   }
  my $m = join ', ',  map {$_."UL"} @m;
  push @k, <<END;
const unsigned long long row_masks[] = {$m, 0};
END
 }

sub colMasks()                                                                  # Create a mask to select each column
 {my @m;
  for my $r(1..&N)
   {my $m = 0;
    for my $c(1..&N)
     {$m |= 1 << coords2SquareCM($r-1, $c-1);
     }
    push @m, $m;
   }
  my $m = join ', ',  map {$_."UL"} @m;
  push @k, <<END;
const unsigned long long col_masks[] = {$m, 0};
END
 }

my @Solution1 = (                                                               # Known semi magical tours from the catalog maintained by George Jellis.
50, 11, 24, 63, 14, 37, 26, 35,
23, 62, 51, 12, 25, 34, 15, 38,
10, 49, 64, 21, 40, 13, 36, 27,
61, 22,  9, 52, 33, 28, 39, 16,
48,  7, 60,  1, 20, 41, 54, 29,
59,  4, 45,  8, 53, 32, 17, 42,
 6, 47,  2, 57, 44, 19, 30, 55,
 3, 58,  5, 46, 31, 56, 43, 18);

my @Solution2 = (                                                               # Known semi magical tours from the catalog maintained by George Jellis.
 1, 48, 31, 50, 33, 16, 63, 18,
30, 51, 46,  3, 62, 19, 14, 35,
47,  2, 49, 32, 15, 34, 17, 64,
52, 29,  4, 45, 20, 61, 36, 13,
 5, 44, 25, 56,  9, 40, 21, 60,
28, 53,  8, 41, 24, 57, 12, 37,
43,  6, 55, 26, 39, 10, 59, 22,
54, 27, 42,  7, 58, 23, 38, 11,
 );

my @Solution3 = (                                                               # Known semi magical tours from the catalog maintained by George Jellis.
26,  7, 40, 59, 10, 15, 42, 61,
39, 58, 27,  8, 41, 60, 11, 16,
 6, 25, 64, 37, 14,  9, 62, 43,
57, 38,  1, 28, 63, 44, 17, 12,
24,  5, 56, 51, 36, 13, 30, 45,
55, 50, 21,  2, 29, 52, 33, 18,
 4, 23, 48, 53, 20, 35, 46, 31,
49, 54,  3, 22, 47, 32, 19, 34,
 );

my @Solution4 = (                                                               # Known semi magical tours from the catalog maintained by George Jellis.
 3, 22, 49, 56,  5, 20, 47, 58,
50, 55,  4, 21, 48, 57,  6, 19,
23,  2, 53, 44, 25,  8, 59, 46,
54, 51, 24,  1, 60, 45, 18,  7,
15, 36, 43, 52, 17, 26,  9, 62,
42, 39, 16, 33, 12, 61, 30, 27,
35, 14, 37, 40, 29, 32, 63, 10,
38, 41, 34, 13, 64, 11, 28, 31, );

my @Solution5 = (                                                               # Known semi magical tours from the catalog maintained by George Jellis.
 4, 23, 50, 55,  6, 25, 58, 39,
49, 54,  5, 24, 57, 38,  7, 26,
22,  3, 56, 51, 28,  1, 40, 59,
53, 48, 21,  2, 37, 64, 27,  8,
20, 35, 52, 29, 14,  9, 60, 41,
47, 32, 13, 36, 63, 44, 15, 10,
34, 19, 30, 45, 12, 17, 42, 61,
31, 46, 33, 18, 43, 62, 11, 16,);

my @Solution6 = (                                                               # Known semi magical tours from the catalog maintained by George Jellis.
 3, 22, 49, 56,  5, 20, 47, 58,
50, 55,  4, 21, 48, 57,  6, 19,
23,  2, 53, 44, 25,  8, 59, 46,
54, 51, 24,  1, 60, 45, 18,  7,
15, 36, 43, 52, 17, 26,  9, 62,
42, 39, 16, 33, 12, 61, 30, 27,
35, 14, 37, 40, 29, 32, 63, 10,
38, 41, 34, 13, 64, 11, 28, 31);

my @Solutions = ([@Solution1], [@Solution2], [@Solution3],
                 [@Solution4], [@Solution5], [@Solution6]);

sub mainLoop()                                                                  # The main loop to position the numbered knight on a square reachable from the square occupied by the previous knight
 {my $N     = &N;
  my $N1    = $N + 1;
  my $NN    = &NN;
  my $NNm1  = &NNm1;
  my $D     = &develop;
  my $E     = &EVERY;
  my $STEPS = &STEPS;

  push @k, <<END;
int Solution [$NN];                                                             // Solution - which will be known during testing but not on kattis  with knights in the range 1..64
int Test     [$NN];                                                             // Test - shows the original input values of the test

void mainLoop() {
END
  push @k, <<END if $D;                                                         # Check path
const int correct_1 = 1;                                                        // First knight is always given
END

  for my $K(2..&NN)                                                             # Each knight
   {my $k = $K - 1;
    push @k, <<END;

int jumps_$k\[$N1\];                                                            // Possible jumps
int already_$k = 0;                                                             // Already set by some prior level
if (!bitTest(km, $k)) availableForJumpingTo(jump[(int)k2s[$k-1]], jumps_$k);    // Possible jumps from the square occupied by the previous knight
else {jumps_$k\[0\] = k2s\[$k\]; jumps_$k\[1\] = NoKnight; already_$k = 1;}     // The preset jump

//Dif (correct_$k)                                                              // Check that we are going to be able to place the next level
//D {int found = 0;
//D  for(int *s$k = jumps_$k; *s$k != NoKnight; ++s$k)
//D   {if (Solution[*s$k] == $K) ++found;
//D   }
//D  if (!found) stop("No placement possible for $K");
//D }

for(int *s$k = jumps_$k; *s$k != NoKnight; ++s$k)                               // Each knight
 {const int sk = *s$k;

  ++step;
  //Dif (step > $STEPS) {printTime(); stop("Out of steps %d", step);}           // Steps limit
  //Dif (step >= $D) checkIntegrity();                                          // Integrity
  //Dif ($E > 0 && step % $E == 0) printBoard(224);                             // Print board periodically

  const int Sk = s2k[sk]; if (Sk > NoKnight && Sk != $k) continue;              // Skip this square because it is already occupied by another knight. If it is occupied by the current knight then 'already' will take care of this situation otherwise the path must be invalid

  char save_k_$k\[$NN\], save_s_$k\[$NN\];                                      // Save state
  short save_rowSums_$k\[$N\], save_colSums_$k\[$N\];                           // Save row and column sums
  unsigned long long save_km_$k = 0, save_sm_$k = 0;                            // Save usage mask

  if (!already_$k)                                                              // Not already set so check for row /col sum
   {memcpy(save_k_$k, k2s, $NN);
    memcpy(save_s_$k, s2k, $NN);
    memcpy(save_rowSums_$k, rowSums, $N * sizeof(short));
    memcpy(save_colSums_$k, colSums, $N * sizeof(short));
    save_km_$k = km;
    save_sm_$k = sm;

    if (setKnightOK($k, sk)) goto next_$k;                                      // Set knight
    if (fillRow    (    sk)) goto next_$k;
    if (fillCol    (    sk)) goto next_$k;
    if (chainAndSet($k))     goto next_$k;
   }
END
    push @k, <<END if $D;                                                       # Check path
const int correct_$K = correct_$k && Solution[*s$k] == $K;                      // Whether the current solution is the correct one
if (correct_$K) say("Correct $K=%d", correct_$K);
END
   }

  if (kattis)                                                                   # At the center - the heart of the sun
   {push @k,<<END;
    printWinningBoard();                                                        // Found a winner
    exit(0);
END
   }
  else                                                                          # At the center - the heart of the sun
   {push @k,<<END;
    if (checkWinner()) longjmp(finished, 1);                                    // Found a winner
END
   }

  for my $K(reverse 2..&NN)                                                     # Each knight
   {my $k = $K - 1;

    push @k, <<END;
  next_$k:
END
    push @k, <<END if $D;                                                       # Check path
  if (correct_$K)
   {printBoard(265);
    stop("Moving off correct answer at Knight1 %d", $K);
   }
END
    push @k, <<END;
  if (!already_$k)                                                              // Restore state
   {memcpy(k2s, save_k_$k, $NN);
    memcpy(s2k, save_s_$k, $NN);
    memcpy(rowSums, save_rowSums_$k, $N * sizeof(short));
    memcpy(colSums, save_colSums_$k, $N * sizeof(short));
    km = save_km_$k;
    sm = save_sm_$k;
   }
 } // $k
END
   }
  push @k, <<END unless kattis;
  stop("No solution found after %d steps", step);
END
  push @k, <<END;
 } // mainLoop
END
 }

sub startCode                                                                   # Starting code
 {my @c = <<END;
#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <memory.h>
#include <assert.h>
#include <setjmp.h>
#include <time.h>
#include <errno.h>

static int canJump(const int s, const int S);
static int chainAndSet(const int k);
static int colSumCheck(int s);
static int colSum(int s);
static int fillCol(int c);
static int fillRow(int r);
static int rowSumCheck(int s);
static int rowSum(int s);
static int setKnight  (int k, int s);
static int setKnightOK(int k, int s);
static void availableForJumpingTo(unsigned long long jumpMask, int *jumps);
static void clearBoard();                                                       // Clear the board
static void load();

unsigned long long km  = 0;                                                     // Occupied knight positions 0..63 in row major order mask
unsigned long long sm  = 0;                                                     // Occupied square positions 0..63 in row major order mask
         char *k2s     = 0;                                                     // Knight(0..63) to square(0..63) in row major order
         char *s2k     = 0;                                                     // Square(0..63) in row major order to knight
short *     rowSums    = 0;                                                     // Row sums
short *     colSums    = 0;                                                     // Col sums

int step               = 0;                                                     // The current step
clock_t start          = 0;                                                     // Start time

jmp_buf finished;                                                               // This is where we go when we have finished

#define bitSet(f, i)   ((f) |= (1ul<<(i)))                                      // Set a bit in a mask
#define bitTest(f, i)  ((f) &  (1ul<<(i)))                                      // Test a bit in a mask
#define bitClear(f, i) ((f)  = ~(~(f) | (1ul<<(i))))                            // Clear a bit in a mask

#define NoKnight -1                                                             // Indicates the lack of a Knight

END

  push @c, <<END if kattis;
static void printWinningBoard();
END

  push @c, <<END unless kattis;
static int checkWinner();
static void checkIntegrity();
static void load_fromArray(int *in);
static void printBoard(int line);
static void printk2s();
static void printKm();
static void printMask(unsigned long long m);
static void prints2k();
static void printSm();
static void printTime();
static void say(char *format, ...);
static void stop(char *format, ...);
END

  return join '', @c;
 }

sub endCode
 {my $N    = &N;
  my $N1   = &N1;
  my $Nm1  = &Nm1;
  my $NN   = &NN;
  my $NN1  = &NN1;
  my $NNm1 = &NNm1;
  my $SUM  = &SUM;
  my $D    = &develop;
  my $Dm1  = qq(step >= $D - 10),
  my $E    = &EVERY;
  my $K    = &kattis;
  my $S    = q(static inline);
  my $Predict = Predict;
  my $KEEP = &Keep;

  my @c;

  push @c, <<END if kattis;
void load()                                                                     // Load a board from a file
 {clearBoard();
  for(int s = 0; s < $NN; s++)
   {int k;
    const int r = scanf("%d", &k);
    if (r != 1) {fprintf(stderr, "Scanf failed at %d code: %d", s, r); exit(0);}
    if (k > NoKnight) setKnight(k-1, s);
   }
 }
END

  push @c, <<END unless kattis;
void load()                                                                     // Load a board from a file
 {int in[$NN];

  for(int s = 0; s < $NN; s++)
   {int k;
    const int r = scanf("%d", &k);
    if (r != 1) {fprintf(stderr, "Scanf failed at %d code: %d", s, r); exit(0);}
    in[s] = k;
   }

  for(int s = 0; s < $NN; s++)                                                  // Load the solution to check its integrity
   {const int k = in[s];
    Solution[s] = k;
    Test    [s] = k;
    setKnight(k-1, s);
   }
  checkIntegrity();

  clearBoard();
  for(int s = 0; s < $NN; s++)                                                  // Partially load the solution to provide a test
   {const int k = in[s];
    Test    [s] = NoKnight;                                                     // Show starting point
    if (k <= $KEEP) {setKnight(k-1, s); Test[s] = k;}                           // Create test from first 19 known values
   }
 }
END

  push @c, <<END;
void clearBoard()                                                               // Clear the board
 {sm = km = 0; memset(k2s, NoKnight, $NN1); memset(s2k, NoKnight, $NN1);
  memset(rowSums, 0, sizeof(short) * $N);
  memset(colSums, 0, sizeof(short) * $N);
 }

$S void availableForJumpingTo(unsigned long long jumpMask, int *jumps)          // Locate squares (row major) we can jump to using a specified mask
 {unsigned long long open = jumpMask & ~sm;
  memset(jumps, NoKnight, sizeof(int) * $N1);                                   // Show unused jumps with -1 as 0 is a valid square number

  for(int i = 0, j = 0; open && i < $N; ++i)
   {const int p = jumps[j++] = __builtin_ctzl(open);
    open &= ~(1ul<<p);
   }
 }

$S int canJump(const int s, const int S)                                        // Test whether we can jump between the two squares in one move
 {const int c = s % $N, r = s / $N,  C = S % $N, R = S / $N,                    // Position of knights
    rR = (R - r), cC = (C - c), d = rR*rR+cC*cC;                                // Distance away
  return d == 5;                                                                // No other pair of squares will yield this value unless they are in jump apart
 }

$S int countKnights()                                                           // Count the number of knights that have been placed
 {return __builtin_popcountl(km);                                               // Knights set
 }

$S int countSquares()                                                           // Count the number of squares that are in use
 {return __builtin_popcountl(sm);                                               // Squares set
 }
END

 push @c, <<END unless kattis;
int checkWinner2()                                                              // Check the board for a winning combination assuming that the board is full
 {if (~km)                                                                      // Knights unset
  {say("Check failed because not all knights placed");
   return 0;
  }

 if (~sm)                                                                       // Squares unset
  {say("Check failed because not all squares filled");
   return 0;
  }

 const int s = k2s[0];
  int C = s % $N, R = s / $N;                                                   // Position of first knight
  for(int k = 1; k < $NN; ++k)                                                  // Chain through knights
   {const int s = k2s[k], c = s % $N, r = s / $N,                               // Position of current knight
      rR = (R - r), cC = (C - c), d = rR*rR+cC*cC;                              // Distance away
    if (d != 5)                                                                 // Not a jump away
     {say("CheckWinner: Chain failed at knight1=%d, s=%d R=%d C=%d r=%d c=%d",
          k+1, s, R, C, r, c);
      return 0;
     }
    R = r; C = c;
   }
  for(int r = 0; r < $N; ++r)                                                   // Row sums
   {int t = 0;
    for(int c = 0; c < $N; ++c) t += s2k[r * $N + c]+1;
    if (t != $SUM)
     {say("CheckWinner: Sum failed for row %d sum=%d", r, t);
      return 0;
     }
   }
  for(int c = 0; c < $N; ++c)                                                   // Column sums
   {int t = 0;
    for(int r = 0; r < $N; ++r) t += s2k[r * $N + c]+1;
    if (t != $SUM)
     {say("CheckWinner: Sum failed for col %d sum=%d", c, t);
      return 0;
     }
   }
  return 1;
 }

int checkWinner()                                                               // Check the board for a winning combination assuming that the board is full
 {checkIntegrity();
  const int r = checkWinner2();
  if (!r) {say("Final board check FAILED at step: %d", step); printBoard(502);}
  else    {say("Final board check passed at step: %d", step); printBoard(503);}
  return r;
 }
END

 push @c, <<END;
$S int rowCount(int s)                                                          // Count the number of knights set in a row
 {const int r = s / $N;
  const unsigned long long mask = row_masks[r], bits = mask & sm;               // Occupied squares in this row
  return __builtin_popcountl(bits);                                             // Number of squares set in this row
 }

$S int rowSum(int s)                                                            // Sum the knights in a row
 {const unsigned int r = s / $N;
  return rowSums[r];
 }

$S int rowSumCheck(int s)                                                       // Sum the knights in a row and return 1 if they are over the sum else 0
 {return rowSum(s) > $SUM;
 }

int fillRow(int s)                                                              // Fill a row if there is one empty square left in it. If we cannot fill the square then return 1 to show that this path is not worth continuing with
 {const int r = s / $N;
  const unsigned long long mask = row_masks[r], bits = mask & sm;               // Occupied squares in this row
  const int count = __builtin_popcountl(bits);                                  // Number of squares set in this row

  if (count == $Nm1)                                                            // One left means we can fill
   {const int q = __builtin_ctzl(~bits & mask);                                 // The square to be filled
    int k = $SUM - rowSum(q);                                                   // Must be this knight
    if ( k > 0 && k <= $NN && !bitTest(km, k-1))                                // Proposed knight is in range and is free
     {//Dif ($Dm1) say("FillRow %d: knight1 %2d  square=%2d", q/$N, k, q);
      return setKnightOK(k-1, q) || fillCol(q) || chainAndSet(k-1);             // Outcome depends on further chaining and filling
     }
    else                                                                        // Stop: fill required but not possible
     {//Dif ($Dm1) say("Row %d fill not possible using knight %d", q/$N, k);
      return 1;
     }
   }
  return 0;                                                                     // Continue: no fill required
 }

$S int colCount(int s)                                                          // Count the number of knights set in a row
 {const int c = s % $N;
  const unsigned long long mask = col_masks[c], bits = mask & sm;               // Occupied squares in this column
  return __builtin_popcountl(bits);                                             // Number of squares set in this column
 }

$S int colSum(int s)                                                            // Sum the knights in a column
 {const int c = s % $N;
  return colSums[c];
 }

$S int colSumCheck(int s)                                                       // Sum the knights in a column and return 1 if they are over the sum else 0
 {return colSum(s) > $SUM;
 }

int fillCol(int s)                                                              // Fill a column if there is one empty square left in it
 {const int c = s % $N;
  const unsigned long long mask = col_masks[c], bits = mask & sm;               // Occupied squares in this column
  const int count = __builtin_popcountl(bits);                                  // Number of squares set in this column

  if (count == $Nm1)                                                            // One left means we can fill
   {const int q = __builtin_ctzl(~bits & mask);                                 // The square containing to be filled
    int k = $SUM - colSum(q);                                                   // Must be this knight
    if ( k > 0 && k <= $NN && !bitTest(km, k-1))                                // Proposed knight is in range and is free
     {//Dif ($Dm1) say("FillCol %d: knight1 %2d  square0=%2d", q%$N, k, q);
      return setKnightOK(k-1, q) || fillRow(q) || chainAndSet(k-1);             // Outcome depends on further chaining and filling
     }
    else                                                                        // Stop: fill destroys path
     {//Dif ($Dm1) say("Column %d fill not possible using knight1 %d", q%$N, k);
      return 1;
     }
   }
  return 0;                                                                     // Continue: no fill required
 }

int chainAndSet(const int k)                                                    // Create chains where possible for the specified knight. Returns 1 only if it can be determined that no placement is possible in this position otherwise returns true
 {const int s = k2s[k];                                                         // Current square

  int f = 0, F = 0;
  if (k > 0)
   {const int q = k2s[k-1];                                                     // Low chain
    if (q > NoKnight)
     {f = canJump(s, q);
     }
   }
  else f = 1;

  if (k < $NNm1)
   {const int Q = k2s[k+1];
    if (Q > NoKnight)                                                           // High chain
     {F = canJump(s, Q);
     }
   }
  else F = 1;

  if ( f &&  F) return 0;                                                       // Continue: the chain is complete

  const unsigned long long
    js  = jump[s],
    nsm = ~sm,                                                                  // The targets available
    jmp = js & nsm;

  const int n = __builtin_popcountl(jmp);                                       // The number of targets available

  if ( f && !F)                                                                 // Upper chain is missing
   {if (n == 1)                                                                 // One free square so it must go here
     {const int K = k + 1;
      if (bitTest(km, K)) return 1;                                             // Required knight already in use somewhere else
      const int S = __builtin_ctzl(jmp);                                        // Square to set
      return setKnightOK(K, S) ||                                               // Result depends on finding a failure in further chaining and filling
        rowSumCheck(S) || colSumCheck(S) ||
        fillRow(S)     ||     fillCol(S) || chainAndSet(K);
     }
    //Dif ($Dm1 && !n) say("SetAndChain1 knight1 %2d", k);
    return !n;                                                                  // Stop: one missing and no square to contain it
   }

  if (!f &&  F)                                                                 // Lower chain is missing
   {if (n == 1)                                                                 // One free square so it must go here
     {const int K = k - 1;
      if (bitTest(km, K)) return 1;                                             // Required knight already in use somewhere else
      const int S = __builtin_ctzl(jmp);                                        // Square to set
      return setKnightOK(K, S) ||                                               // Result depends on finding a failure in further chaining and filling
        rowSumCheck(S) || colSumCheck(S) ||
        fillRow(S)     ||     fillCol(S) || chainAndSet(K);
     }
    //Dif ($Dm1 && !n) say("SetAndChain2 knight1 %2d", k);
    return !n;                                                                  // Stop: one missing and no square to contain it
   }

  //Dif ($Dm1 && n < 2) say("SetAndChain3 knight1 %2d", k);
  return n < 2;                                                                 // Stop: Two missing but not enough squares to accommodate them
 }

$S int predictRow(int s)                                                        // Square in row to predict
 {const unsigned long long
    nkm    = ~km,
    Start  = __builtin_ctzl(nkm),
    Finish = __builtin_clzl(nkm);
  const int start = (int)Start, finish = $NNm1 - (int)Finish;

  const int n = rowCount(s);
  if (n < $Predict || n == $N) return 0;                                        // Continue: too soon to predict
  const int C = $N - n;

  int l = 0;
  for(int k = start, c = 0; c < C && k <= finish; ++k)                          // Sum of lowest knights
   {if (bitTest(nkm, k)) {l += k+1; ++c;}
   }
  const int rs = rowSum(s);
  //Dif ($Dm1 && rs + l > $SUM) say("predictRow1 square: %2d n=%2d l=%2d rs=%2d", s, n, l, rs);
  if (rs + l > $SUM) return 1;                                                  // No point in continuing because this row is already too big

  int h = 0;
  for(int k = finish, c = 0; c < C && k >=start; --k)                           // Sum of highest knights
   {if (bitTest(nkm, k)) {h += k+1; ++c;}
   }

  //Dif ($Dm1 && rs + h < $SUM) say("predictRow2 square: %2d", s);
  if (rs + h < $SUM) return 2;                                                  // No point in continuing because this row will never be big enough
  return 0;                                                                     // Rum sum still possible
 }

$S int predictCol(int s)                                                        // Square in column to predict
 {const unsigned long long
    nkm    = ~km,
    Start  = __builtin_ctzl(nkm),
    Finish = __builtin_clzl(nkm);
  const int start = (int)Start, finish = $NNm1 - (int)Finish;

  const int n = colCount(s);
  if (n < $Predict || n == $N) return 0;                                        // Continue: too soon to predict
  const int C = $N - n;

  int l = 0;
  for(int k = start, c = 0; c < C && k <= finish; ++k)                          // Sum of lowest knights
   {if (!bitTest(km, k)) {l += k+1; ++c;}
   }
  const int cs = colSum(s);
  //Dif ($Dm1 && cs + l > $SUM) say("predictCol1 square: %2d", s);
  if (cs + l > $SUM) return 1;                                                  // No point in continuing because this row is already too big

  int h = 0;
  for(int k = finish, c = 0; c < C && k >= start; --k)                          // Sum of highest knights
   {if (bitTest(nkm, k)) {h += k+1; ++c;}
   }

  //Dif ($Dm1 && cs + h < $SUM) say("predictCol2 square: %2d C=%2d start=%2d finish=%2d cs=%2d h=%2d", s, C, start, finish, cs, h);
  if (cs + h < $SUM) return 2;                                                  // No point in continuing because this row will never be big enough
  return 0;                                                                     // Rum sum still possible
 }

$S int setKnight(int k, int s)                                                  // Put a knight on a square - return true if the board is invalid as a result of the placement
 {k2s[k] = s;                                                                   // Assign square to knight
  s2k[s] = k;                                                                   // Assign knight to square
  bitSet(km, k);                                                                // Set knight usage mask
  bitSet(sm, s);                                                                // Set square usage mask
  const int r = s / $N, c = s % $N;
  rowSums[r] += k + 1,                                                          // Update row sum
  colSums[c] += k + 1;                                                          // Update col sum

  //Dif($Dm1)                                                                   // Show state of play
  //D {say("Set knight1 %2d at square0 %2d", k+1, s);
  //D  printBoard(685);
  //D }

  //Dif ($Dm1 && rowCount(s) == $N && rowSumCheck(s)) say("setKnight1 knight1: %2d square: %2d", k, s);
  if (rowCount(s) == $N && rowSumCheck(s)) return 1;                            // Row overflow
  //Dif ($Dm1 && colCount(s) == $N && colSumCheck(s)) say("setKnight2 knight1: %2d square: %2d", k, s);
  if (colCount(s) == $N && colSumCheck(s)) return 1;                            // Column overflow
  return 0;                                                                     // Path becomes invalid if the row or cols overflows
 }

int setKnightOK(int k, int s)                                                   // Put a on a knight on a square as long as the next knight is not placed in a contradictory position
 {if (k+1 < $NN && bitTest(km, k+1) && !canJump(s, k2s[k+1]))                   // If the next knight is already set then we need to be able to reach it from this square
   {//Dif ($Dm1)
    //D {say("Cannot jump from knight1 %d to knight1 %d", k+1, k+2);
    //D }
    return 1;                                                                   // Stop: cannot chain to next knight which already exists
   }
  if (k > 0 && bitTest(km, k-1) && !canJump(s, k2s[k-1]))                       // If the previous knight is already set then we need to be able to reach it from this square
   {//Dif ($Dm1)
    //D {say("Cannot jump from knight1 %d to knight1 %d", k+1, k);
    //D }
    return 1;                                                                   // Stop: cannot chain to next knight which already exists
   }
  if (k2s[k] > NoKnight)                                                        // Already set
   {//Dif ($Dm1) say("Knight1 %d already set", k+1);
    return 1;                                                                   // Stop: cannot chain to next knight which already exists
   }
  if (s2k[s] > NoKnight)                                                        // Already set
   {//Dif ($Dm1) say("Square0 %d already set", s);
    return 1;                                                                   // Stop: cannot chain to next knight which already exists
   }
  return setKnight(k, s) || predictRow(s) || predictCol(s);
 }

void printWinningBoard()                                                        // Print board in kattis format
 {for(int s = 0; s < $NN; ++s)                                                  // Print rows
   {const int k = s2k[s];
    printf(" %2d", k+1);
    if (s && s % $N == $Nm1) printf("\\n");
   }
 }
END

  push @c, <<END unless $K;
void checkIntegrity()                                                           // Check the integrity of the board
 {const int sn = countSquares(), kn = countKnights();

  if (1)                                                                        // Match against known part of solution
   {for(int s = 0; s < $NN; ++s)
     {const int k = Solution[s]-1, K = s2k[s];
      if (Test[s] > NoKnight &&  K > NoKnight && K != k)
       {printBoard(392);
        stop("Integrity: Square %d should have knight1 %d but has %d", s, k+1, K+1);
       }
     }
   }

  if (sn != kn)
   {printBoard(398);
    stop("Integrity: Knights %d versus squares %d", sn, kn);
   }

  for(int k = 0; k < $NN; ++k)                                                  // Knights to squares and back
   {if (bitTest(km, k))
     {const int K = s2k[(int)k2s[k]];
      if (K != k)                                                               // Knight set
       {printBoard(405);
        stop("Integrity: Round trip failed for knight1 = %d to %d", k+1, K+1);
       }
     }
    else
     {const int s = k2s[k];
      if (s != NoKnight)                                                        // Knight set
       {printBoard(440);
        stop("Integrity: Knight mask and board disagree for knight1 = %d square0 %d", k+1, s);
       }
     }
   }

  for(int s = 0; s < $NN; ++s)                                                  // Squares to knights and back
   {if (bitTest(sm, s))
     {const int S = k2s[(int)s2k[s]];                                           // Square set
      if (S != s)                                                               // Square set
       {printBoard(450);
        stop("Integrity: Round trip failed for square = %d to %d", s, S);
       }
     }
    else
     {const int k = s2k[s];
      if (k != NoKnight)                                                        // Knight set
       {printBoard(457);
        stop("Integrity: Square mask and board disagree for square0 = %d knight1 %d", s, k+1);
       }
     }
   }

  const int s = k2s[0];                                                         // Walk board
  int R = s / $N, C = s % $N;                                                   // Position of first knight

  for(int k = 1; k < $NN; ++k)                                                  // Chain through knights
   {if (bitTest(km, k))                                                         // Knight is active
     {const int s = k2s[k], r = s / $N, c = s % $N,                             // Position of current knight
        rR = (R - r), cC = (C - c), d = rR*rR+cC*cC;                            // Distance away
      if (d != 5)                                                               // Not a jump away
       {printBoard(429);
        stop("Integrity: Chain failed at knight1=%d s=%d R=%d C=%d r=%d c=%d", k+1, s, R, C, r, c);
       }
      R = r; C = c;
     }
    else
     {for(; k < $NN; ++k)                                                       // Move up to next active knight
       {if (bitTest(km, k))
         {const int s = k2s[k]; R = s / $N; C = s % $N;
          break;
         }
       }
     }
   }

  for(int r = 0; r < $N; ++r)                                                   // Row sums
   {const int S = rowSum(r*$N), s = rowSums[r];
    if (S != s)
     {printBoard(461);
      stop("Integrity: Row %d sum computed %d vs cached %d", r, S, s);
     }

    if (S > $SUM)
     {printBoard(464);
      stop("Integrity: Row sum %d failed for row %d", S, r);
     }
   }

  for(int c = 0; c < $N; ++c)                                                   // Col sums
   {const int S = colSum(c), s = colSums[c];
    if (S != s)
     {printBoard(472);
      stop("Integrity: Col %d sum computed %d vs cached %d", c, S, s);
     }
    if (S > $SUM)
     {printBoard(476);
      stop("Integrity: Col sum %d failed for col %d", S, c);
     }
   }
 }

void printMask(unsigned long long m )                                           // Print mask
 {for(int k = 0; k < $NN; ++k) fprintf(stderr, " %2d", k);
  say("");
  for(int k = 0; k < $NN; ++k) fprintf(stderr, " %2d", !!((m) & (1ul<<k)));
  say("");
 }

void printKm()                                                                  // Print board by knight
 {printMask(km);
 }

void printSm()                                                                  // Print board by square
 {printMask(sm);
 }

void printBoard(int line)                                                       // Print board
 {const int lS = __builtin_ctzl(sm),                                            // Low square
            hS = $NN - __builtin_clzl(sm) -1,                                   // High square
            hK = $NN - __builtin_clzl(km);                                      // High knight

  fprintf(stderr, " %12d Step      %2d Knights1 to: %2d"                        // Titles
    "      Squares    Knights  Squares0: %2d to: %2d line: %d"
    "\\n%2d: ", step, countKnights(), hK, lS, hS, line, 0);                     // Start of row

  for(int s = 0; s < $NN; ++s)                                                  // Print rows
   {const int k = s2k[s];
    const char e = Solution[s] == k + 1 ? '*' : ' ';
    if (bitTest(sm, s)) fprintf(stderr, " %c%2d", e, k+1);
    else                fprintf(stderr, "   .");

    if (s && s % $N == $Nm1)                                                    // Position
     {fprintf(stderr, "  =%3d %2d  ", rowSum(s), rowCount(s));
      for (int i = s - $Nm1; i <= s; ++i)
       {if (bitTest(sm, i)) fprintf(stderr, "1"); else fprintf(stderr, "0");
       }
      fprintf(stderr, "   ");
      for (int i = s - $Nm1; i <= s; ++i)
       {if (bitTest(km, i)) fprintf(stderr, "1"); else fprintf(stderr, "0");
       }
      if (s+1 != $NN)   fprintf(stderr, "\\n%2d: ", 1+s);
      else              fprintf(stderr, "\\n");
     }
   }

  fprintf(stderr, "    ");
  for(int s = 0; s < $N; ++s)                                                   // Column Sums computed
   {fprintf(stderr, "=%3d", colSum(s));
   }
  fprintf(stderr, "\\n    ");
  for(int s = 0; s < $N; ++s)                                                   // Column counts
   {fprintf(stderr, "  %2d", colCount(s));
   }
  say("");
  if (0 && $D && $Dm1)                                                          // Print restart
   {say("const int[$NN] = {");
    for  (int r = 0, s = 0; r < $N; ++r)
     {for(int c = 0; c < $N; ++c)
       {const int sk = s2k[s++], p = sk > -1 ? sk + 1 : -1;

        if (s == $NNm1)
         {fprintf(stderr, " %2d", p);
         }
        else
         {fprintf(stderr, " %2d,", p);
         }
       }
      say("");
     }
    say("};");
   }
 }

void printk2s()                                                                 // Print board
 {fprintf(stderr, "k2s ");
  for(int k = 0; k < $NN; ++k)
   {const int s = k2s[k];
    fprintf(stderr, " %2d", s);
   }
  say("");
  fprintf(stderr, "km  ");
  for(int k = 0; k < $NN; ++k)
   {const unsigned int K = 1ul << k;
    const int count = K & km;                                                   // Number of squares set in this row
    fprintf(stderr, " %2d", !!count );
   }
  say("");
 }

void prints2k()                                                                 // Print board
 {fprintf(stderr, "s2k ");
  for(int s = 0; s < $NN; ++s)
   {const int k = s2k[s];
    fprintf(stderr, " %2d", k);
   }
  say("");
  fprintf(stderr, "sm  ");
  for(int s = 0; s < $NN; ++s)
   {const unsigned int S = 1ul << s;
    const int count = S & sm;                                                   // Number of squares set in this row
    fprintf(stderr, " %2d", !!count );
   }
  say("");
 }

void printTime()                                                                // Print time used
 {say("Time: %10.4f seconds", ((double) (clock() - start)) / CLOCKS_PER_SEC);
 }

void load_fromArray(int *in)                                                    // Load an initial board
 {for(int i = 0; i < $NN; i++) if (in[i] > NoKnight) setKnight(in[i]-1, i);     // Processing is done based from 0, but input is 1 based
 }

void test_unused()                                                              // TESTS
 {if (1) return;                                                                // These functions are here just to prevent compiler messages. They should not actually be executed at this point.
  prints2k();
  printk2s();
  printSm();
  printKm();
 }

void test_availableForJumpingTo()                                               // Test available for jumping
 {say("AvailableForJumping to ");
  sm     = 0; bitSet(sm, 1); bitSet(sm, 42); bitSet(sm, 31); bitSet(sm, 47);
  unsigned long long m = 0;       bitSet(m,  42); bitSet(m,  29);
  int j[$N1];
  availableForJumpingTo(m, j);
  assert(j[0] == 29);
  assert(j[1] == NoKnight);
 }

void test_bits()                                                                // Test bit operations
 {say("Test bits");
  unsigned long long a = 0;
  bitSet(a, 0);
  bitSet(a, 1);
  bitSet(a, 2);
  assert(a == 7);
  assert( bitTest(a, 2));
  assert(a == 7);
  assert(!bitTest(a, 3));
  assert(a == 7);
  bitClear(a, 1);
  assert(a == 5);
 }

void test_setKnight()                                                           // Test knight set
 {say("Set Knight");
  clearBoard();
  setKnight(0, 1); assert(k2s[0] == 1); assert(s2k[1] == 0); assert(sm ==  2); assert(km == 1);
  setKnight(1, 0); assert(k2s[1] == 0); assert(s2k[0] == 1); assert(sm ==  3); assert(km == 3);
  setKnight(2, 9); assert(k2s[2] == 9); assert(s2k[9] == 2); assert(sm ==515); assert(km == 7);
 }

void test1_fillRow()                                                            // Test row filling
 {clearBoard();
  say("Test row fill 1");
  for(int i = 0; i < $Nm1; ++i) setKnight(i*9, i);
  say("AAAA %d", fillRow(0));
  assert(fillRow(0) == 0);
  assert(fillCol(0) == 0);
 }

void test2_fillRow()                                                            // Test row filling
 {clearBoard();
  say("Test row fill 2");
  for(int i = 0; i < $Nm1; ++i) setKnight(1+i*9, i);
  assert(fillRow(0) == 1);
  assert(fillCol(0) == 0);
 }

void test3_fillRow()                                                            // Test row filling
 {clearBoard();
  say("Test row fill 3");
  for(int i = 0; i < $Nm1; ++i) setKnight(2+i*9, i);
  assert(fillRow(0) == 0);
  assert(fillCol(0) == 0);
 }

void test4_fillRow()                                                            // Test row filling
 {clearBoard();
  say("Row fill 3");
  for(int i = 0; i < $Nm1; ++i) setKnight(i*8, i);
  assert(fillRow(0) == 1);
  assert(fillCol(0) == 0);
 }

void test1_fillCol()                                                            // Test col filling
 {clearBoard();
  say("Test column fill 1");
  for(int i = 0; i < $Nm1; ++i) setKnight(i*9, i*8);
  assert(fillCol(0) == 0);
  assert(fillRow(0) == 0);
 }

void test2_fillCol()                                                            // Test row filling
 {clearBoard();
  say("Test column fill 2");
  for(int i = 0; i < $Nm1; ++i) setKnight(i*8, i*8);
  assert(fillCol(0) == 1);
  assert(fillRow(0) == 0);
 }

void test_fill2()                                                               // Test an awkward row fill
 {clearBoard();
  int Test2    [$NN] = {
-1, 11, 24, -1, 14, 37, 26, 35,
23, -1, -1, 12, 25, 34, 15, 38,
10, -1, -1, 21, 40, 13, 36, 27,
-1, 22,  9, -1, 33, 28, 39, 16,
-1,  7, -1,  1, 20, 41, 54, 29,
-1,  4, 45,  8, 53, 32, 17, 42,
 6, 47,  2, 57, 44, 19, 30, 55,
 3, 58,  5, 46, 31, 56, 43, 18};
  load_fromArray(Test2);
  say("Test fill 2");
  fillRow(40);
 }

void test_fill()                                                                // Test row filling
 {test1_fillRow(); test2_fillRow(); test3_fillRow(); test4_fillRow();
  test1_fillCol(); test2_fillCol();
  test_fill2();
 }

void test_chainAndSet()                                                         // Test chaining
 {clearBoard();
  setKnight(0, 10);  setKnight(1, 0);
  assert( canJump(10, 0));  assert( canJump(0, 10));
  assert(!chainAndSet(1));
  assert(!chainAndSet(0));
  assert(!chainAndSet(2));
  assert(s2k[17] == 2);

  clearBoard();
  setKnight(0, 10); setKnight(1, 0); setKnight(3, 17);
  assert(chainAndSet(1));
 }

void test_predicting()                                                          // Test predicting
 {clearBoard();
  int b[$NN] = {
 1,  2,  3,  4,  5, -1, -1, -1,
 6, 64, 63, 12, 25, 34, 15, 38,
 7, 62, 61, 21, 40, 13, 36, 27,
 8, 22,  9, 60, 33, 28, 39, 16,
 9,  7, 59,  1, 20, 41, 54, 29,
-1,  4, 45,  8, 53, 32, 17, 42,
-1, 47,  2, 57, 44, 19, 30, 55,
-1, 58,  5, 46, 31, 56, 43, 18};
  load_fromArray(b);
  say("Predicting");
  printBoard(1121);
  assert(predictRow(0) == 2);
  assert(predictCol(0) == 2);
 }

void say(char *format, ...)                                                     // Say something and carry on
 {va_list p;
  va_start (p, format);
  int i = vfprintf(stderr, format, p);
  assert(i >= 0);
  va_end(p);
  fprintf(stderr, "\\n");
 }

void stop(char *format, ...)                                                    // Say something and stop
 {va_list p;
  va_start (p, format);
  int i = vfprintf(stderr, format, p);
  assert(i > 0);
  va_end(p);
  fprintf(stderr, "\\n");
  exit(1);
 }

int main()
 {say("Version: 17");

  char k2sa[$NN1]; k2s = k2sa;                                                  // Knight(0..63) to square(0..63) in row major order
  char s2ka[$NN1]; s2k = s2ka;                                                  // Square(0..63) in row major order to knight
  short rowSumsa[$N]; rowSums = rowSumsa;                                       // Row sums
  short colSumsa[$N]; colSums = colSumsa;                                       // Col sums

  if ($D)
   {test_unused();
    test_setKnight();
    test_bits();
    test_fill();
    test_chainAndSet();
    test_availableForJumpingTo();
    test_predicting();
   }

  start = clock();

  if (!setjmp(finished))                                                        // Place knights
   {clearBoard();
    load();
    mainLoop();
   }
  printTime();

  return 0;
 }
END

  push @c, <<END if $K;

int main()
 {char k2sa[$NN1]; k2s = k2sa;                                                  // Knight(0..63) to square(0..63) in row major order
  char s2ka[$NN1]; s2k = s2ka;                                                  // Square(0..63) in row major order to knight
  short rowSumsa[$N]; rowSums = rowSumsa;                                       // Row sums
  short colSumsa[$N]; colSums = colSumsa;                                       // Col sums

  if (!setjmp(finished))                                                        // Place knights
   {clearBoard();
    load();
    mainLoop();
   }
  return 0;
 }
END

  join '', @c;
 }

# Create and test the C code

createJumps;                                                                    # Generate code
rowMasks();
colMasks();
mainLoop();

if (1)                                                                          # Modify code for testing or production
 {push @k, &endCode;
  my @K;
  for my $l(map {split /\n/} @k)
   {my $p = index($l, q(//));
    if ($p > 10 and $p < 80)
     {my $n = 80-$p;
      my $spaces = ' ' x $n;
      $l =~ s(//) ($spaces//)s;
     }
    elsif ($p > 79)
     {$l =~ s(\A(.{78})(\s+)//) ($1  //)s;
     }
    push @K, $l;
   }
  my $K = join "\n", @K;                                                        # Write code
     $K =~ s((//D))   ()gs if develop;
     $K =~ s((//.*$)) ()gm if kattis;
     $K =~ s(\n+)   (\n)gs if kattis;
  my $f = owf($outputC, $K);

  my $o = develop ? '' : '-O3';                                                 # Compile
  my $c = qq(gcc $o -Wall -Wextra -I/home/phil/z/c/ -o $program $f && chmod u+x $program);
  unlink $program;
  say STDERR qq($c);
  say STDERR qx($c);

  for my $i(keys @Solutions)                                                    # Test
   {#next unless $i == 2;
    my $solution = $Solutions[$i];
    say STDERR "Test ".($i+1);
    unlink $outputB;

    if (kattis)                                                                 # Create input file
     {my $s = join ' ', map {$_ > Keep ? -1 : $_} @$solution;
      owf($input, $s);
     }
    else
     {owf($input, join ' ', @$solution);
     }

    my $e = qq(./$program < $input > $outputB 2> $outputE);

    my $start = time;
    say STDERR qq($e);
    qx($e );
    my $finish = time;

    if (kattis)
     {confess "Failed test $i on kattis" unless -e $outputB;
      my $r = readFile($outputB);
      say STDERR $r;
      my $s = [split /\s+/s, $r]; shift @$s;
      #say STDERR "AAAA", dump($s)             =~ s(\s) ( )gsr;
      #say STDERR "AAAA", dump($Solutions[$i]) =~ s(\s) ( )gsr;
      confess "Wrong answer" unless dump($s) eq dump($Solutions[$i]);
     }
    else
     {confess "Failed test $i\n" unless readFile($outputE) =~ m(Final board check passed);
     }

    say STDERR sprintf "Finished in %8.4f seconds", $finish - $start;
   }
 }
