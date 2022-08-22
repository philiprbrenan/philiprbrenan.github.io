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
my $repo = q(philiprbrenan.github.io);                                          # Store code here so it can be referenced from a browser
my $Repo = q(javascript);                                                       # Store code here for general reference
my $wf   = q(.github/workflows/main.yml);                                       # Work flow on Ubuntu

push my @files, searchDirectoryTreesForMatchingFiles($home);                    # Files

for my $s(@files)                                                               # Upload each selected file
 {my $p = readFile($s);                                                         # Load file
  if ($s !~ m(README))                                                          # Github as a web server
   {my $t = swapFilePrefix($s, $home, q(js/));
    my $w = writeFileUsingSavedToken($user, $repo, $t, $p);
    lll "$w $s $t";
   }
  if (1)                                                                        # Github as a code repo
   {my $t = swapFilePrefix($s, $home);
    my $w = writeFileUsingSavedToken($user, $Repo, $t, $p);
    lll "$w $s $t";
   }
 }

my $y = <<'END';
# Test

name: Test

on:
  push

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v2
      with:
        ref: 'main'

    - name: Nodejs
      run: |
        sudo apt install nodejs

    - name: Run
      run: |
        nodejs js/basics.js
        nodejs js/Map/test.js
        cd js/Map
        nodejs test.js
END

lll "Ubuntu work flow for $repo ", writeFileUsingSavedToken($user, $repo, $wf, $y);

$y =~ s(js/) ()gs;

lll "Ubuntu work flow for $Repo ", writeFileUsingSavedToken($user, $Repo, $wf, $y);
