#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Push Btree presntation to GitHub
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2025
#-------------------------------------------------------------------------------
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use GitHub::Crud qw(:all);
use feature qw(say current_sub);

my $home    = q(/home/phil/btreeBlock/presentation/);                           # Home folder
my $outHtml = q(/home/phil/btreeBlock/presentation/index.html);                 # Output html
my $shaFile = q(/home/phil/btreeBlock/presentation/.shaFile);                   # File shas
my $user    = q(philiprbrenan);                                                 # User
my $repo    = q(philiprbrenan.github.io);                                       # Repo
my $dir     = q(zesal/presentation);                                            # Work flow on Ubuntu
my @ext     = qw(.htm .jpg .pl);                                                # Extensions of files to upload to github

say STDERR timeStamp,  " Push presentation to github $repo";

push my @files, searchDirectoryTreesForMatchingFiles($home, @ext);              # Files to upload

if (1)                                                                          # Remove most of the verilog except the reports
 {my @f = @files; @files = ();
  for my $f(@f)
   {next if $f =~ m(verilog) and $f !~ m(/vivado/reports/);
    push @files, $f;
   }
 }

@files = changedFiles $shaFile, @files if 1;                                    # Filter out files that have not changed

for my $s(@files)                                                               # Upload each selected file
 {my $c = readBinaryFile $s;                                                    # Load file

  if ($s =~ m(index)i)                                                          # Expand Index.htm
   {$c = expandWellKnownWordsAsUrlsInHtmlFormat $c;
    owf($outHtml, $c);
   }

  my $t = fpf $dir, swapFilePrefix $s, $home;                                   # File on github
  my $w = writeFileUsingSavedToken($user, $repo, $t, $c);                       # Write file into github
  lll "$w  $t";
 }
