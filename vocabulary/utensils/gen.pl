#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Utensils. Small photos so clicking on them says their name.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2024
#-------------------------------------------------------------------------------
use v5.34;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
eval "use Test::More qw(no_plan);" unless caller;

my $title    = "Kitchen_Utensils";                                              # Title
my $home     = "/home/phil/z/spanish/utensils/";                                # Home folder
my $audioX   = "wav";                                                           # Audio extension
my $imagesPL = 6;                                                               # Images per line
my $index    = fpe $home, qw(utensils html);                                    # English index
my $script   = fpe $home, qw(script  html);                                     # Audio script
my $aTitle   = fpe $home, $title, $audioX;                                      # Main title sequence
owf($aTitle, '') unless -e $aTitle;
my $Title    = $title =~ s(_) ( )gsr;                                           # Title as written

sub enFromPhoto($)                                                              # English name from photo
 {my ($photo) = @_;                                                             # Photo file name
  [split /\|/, fn $photo]->[1]
 }

sub esFromPhoto($)                                                              # Spanish name from photo
 {my ($photo) = @_;                                                             # Photo file name
  [split /\|/, fn $photo]->[0]
 }

my @p = searchDirectoryTreesForMatchingFiles $home, qw(.png .jpg);              # Get photos

for my $f(@p)
 {my $a = fpe $home, enFromPhoto($f), $audioX;                                  # Audio file
  owf $a, '' unless -e $a;                                                      # Spanish | English audio
 }

my @h = <<END;                                                                  # Heading html
<!DOCTYPE html>
<html>
<style>
  body{margin: 1% 10% 1% 10%;}
  img {width : 100%; height: auto;}
  .thing {font-weight: bold;}
  td {text-align: center;}
</style>
<body>
<h1 onclick="playTitle.play()">$Title</h1>
<audio id="playTitle" src="$title.$audioX"></audio>
<table border="0" cellpadding="10">
END

for my $i(keys @p)                                                              # Images
 {my $p = fne $p[$i];
  my $e = enFromPhoto($p);
  my $s = esFromPhoto($p);
  my $n = $e =~ s(_) ( )gsr;
  push @h, "  <tr>" unless $i % $imagesPL;
  push @h, <<END;
    <td onclick="play$e.play()"><img src="$p"><p class="thing">$n<p>$s
    <audio   id="play$e"             src="$e.$audioX"></audio>
END
 }

push @h, <<END;
</table>
END

push @h, <<END;                                                                 # Instructions
<p>Click on the words and pictures to hear them.
</body>
</html>
END

owf($index, join "", @h);                                                       # Write html

push my @s, <<END;                                                              # Audio script
<h1>$title</h1>
<table cellpadding=5>
END

for my $p(@p)                                                                   # Audio
 {my $n = enFromPhoto($p);
  my $s = esFromPhoto($p);
  push @s, "<tr><th>$s<td>$n<td>$n<td>$n"
 }

push @s, <<END;
</ol>
END

owf($script, join "\n", @s);                                                    # Write script
