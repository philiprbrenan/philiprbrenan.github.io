#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Animals from Ana 2024-01-31
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2024
#-------------------------------------------------------------------------------
use v5.34;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);

my $title    = "Animals";                                                       # Title
my $home     = "/home/phil/z/spanish/animals/";                                 # Home folder
my $audioX   = "wav";                                                           # Audio extension
my $imagesPL = 6;                                                               # Images per line
my $index    = fpe $home, qw(animals html);                                     # English index
my $script   = fpe $home, qw(zzz     html);                                     # Audio script
my $aTitle   = fpe $home, $title, $audioX;                                      # Main title sequence
owf($aTitle, '') unless -e $aTitle;

sub enFromPhoto($)                                                              # English name from photo
 {my ($photo) = @_;                                                             # Photo file name
  fn $photo
 }

my %es = (
    "bear"     => "oso",
    "bird"     => "pajaro",
    "cat"      => "gato",
    "cow"      => "vaca",
    "donkey"   => "burro",
    "giraffe"  => "jirafa",
    "hen"      => "gallina",
    "horse"    => "caballo",
    "mouse"    => "raton",
    "pig"      => "cerdo",
    "rhino"    => "rinoceronte",
    "sheep"    => "oveja",
    "tiger"    => "tigre",
    "zebra"    => "cebra",
);

sub esFromPhoto($)                                                              # Spanish name from photo
 {my ($photo) = @_;                                                             # Photo file name
  $es{fn $photo}
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
  .thing {font-weight: bold; font-family: "Century Gothic", serif; font-size:200%;}
  td {text-align: center;}
  .english, .spanish {display: block;}
  .hidden            {display: none; }
</style>
<body>
<h1 onclick="playTitle.play()">$title</h1>

<p>Click on the words to hear them in English.  Show words in:
<input checked="1" type="checkbox" id="toggleEn">English
<input checked="1" type="checkbox" id="toggleEs">Spanish

<audio id="playTitle" src="$title.$audioX"></audio>
<table border="0" cellpadding="10">
END

for my $i(keys @p)                                                              # Images
 {my $p = fne $p[$i];
  my $e = enFromPhoto $p;
  my $s = esFromPhoto($p) =~ s(_) ( )gsr;
  my $n = $e =~ s(_) ( )gsr;
  push @h, "  <tr>" unless $i % $imagesPL;
  push @h, <<END;
    <td onclick="play$e.play()"><img src="$p"><p class="thing en">$n<p class="es">$s
    <audio   id="play$e"             src="$e.$audioX"></audio>
END
 }

push @h, <<END;
</table>
END

push @h, <<END;                                                                 # Instructions
<script>
function tEn() {
  document.querySelectorAll('.en').forEach(function(element) {if (!toggleEn.checked)    {element.classList.add('hidden')} else {element.classList.remove('hidden')}})
}
function tEs() {
  document.querySelectorAll('.es').forEach(function(element) {if (!toggleEs.checked)    {element.classList.add('hidden')} else {element.classList.remove('hidden')}})
}

toggleEn.addEventListener('change', tEn); tEn()
toggleEs.addEventListener('change', tEs); tEs()
</script>
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
</table>
</body>
</html>
END

owf($script, join "\n", @s);                                                    # Write script

for my $p(@p)                                                                   # Audio
 {my $n = enFromPhoto($p);
  my $s = esFromPhoto($p);
  push @s, "<tr><th>$s<td>$n<td>$n<td>$n"
 }

push @s, <<END;
</table>
</body>
</html>
END

owf($script, join "\n", @s);                                                    # Write script

#owf($script, join "\n", map {enFromPhoto($_)} @p);                              # Write script
