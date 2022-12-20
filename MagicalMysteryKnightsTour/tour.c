//------------------------------------------------------------------------------
// 9.6 hard - https://open.kattis.com/problems/magicalmysteryknight
// Depth first search with chain checking
// Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2022
//------------------------------------------------------------------------------
//   2 passed in   0.0203 seconds ++ Reus 3
//   3 passed in   0.0024 seconds ++ Verify
//   4 passed in   0.0022 seconds ++ Reus
//   5 passed in   0.0022 seconds ++ Reus  2
//   6 passed in   0.0024 seconds ++ New 1
//   7 passed in   0.0024 seconds ++ New 1A
//   8 passed in   0.0022 seconds ++ New 2
//  10 passed in   0.0073 seconds ++ New 2A
//  11 passed in   0.0078 seconds ++ 30
//  12 passed in   0.0022 seconds ++ Short
//  15 passed in   0.1335 seconds ++ Right
//  16 passed in   0.0029 seconds ++ Sample
//  18 passed in   0.0687 seconds ++ 48
//  20 passed in   1.7991 seconds ++ 10s 20
//  23 passed in   8.4755 seconds ++ 40s Long

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>
#include <memory.h>
#include <assert.h>
#include <execinfo.h>
#include <setjmp.h>

#define STEPS    1e9                                                            // Maximum number of steps

#define test     000                                                            // Write test output to STDERR if 1
#define profile  0                                                              // Enable profiling
#define develop  0                                                              // Developing
#define testSetK 0                                                              // Write test output to STDERR in setK if 1

#define N  8
#define NN (N*N)
#define NN1 (NN + 1)
#define LINES  999
#define BOARDS 999
#define SUM  (N * NN1 / 2)                                                      // How far to step into a big gap

#define coords2Square(r, c) (N * (r) + (c) + 1)                                 // Coordinates to square

jmp_buf finished;                                                               // This is where we go when we have finished

int SET    = 0;                                                                 // Set number
int STEP   = 0;                                                                 // Number of steps taken
int cR = 0, cC = 0;                                                             // Current coordinates

int bAlloc = 0, bFree = 0, lastReject = 0;

typedef struct Board                                                            // The current state of play on a board
 {char s2k     [NN1];                                                           // For each square numbered from 1-64 the knight on that square or zero if no knight is present
  char k2s     [NN1];                                                           // For each knight numbered from 1-64 the square numbered from 1 to 64 the knight is on or zero if the knight is unassigned
  int rowSum   [N  ];                                                           // Current sum of each row
  int colSum   [N  ];                                                           // Current sum of each column
  int rowCount [N  ];                                                           // Current number of knights in each row
  int colCount [N  ];                                                           // Current number of knights in each column

  int goodRows;                                                                 // Rows that sum correctly
  int goodCols;                                                                 // Columns that sum correctly
  int depth;                                                                    // The copy depth of this board
  int count;                                                                    // The number of knights on the board
  int lowestNotSet;                                                             // The lowest  unset knight on the board
  int highestNotSet;                                                            // The highest unset knight on the board
  struct Board *parent;                                                         // The parent board
  long locations;                                                               // The board represented as 64 bits - a bit is on if there is a knight at that location
  int BoardN;                                                                   // The board represented as 64 bits - a bit is on if there is a knight at that location
 } Board;

Board *WIN = 0, *SOLUTION = 0, *Boards[BOARDS];                                 // The solution if its known
int BoardN = 0;                                                                 // An available board

int  *Jumps[NN1];
long *locations;                                                                // Knight jump possible between these two squares
char *connections;                                                              // Each element is a bit mask showing the possible jumps from that element
void *traceBackconnections;                                                     // Each element is a bit mask showing the possible jumps from that element
#define connectionIndex(a, b) ((a)*NN1+(b))                                     // Index to check the connection between two squares

int line [LINES];                                                               // Profile - hits
int lined[LINES] = {};                                                          // Profile - profiled

void   confess               (int c);
void   check                 ();
int    chainable             (Board *B, int $S, int $K);
int    remainderHigh         (Board *B, int n);
int    remainderLow          (Board *B, int n);
int    chainAndSet           (Board *B, int $S, int $K);
void   printBoard            (Board *B);
void   stop                  (char *c);
void   printProfile          ();
Board *createBoard           ();
void   Board_free            (Board *B);
void   say                   (char * message);
Board *Board_get             ();
Board *Board_clone           (Board *B);
int    placeKnightsByChaining(Board *B);
int    setK                  (Board *B, const int K, const int S, Board **BB);
Board *Board_loadFromArray   (int *);
void print_trace();                                                             // Print trace back

int checkWinner(Board *b)                                                       // Check for a winning configuration
 {if (b->goodRows == N && b->goodCols == N)                                     // A winning board as all the squares are filled
   {WIN = b;
    if (develop) fprintf(stderr, "Winner at step: %d\n", STEP);
    longjmp(finished, 1);                                                       // Found a winner
    return 1;
   }
  return 0;
 }

int stepDown(Board *B, const int K, const int S)                                // Place a knight on a specific square at the next level down
 {Board *b = 0;

  setK(B, K, S, &b);

  if (test && STEP % test == 0) printBoard(B);
//p
  if (b)
   {
//p
//p
    if (test) printBoard(B);
    if (placeKnightsByChaining(b)) return 1;
//p
    Board_free(b);
   }
//p
  return 0;
 }

int setK(Board *B, const int K, const int S, Board **BB)                        // Place a knight on a specific square if we can prove it is safe to do so .  At that point we create a new board and then fill in the consequences
 {++SET;
//p
  if (B->s2k[S] == K)      return 0;                                            // Already set
  if (B->s2k[S] != 0)      return lastReject = 11;                              // Already set to something else
//p
  if (B->k2s[K] != 0)      return 22;                                           // Placement not possible
//p
//  if (!chainable(B, S, K)) return 2;  Works without                           // Impossible to connect with surrounding knights
//p
//    if (s2k[S] == K) return 0;                                                // Just set by chainable
//p
  const int c = (S-1) % N, r = ((S-1) - cC) / N;
//p
  if (K > SUM)
   {//if (B->rowSum[r]) return 3;
    //if (B->colSum[c]) return 4;
    return 3;
   }
//p
  const int re = N   - B->rowCount[r] - 1;                                      // Empty squares in row
//p
  if (re > 0 && re < 5)
   {const int dr = SUM - B->rowSum[r] - K;                                      // How much we have to go
    if (dr > remainderHigh(B, re)) return lastReject = 33;                      // Not possible to fill these slots even if we used the largest possible values - which might already have been taken any way
    if (dr < remainderLow (B, re)) return lastReject = 44;                      // Not possible to fill these slots even if we used the largest possible values - which might already have been taken any way
   }
//p
  const int ce = N   - B->colCount[c] - 1;                                      // Empty squares in row

  if (ce > 0 && ce < 5)
   {const int dc = SUM - B->colSum[c] - K;                                      // How much we have to go
    if (dc > remainderHigh(B, ce)) return lastReject = 55;                      // Not possible to fill these slots even if we used the largest possible values - which might already have been taken any way
    if (dc < remainderLow (B, ce)) return lastReject = 66;                      // Not possible to fill these slots even if we used the largest possible values - which might already have been taken any way
   }
//p
  if (BB != 0)                                                                  // We are going to make a change so do it on a new board preserve
   {B = *BB = Board_clone(B);
   }

  B->s2k[S] = K;
  B->k2s[K] = S;
  ++B->count;                                                                   // We check earlier on that the proposed square is empty
  B->locations |= (1 << S);                                                     // Show square as occupied
  //if (testSetK) fprintf(stderr, "SetKXX: SET %2d K=%2d S=%2d", SET, K, S);

  if (1)
   {int *l = &B->lowestNotSet, *h = &B->highestNotSet;
    for (; *l < NN && B->k2s[*l]; ++*l) {}
    for (; *h > 1  && B->k2s[*h]; ++*h) {}
   }
//p
  B->rowSum[r] += K;  if (B->rowSum[r] == SUM) ++B->goodRows;
  B->colSum[c] += K;  if (B->colSum[c] == SUM) ++B->goodCols;
  int rowReadyForFill = ++B->rowCount[r] == N-1;
  int colReadyForFill = ++B->colCount[c] == N-1;

  if (!BB) return lastReject = 1;                                               // During loading we return here otherwise an attempt is made to solve the board as soon as the first knight is placed.

  const int cs = chainAndSet(B, S, K);                                          // Check surrounding connections
  if (cs == -1) {Board_free(B); *BB = 0; return lastReject = 77;}               // Impossible to connect with surrounding knights so free board and complain
  if (cs ==  1) return 0;                                                       // Success along this path

  if (rowReadyForFill)                                                          // Fill in the current row if possible and check it chains
   {const int k = SUM - B->rowSum[r];

    if (k >= 1 && k <= NN && B->k2s[k] == 0)                                    // In range and knight not otherwise occupied
     {for (int i = 0; i < N; i++)
       {const int s = coords2Square(r, i);
        if (B->s2k[s] == 0)
         {if (stepDown(B, k, s)) return 0;
          else {Board_free(B); *BB = 0; return lastReject = 88;}
//p
         }
       }
     }
   }

  if (colReadyForFill)                                                          // Fill in the current column if possible and check it chains
   {const int k = SUM - B->colSum[c];
    if (k >= 1 && k <= NN && B->k2s[k] == 0)                                                         // In range and knight not otherwise occupied
     {for (int i = 0; i < N; i++)
       {const int s = coords2Square(i, c);
        if (B->s2k[s] == 0)
         {if (stepDown(B, k, s)) return 0;
          else {Board_free(B); *BB = 0; return lastReject = 99;}
//p
         }
       }
     }
   }
//p
  return 0;
 }

int chainAndSet(Board *B, const int $S, const int $K)                           // -1 failed, - do not know, 1 - success: Create chains where possible for the specified knight placed at the specified location. Returns  false only it can be determined that no placement is possible  in this position
 {const int
    k     = $K - 1, K = $K + 1,                                                 // Relative knights
    Bk2sk = B->k2s[k],
    Bk2sK = B->k2s[K],
    f     = k >= 1 && connections[connectionIndex($S, Bk2sk)],                  // Low chain
    F     = K > NN || connections[connectionIndex($S, Bk2sK)];                  // High chain
//fprintf(stderr, "BBBB $K=%d S=%d  f=%d F=%d\n", $K, $S, f, F);
  if ( f &&  F) return 1;                                                       // Chain exists
  if (B->k2s[k] && !f) {lastReject = 1011; return -1;}                           // Chain down should exist but does not
  if (B->k2s[K] && !F) {lastReject = 1022; return -1;}                           // Chain up should exist but does not
//fprintf(stderr, "CCCC\n");
  const int o = __builtin_popcountl(B->locations & locations[$S]);              // The numbered of occupied jumps radiating from this square

  if (!f && !F) return o >= 2;                                                  // Chain does not exist either above or below but there is room for the chain to appear in.

  switch(o)
   {case 0: return 0;                                                           // There are no free slots yet we have on knight to place.
    case 1:                                                                     // There is one free slot with one knight to place  - so we attempt to put the unplaced knight into one empty square
      for (int *j = Jumps[$S]; *j; ++j)
       {if (B->s2k[*j] == 0)
         {if (stepDown(B, f ? K : k, *j)) return 1;                             // Place the one missing knight
          else return -1;                                                       // Could not set free slot so this path is no good
//p
         }
       }
      lastReject = 233;
      stop("Cannot get here because there is only one square");
    return -1;                                                                  // Placement failed to produce a winning board
    case 2: case 3:                                                             // There are a small number of free slots with one knight to place - so try them both
      for (int *j = Jumps[$S]; *j; ++j)
       {if (B->s2k[*j] == 0)
         {if (stepDown(B, f ? K : k, *j)) return 1;                             // Place the one missing knight
//p
         }
       }
      lastReject = 244;
    return 0;                                                                   // Placement failed to produce a winning board
    default: return 0;
   }
 }

int placeKnightsByChaining(Board *B)                                            // Add knights in knight order
 {if (checkWinner(B)) return 1;
//p
  for (int *j = Jumps[(int)B->k2s[B->lowestNotSet-1]]; *j; ++j)
   {if (B->s2k[*j] == 0)
     {
//p
      if (stepDown(B, B->lowestNotSet, *j)) return 1;
//p
     }
   }
  return 0;
 }

int remainderHigh(Board *B, const int n)                                        // Sum remaining high knights
 {int c = 0, s = 0;
  for (int K = B->highestNotSet; K > 0; K--)
   {if (B->k2s[K] == 0) {++c; s += K; if (c == n) return s;}
//p
   }
  return s;
 }

int remainderLow(Board *B, const int n)                                         // Sum remaining low knights
 {int c = 0, s = 0;
  for (int K = B->lowestNotSet; K <= NN; K++)
   {if (B->k2s[K] == 0) {++c; s += K; if (c == n) return s;}
//p
   }
  return s;
 }

char *rowColStatus(Board *B, const int sum, const int e)                        // Show the status of a row or column from its sum and number of empty slots
 {if (sum >  SUM) return ">>>";                                                 // Too much
  if (sum == SUM) return "===";                                                 // Equal
  if (SUM -  sum > remainderHigh(B, e)) return "/.\\";                          // No hope too high
  if (SUM -  sum < remainderLow (B, e)) return "\\./";                          // No hope too low
  return "<<<";                                                                 // In progress
 }

void Boards_init()                                                              // Preallocate the boards
 {for(int i = 0; i < BOARDS; i++)
   {Board *b = Boards[i] = malloc(sizeof(Board)); memset(b, 0, sizeof(Board));
   }
  BoardN = 0;
 }

void Board_free(Board *B)                                                       // Return a board to the stack
 {if (BoardN < 0)
   {stop("Too many boards");
   }
  ++bFree;
  Boards[--BoardN] = B;
 }

Board *Board_get()                                                              // Get a board
 {if (BoardN >= BOARDS)
   {fprintf(stderr, "Out of boards at step %d\n", STEP);
    stop("");
   }
  ++bAlloc;
  Board *b = Boards[BoardN++];
  memset(b, 0, sizeof(Board));
  b->BoardN = BoardN-1;
  return b;
 }

Board *createBoard()                                                            // Get another board from the preallocated stack of boards
 {Board *b = Board_get();
  b->lowestNotSet  = 1;
  b->highestNotSet = NN;
  return b;
 }

Board *Board_clone(Board *B)                                                    // Duplicate a board
 {if (++STEP >= STEPS)                                                          // Stop after too many steps
   {printBoard(B);
    printProfile();
    stop("Out of steps");
   }
//p
  Board *b = Board_get();
  memcpy(b, B, sizeof(Board));
  b->depth  = B->depth + 1;
  b->parent = B;
  b->BoardN = BoardN-1;

  return b;
 }

Board *Board_load()                                                             // Load an initial board
 {int in[NN];
  for   (int i = 0; i < NN; i++) if (scanf("%d", in+i) != 1) stop("Scanf");
  Board *B = createBoard();
  int s = 0;

  for   (int i = 0; i < N; i++)
   {for (int j = 0; j < N; j++)
     {const int k = in[s++];
      if (k > 0) setK(B, k, s, 0);
     }
   }

  for    (int i = 1; i <= NN; i++)
   {const int k = in[i-1];
    if (k > 0 && k != B->s2k[i])
     {printBoard(B);
      stop("Load failed");
     }
   }
  return B;
 }

Board *Board_loadFromArray(int *in)                                             // Load an initial board from an array
 {Board *B = createBoard();
  int s = 0;

  for   (int i = 0; i < N; i++)
   {for (int j = 0; j < N; j++)
     {const int k = in[s++];
      if (k > 0) setK(B, k, s, 0);
     }
   }

  for    (int i = 1; i <= NN; i++)
   {const int k = in[i-1];
    if (k > 0 && k != B->s2k[i])
     {printBoard(B);
      stop("Load failed");
     }
   }
  return B;
 }

void check(Board *B)                                                            // Check a board to confirm that all the knights are on the expected squares and all the squares have the expected knights
 {int count[NN1]; memset(count, 0, sizeof(count));
  for   (int r = 0; r < N; r++)
   {for (int c = 0; c < N; c++)
     {int s = coords2Square(r, c), k = B->s2k[s], S = B->k2s[k];
      if (k > 0 && count[k]++ > 0) stop("Duplicate knight");
      if (k > 0 && s != S)
       {fprintf(stderr, "knight: %2d square %2d Square %2d row %2d col %2d",
                         k,          s,         S,         r,      c);
        printBoard(B); stop("Check");
       }
     }
   }
 }

void walkBoard(Board *B)                                                        // Walk through the board from one to lowest not set
 {for(int $K = 2; $K < B->lowestNotSet; $K++)
   {const int S = B->k2s[$K], k = $K - 1, K = $K + 1;                           // Relative knights
    int e = 0;                                                                  // Empty square if just one
    int f = 0, F = K <= NN;                                                     // The knights found
    const int *J = Jumps[S];
    for (int i = 0; i < N; ++i)
     {const int s = J[i];
      if (s == 0) break;
      const int $k = B->s2k[s];
      if      ($k == 0) ++e;
      else if ($k == k) f = 1;
      else if ($k == K) F = 1;
     }
//fprintf(stderr, "BBBB $K=", $K,  "k=", k,  "K=", K, "S=", S, "e=", e, "es=", es, "f", f, "F", F);

    if (f && F) continue;                                                       // Chain exists

    if (e == 0 || (e == 1 && !f && !F))                                         // It would not be possible to create a chain under these circumstances as there is no room for the missing knights
     {printBoard(B);
      printBoard(B->parent);
      printBoard(B->parent->parent);
      stop("Chain failed");
     }
   }
 }

void printBoard(Board *B)                                                       // Print the board as an array
 {fprintf(stderr, "Step: %2d  Depth: %2d Count: %2d LowestNotSet: %2d HighestNotSet: %2d LastReject: %2d GoodRows: %4d GoodCols: %2d Delta: %2d  Alloc: %8d Free: %8d\n",
                   STEP,      B->depth,  B->count,  B->lowestNotSet,  B->highestNotSet,  lastReject, B->goodRows,  B->goodCols,  bAlloc - B->depth - bFree, bAlloc, bFree);

  fprintf(stderr, "   ");
  for (int $c = 0; $c < N; $c++)                                                // Column headers
   {fprintf(stderr, "  %d ", $c+1);
   }
  fprintf(stderr, "\n");

  for (int r = 0; r < N; r++)                                                   // Print each row
   {fprintf(stderr, "%2d  ", r*N);
    for (int c = 0; c < N; c++)                                                 // Column in row
     {const int s = coords2Square(r, c);                                        // Square
      const int k = B->s2k[s];                                                  // Knight
      if (k != 0)
       {if (SOLUTION != 0)
         {if (SOLUTION->s2k[s] == k) fprintf(stderr, "| %2d", k);
          else                       fprintf(stderr, "|*%2d", k);
         }
        else fprintf(stderr, "| %2d", k);
       }
      else
       {fprintf(stderr, "| . ");
       }
     }
    fprintf(stderr, "| %4d", B->rowSum[r]);                                     // Row sum
    fprintf(stderr, " %s\n", rowColStatus(B, B->rowSum[r], N-B->rowCount[r]));  // Row status
   }

  fprintf(stderr, "    ");
  for (int c = 0; c < N; c++)                                                   // Print footer sums
   {fprintf(stderr, "|%3d", B->colSum[c]);                                      // Column sum
   }
  fprintf(stderr, "\n");

  fprintf(stderr, "    ");
  for (int c = 0; c < N; c++)                                                   // Print footer comments
   {fprintf(stderr, "|%s", rowColStatus(B, B->colSum[c], N-B->colCount[c]));    // Column status
   }
  fprintf(stderr, "\n");
 }

void printWinningBoard(Board *B)                                                // Print a winning board
 {for (int r = 0; r < N; r++)                                                   // Print each row
   {for (int c = 0; c < N; c++)                                                 // Column in row
     {const int s = B->s2k[coords2Square(r, c)];                                // Square
      if (c == 0) fprintf(stdout, "%2d",  s);
      else        fprintf(stdout, " %2d", s);
     }
    fprintf(stdout, "\n");
   }
 }


int *jumpsFromSquare(int s)                                                     // Jumps from a square
 {const int c = (s-1) % N, r = ((s-1) - cC) / N;
  int *j = malloc((N+1) * sizeof(int));
  for(int i = 0; i < N + 1; ++i) j[i] = 0;

  int i = 0;
  if (r >= 2     && c >= 1    ) j[i++] = coords2Square(r-2, c-1);
  if (r >= 1     && c >= 2    ) j[i++] = coords2Square(r-1, c-2);

  if (r < N - 1  && c <  N - 2) j[i++] = coords2Square(r+1, c+2);
  if (r < N - 2  && c <  N - 1) j[i++] = coords2Square(r+2, c+1);

  if (r >= 1     && c <  N - 2) j[i++] = coords2Square(r-1, c+2);
  if (r >= 2     && c <  N - 1) j[i++] = coords2Square(r-2, c+1);

  if (r < N - 1  && c >= 2    ) j[i++] = coords2Square(r+1, c-2);
  if (r < N - 2  && c >= 1    ) j[i++] = coords2Square(r+2, c-1);
  return j;
 }

void Jumps_init()
 {for (int i = 0; i <= NN; i++) Jumps[i] = 0;
  for (int i = 1; i <= NN; i++)                                                 // Jumps from each square
   {Jumps[i] = jumpsFromSquare(i);
   }

  if (1)                                                                        // Squares connected by jumps
   {const int size = (NN1)*(NN1)*sizeof(char);
    connections    = malloc(size);
    memset(connections, 0, size);
    for  (int i = 1; i <= NN; i++)
     {for(int *j = Jumps[i]; *j; ++j)
       {int c1 = connectionIndex(i, *j);
        int c2 = connectionIndex(*j, i);
        connections[c1] = 1;
        connections[c2] = 1;
       }
     }
   }

  if (1)                                                                        // Squares connected by jumps
   {const int size = NN1*sizeof(long);
    locations      = malloc(size);
    memset(locations, 0, size);
    for  (int i = 1; i <= NN; i++)
     {for(int *j = Jumps[i]; *j; ++j)
       {locations[i] |= 1 << *j;
       }
     }
   }
 }

void printProfile()                                                             // Print the execution profile
 {if (!profile) return;
  fprintf(stderr, "Hits\n");
  for (int i = 0; i < LINES; i++)
   {if (line[i] != 0)
     {fprintf(stderr, "%4d  %12d\n", i, line[i]);
     }
   }
  if (lined != 0)
   {fprintf(stderr, "Misses");
    for (int i = 0; i < LINES; i++)
     {if (lined[i] && line[lined[i]] == 0) fprintf(stderr, " %3d", lined[i]);
     }
    fprintf(stderr, "\n");
   }
 }

void say(char * message)                                                        // Trace back
 {fprintf(stderr, "%s\n", message);
 }

void print_trace()                                                              // Print trace back
 {const int traces = 999;
  void *array[traces];
  char **strings;
  int size, i;

  size = backtrace (array, traces);
  strings = backtrace_symbols (array, size);
  if (strings != 0)
   {printf ("Obtained %d stack frames.\n", size);
    for (i = 0; i < size; i++) printf ("%s\n", strings[i]);
   }
  free (strings);
 }

void stop(char * message)                                                       // Trace back
 {//print_trace();
  say(message);
  exit(1);
 }

void confess(int condition)                                                     // Confess to something bad
 {if (condition) return;
  stop("Confess");
 }

int main()
 {Jumps_init();
  Boards_init();
//  int solution[NN] = {
//50, 11, 24, 63, 14, 37, 26, 35,
//23, 62, 51, 12, 25, 34, 15, 38,
//10, 49, 64, 21, 40, 13, 36, 27,
//61, 22,  9, 52, 33, 28, 39, 16,
//48,  7, 60,  1, 20, 41, 54, 29,
//59,  4, 45,  8, 53, 32, 17, 42,
// 6, 47,  2, 57, 44, 19, 30, 55,
// 3, 58,  5, 46, 31, 56, 43, 18
//};

//  SOLUTION = Board_loadFromArray(solution);

  Board *B = Board_load();                                                      // Create the board

  if (!setjmp(finished))
   {placeKnightsByChaining(B);                                                  // Chain through
   }

  if (WIN != 0) printWinningBoard(WIN);                                         // Print results

  if (develop)
   {fprintf(stderr, "Steps=%d LastReject=%d\n", STEP, lastReject);

    if (WIN != 0) printBoard(WIN);
    else say("No solution found");
    printProfile();
   }
  return 0;
 }

//TEST Verify
/*
50 11 24 63 14 37 26 35
23 62 51 12 25 34 15 38
10 49 64 21 40 13 36 27
61 22  9 52 33 28 39 16
48  7 60  1 20 41 54 29
59  4 45  8 53 32 17 42
 6 47  2 57 44 19 30 55
 3 58  5 46 31 56 43 18
----
50 11 24 63 14 37 26 35
23 62 51 12 25 34 15 38
10 49 64 21 40 13 36 27
61 22  9 52 33 28 39 16
48  7 60  1 20 41 54 29
59  4 45  8 53 32 17 42
 6 47  2 57 44 19 30 55
 3 58  5 46 31 56 43 18
*/

//TEST Reus 3
/*
 2 39 58 31 -1 -1 -1 -1
59 30  3 40 -1 -1 -1 -1
38  1 32 57 -1 -1 -1 -1
29 60 37 -1 -1 -1 -1 -1
64  5 28 33 -1 -1 -1 -1
27 36 61 -1 -1 -1 -1 -1
 6 63 34 25 -1 -1 -1 -1
35 26  7 62 -1 -1 -1 -1
----
 2 39 58 31 18 15 54 43
59 30  3 40 55 42 17 14
38  1 32 57 16 19 44 53
29 60 37  4 41 56 13 20
64  5 28 33 24 11 50 45
27 36 61  8 49 46 21 12
 6 63 34 25 52 23 10 47
35 26  7 62  9 48 51 22
----
 2 39 58 31 56 41 18 15
59 30  3 40 17 14 55 42
38  1 32 57 54 43 16 19
29 60 37  4 13 20 53 44
64  5 28 33 52 45 12 21
27 36 61  8 11 22 49 46
 6 63 34 25 48 51 10 23
35 26  7 62  9 24 47 50
----
 2 39 58 31 56 41 18 15
59 30  3 40 17 14 43 54
38  1 32 57 42 55 16 19
29 60 37  4 13 20 53 44
64  5 28 33 52 45 12 21
27 36 61  8 23 10 49 46
 6 63 34 25 48 51 22 11
35 26  7 62  9 24 47 50
*/

//TEST Short
/*
50 11 24 63 14 37 26 35
23 62 51 12 25 34 15 38
10 49 64 21 40 13 36 27
61 22  9 52 33 28 39 16
48  7 60  1 20 41 54 29
59  4 45  8 53 32 17 42
-1 -1 -1 57 44 19 30 55
-1 -1 -1 46 31 56 43 18
----
50 11 24 63 14 37 26 35
23 62 51 12 25 34 15 38
10 49 64 21 40 13 36 27
61 22  9 52 33 28 39 16
48  7 60  1 20 41 54 29
59  4 45  8 53 32 17 42
 6 47  2 57 44 19 30 55
 3 58  5 46 31 56 43 18
*/

//TEST Not long
/*
50 11 24 63 14 37 26 35
23 62 51 12 25 34 15 38
-1 -1 -1 21 40 13 36 27
-1 -1 -1 52 33 28 39 16
-1 -1 -1  1 20 41 54 29
-1 -1 -1  8 53 32 17 42
-1 -1 -1 57 44 19 30 55
-1 -1 -1 46 31 56 43 18
----
50 11 24 63 14 37 26 35
23 62 51 12 25 34 15 38
10 49 64 21 40 13 36 27
61 22  9 52 33 28 39 16
48  7 60  1 20 41 54 29
59  4 45  8 53 32 17 42
 6 47  2 57 44 19 30 55
 3 58  5 46 31 56 43 18
*/

//TEST Sample
/*
 1 48 -1 -1 33 -1 63 18
30 51 -1  3 -1 -1 -1 -1
-1 -1 -1 -1 15 -1 -1 -1
-1 -1 -1 45 -1 -1 36 -1
-1 -1 25 -1  9 -1 21 60
-1 -1 -1 -1 24 57 12 -1
-1  6 -1 -1 39 -1 -1 -1
54 -1 42 -1 -1 -1 -1 -1
----
 1 48 31 50 33 16 63 18
30 51 46  3 62 19 14 35
47  2 49 32 15 34 17 64
52 29  4 45 20 61 36 13
 5 44 25 56  9 40 21 60
28 53  8 41 24 57 12 37
43  6 55 26 39 10 59 22
54 27 42  7 58 23 38 11
*/

//TEST Reus
/*
 2 39 58 31 56 41 18 15
59 30  3 40 17 14 43 54
38  1 32 57 42 55 16 19
29 60 37  4 13 20 53 44
64  5 28 33 52 45 12 21
27 36 61  8 23 10 49 46
 6 63 34 25 48 51 22 11
35 26  7 62  9 24 47 50
----
 2 39 58 31 56 41 18 15
59 30  3 40 17 14 43 54
38  1 32 57 42 55 16 19
29 60 37  4 13 20 53 44
64  5 28 33 52 45 12 21
27 36 61  8 23 10 49 46
 6 63 34 25 48 51 22 11
35 26  7 62  9 24 47 50
*/

//TEST Reus  2
/*
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
38  1 32 57 42 55 16 19
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
 6 63 34 25 48 51 22 11
35 26  7 62  9 24 47 50
----
 2 39 58 31 56 41 18 15
59 30  3 40 17 14 43 54
38  1 32 57 42 55 16 19
29 60 37  4 13 20 53 44
64  5 28 33 52 45 12 21
27 36 61  8 23 10 49 46
 6 63 34 25 48 51 22 11
35 26  7 62  9 24 47 50
*/

//TEST New 1
/*
26  7 40 59 10 15 42 61
39 58 27  8 41 60 11 16
 6 25 64 37 14  9 62 43
57 38  1 28 63 44 17 12
24  5 56 51 36 13 30 45
55 50 21  2 29 52 33 18
 4 23 48 53 20 35 46 31
49 54  3 22 47 32 19 34
----
26  7 40 59 10 15 42 61
39 58 27  8 41 60 11 16
 6 25 64 37 14  9 62 43
57 38  1 28 63 44 17 12
24  5 56 51 36 13 30 45
55 50 21  2 29 52 33 18
 4 23 48 53 20 35 46 31
49 54  3 22 47 32 19 34
*/

//TEST New 1A
/*
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
57 38  1 28 63 44 17 12
24  5 56 51 36 13 30 45
55 50 21  2 29 52 33 18
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
----
26  7 40 59 10 15 42 61
39 58 27  8 41 60 11 16
 6 25 64 37 14  9 62 43
57 38  1 28 63 44 17 12
24  5 56 51 36 13 30 45
55 50 21  2 29 52 33 18
 4 23 48 53 20 35 46 31
49 54  3 22 47 32 19 34
*/

//TEST New 2
/*
 3 22 49 56  5 20 47 58
50 55  4 21 48 57  6 19
23  2 53 44 25  8 59 46
54 51 24  1 60 45 18  7
15 36 43 52 17 26  9 62
42 39 16 33 12 61 30 27
35 14 37 40 29 32 63 10
38 41 34 13 64 11 28 31
----
 3 22 49 56  5 20 47 58
50 55  4 21 48 57  6 19
23  2 53 44 25  8 59 46
54 51 24  1 60 45 18  7
15 36 43 52 17 26  9 62
42 39 16 33 12 61 30 27
35 14 37 40 29 32 63 10
38 41 34 13 64 11 28 31
*/

//TEST --skip New 2A
/*
-1 -1 -1 -1 -1 -1 -1 -1
50 55  4 21 48 57  6 19
23  2 53 44 25  8 59 46
54 51 24  1 60 45 18  7
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
----
 3 22 49 56  5 20 47 58
50 55  4 21 48 57  6 19
23  2 53 44 25  8 59 46
54 51 24  1 60 45 18  7
43 36 13 52 17 26  9 62
14 39 34 41 12 61 30 27
35 42 37 16 29 32 63 10
38 15 40 33 64 11 28 31
*/

//TEST New 2A
/*
-1 -1 -1 -1 -1 -1 -1 -1
50 55  4 21 48 57  6 19
23  2 53 44 25  8 59 46
54 51 24  1 60 45 18  7
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
----
 3 22 49 56  5 20 47 58
50 55  4 21 48 57  6 19
23  2 53 44 25  8 59 46
54 51 24  1 60 45 18  7
15 36 43 52 17 26  9 62
42 39 16 33 12 61 30 27
35 14 37 40 29 32 63 10
38 41 34 13 64 11 28 31
*/

//TEST 30
/*
 1 -1 -1 -1 -1 16 -1 18
30 -1 -1  3 -1 19 14 -1
-1  2 -1 -1 15 -1 17 -1
-1 29  4 -1 20 -1 -1 13
 5 -1 25 -1  9 -1 21 -1
28 -1  8 -1 24 -1 12 -1
-1  6 -1 26 -1 10 -1 22
-1 27 -1  7 -1 23 -1 11
----
 1 48 31 50 33 16 63 18
30 51 46  3 62 19 14 35
47  2 49 32 15 34 17 64
52 29  4 45 20 61 36 13
 5 44 25 56  9 40 21 60
28 53  8 41 24 57 12 37
43  6 55 26 39 10 59 22
54 27 42  7 58 23 38 11
*/

//TEST Right
/*
 1 48 -1 -1 -1 -1 63 18
30 51 -1 -1 -1 -1 14 35
47 -1 -1 -1 -1 -1 17 64
-1 -1 -1 -1 -1 -1 36 13
-1 -1 -1 -1 -1 -1 21 60
-1 -1 -1 -1 -1 -1 12 37
-1 -1 -1 -1 -1 -1 59 22
-1 -1 -1 -1 -1 -1 38 11
----
 1 48 31 50 33 16 63 18
30 51 46  3 62 19 14 35
47  2 49 32 15 34 17 64
52 29  4 45 20 61 36 13
 7 44 25 40  5 58 21 60
28 53  6 57 24 39 12 37
43  8 55 26 41 10 59 22
54 27 42  9 56 23 38 11
----
 1 48 31 50 33 16 63 18
30 51  2 45 62 19 14 35
47  4 49 32 15 34 17 64
52 29 46  3 20 61 36 13
27 42  5 56  9 40 21 60
 6 53 28 41 24 57 12 37
43 26 55  8 39 10 59 22
54  7 44 25 58 23 38 11
----
 1 48 31 50 33 16 63 18
30 51 46  3 62 19 14 35
47  2 49 32 15 34 17 64
52 29  4 45 20 61 36 13
 5 44 25 56  9 40 21 60
28 53  8 41 24 57 12 37
43  6 55 26 39 10 59 22
54 27 42  7 58 23 38 11
*/

//TEST 48
/*
 1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
-1 -1 -1 -1 -1 -1 -1 -1
43  6 55 26 39 10 59 22
54 27 42  7 58 23 38 11
----
 1 48 31 50 33 16 63 18
30 51 46  3 62 19 14 35
47  2 49 32 15 34 17 64
52 29  4 45 20 61 36 13
 5 44 25 56  9 40 21 60
28 53  8 41 24 57 12 37
43  6 55 26 39 10 59 22
54 27 42  7 58 23 38 11
----
 1 46 49 32 15 34 63 20
30 51  2 47 64 19 14 35
45  4 31 50 33 16 21 60
52 29 48  3 18 61 36 13
 5 44 25 56  9 40 17 62
28 53  8 41 24 57 12 37
43  6 55 26 39 10 59 22
54 27 42  7 58 23 38 11
*/

//TEST --skip 10s 20
/*
 1 -1 -1 -1 -1 16 -1 18
-1 -1 -1  3 -1 19 14 -1
-1  2 -1 -1 15 -1 17 -1
-1 -1  4 -1 20 -1 -1 13
 5 -1 -1 -1  9 -1 -1 -1
-1 -1  8 -1 -1 -1 12 -1
-1  6 -1 -1 -1 10 -1 -1
-1 -1 -1  7 -1 -1 -1 11
----
*/

//TEST 10s 20
/*
 1 -1 -1 -1 -1 16 -1 18
-1 -1 -1  3 -1 19 14 -1
-1  2 -1 -1 15 -1 17 -1
-1 -1  4 -1 20 -1 -1 13
 5 -1 -1 -1  9 -1 -1 -1
-1 -1  8 -1 -1 -1 12 -1
-1  6 -1 -1 -1 10 -1 -1
-1 -1 -1  7 -1 -1 -1 11
----
 1 48 31 50 33 16 63 18
30 51 46  3 62 19 14 35
47  2 49 32 15 34 17 64
52 29  4 45 20 61 36 13
 5 44 25 56  9 40 21 60
28 53  8 41 24 57 12 37
43  6 55 26 39 10 59 22
54 27 42  7 58 23 38 11
---
 1 48 35 54 37 16 51 18
34 55 46  3 50 19 14 39
47  2 49 36 15 38 17 56
52 33  4 45 20 53 40 13
 5 26 63 32  9 44 21 60
64 29  8 25 58 23 12 41
27  6 31 62 43 10 59 22
30 61 28  7 24 57 42 11
*/

//TEST --skip 19 runs out
/*
 1 -1 -1 -1 -1 16 -1 18
-1 -1 -1  3 -1 19 14 -1
-1  2 -1 -1 15 -1 17 -1
-1 -1  4 -1 -1 -1 -1 13
 5 -1 -1 -1  9 -1 -1 -1
-1 -1  8 -1 -1 -1 12 -1
-1  6 -1 -1 -1 10 -1 -1
-1 -1 -1  7 -1 -1 -1 11
----
 1 48 31 50 33 16 63 18
30 51 46  3 62 19 14 35
47  2 49 32 15 34 17 64
52 29  4 45 20 61 36 13
 5 44 25 56  9 40 21 60
28 53  8 41 24 57 12 37
43  6 55 26 39 10 59 22
54 27 42  7 58 23 38 11
*/

//TEST --skip 40s Long
/*
 1 48 -1 -1 -1 -1 -1 -1
30 51 -1 -1 -1 -1 -1 -1
47  2 -1 -1 -1 -1 -1 -1
52 29 -1 -1 -1 -1 -1 -1
 5 44 -1 -1 -1 -1 -1 -1
28 53  8 -1 -1 -1 -1 -1
43  6 55 -1 -1 -1 -1 -1
54 27 42 -1 -1 -1 -1 -1
----
 1 48 49 32 63 34 19 14
30 51 46  3 18 13 62 35
47  2 31 56 33 64 15 20
52 29  4 45 12 17 36 59
 5 44 25 50 61 38 21 16
28 53  8 41 24 11 58 37
43  6 55 26  9 60 39 22
54 27 42  7 40 23 10 57
*/

//TEST 40s Long
/*
 1 48 -1 -1 -1 -1 -1 -1
30 51 -1 -1 -1 -1 -1 -1
47  2 -1 -1 -1 -1 -1 -1
52 29 -1 -1 -1 -1 -1 -1
 5 44 -1 -1 -1 -1 -1 -1
28 53  8 -1 -1 -1 -1 -1
43  6 55 -1 -1 -1 -1 -1
54 27 42 -1 -1 -1 -1 -1
----
 1 48 31 50 33 16 63 18
30 51 46  3 62 19 14 35
47  2 49 32 15 34 17 64
52 29  4 45 20 61 36 13
 5 44 25 56  9 40 21 60
28 53  8 41 24 57 12 37
43  6 55 26 39 10 59 22
54 27 42  7 58 23 38 11
*/
