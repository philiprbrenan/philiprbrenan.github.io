#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/ -I/home/phil/perl/cpan/GitHubCrud/lib/
#-------------------------------------------------------------------------------
# Push JavaScript to GitHub to make it visible in any browser
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2022
#-------------------------------------------------------------------------------
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use GitHub::Crud qw(:all);
use feature qw(say current_sub);

my $home = q(/home/phil/z/js/);                                                 # Local files
my $user = q(philiprbrenan);                                                    # User
my $repo = q(philiprbrenan.github.io);                                          # Repo

push my @files, searchDirectoryTreesForMatchingFiles($home);                    # Files

for my $s(@files)                                                               # Upload each selected file
 {my $t = swapFilePrefix($s, $home, q(js/));                                    # Position file in repo
  my $p = readFile($s);                                                         # Load file
  my $w = writeFileUsingSavedToken($user, $repo, $t, $p);                       # Write file to github
  lll "$w $s $t";
 }
