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
my $wf   = q(.github/workflows/main.yml);                                       # Work flow on Ubuntu

push my @files, searchDirectoryTreesForMatchingFiles($home);                    # Files

for my $s(@files)                                                               # Upload each selected file
 {my $t = swapFilePrefix($s, $home, q(js/));                                    # Position file in repo
  my $p = readFile($s);                                                         # Load file
  my $w = writeFileUsingSavedToken($user, $repo, $t, $p);                       # Write file to github
  lll "$w $s $t";
 }

my $y = <<'END';
# Test

name: Test

on:
  push

jobs:
  test00:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
      with:
        ref: 'main'

    - name: Run
      run: |
        cd js/Map
        nodejs test.js
END

lll "Ubuntu work flow for $repo ", writeFileUsingSavedToken($user, $repo, $wf, $y);
