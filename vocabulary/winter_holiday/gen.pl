#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Winter holiday
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2024
#-------------------------------------------------------------------------------
use v5.34;
use warnings FATAL => qw(all);
use strict;
use Carp;
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use utf8;

my $title     = "Winter_Holiday";                                               # Title
my $home      = "/home/phil/z/vocabulary/winter_holiday/";                      # Home folder
my $audioX    = "wav";                                                          # Audio extension
my $imagesPL  = 6;                                                              # Images per line
my $index     = fpe $home, qw(index html);                                      # English index
my $script    = fpe $home, qw(zScript html);                                    # Audio script
my $translate = fpe $home, qw(zTranslate txt);                                  # Words to be translated by chat gpt
my $list      = fpe $home, qw(zList      txt);                                  # Words to be listed
my $aTitle    = fpe $home, $title, $audioX;                                     # Main title sequence
my %audio;                                                                      # Audio files corresponding to photgraphs
my %translate;                                                                  # Translations still needed

owf($aTitle, '') unless -e $aTitle;

sub spaces($)                                                                   # Convert _ to space
 {my ($string) = @_;
  $string =~ s(_) ( )gsr
 }

sub enFromPhoto($)                                                              # English name from photo
 {my ($photo) = @_;                                                             # Photo file name
  fn $photo
 }

my %es = (                                                                      # Spanish
    "barn"           => "granero",
    "boat_house"     => "casa de botes",
    "farm"           => "granja",
    "harbour"        => "puerto",
    "island"         => "isla",
    "Mars"           => "Marte",
    "oars"           => "remos",
    "red_woolly_hat" => "gorro rojo de lana",
    "sheep_dog"      => "perro pastor",
    "skates"         => "patines de hielo",
    "tarn"           => "laguna de montaña",
    "telescope"      => "telescopio",
);

sub esFromPhoto($)                                                              # Spanish name from photo
 {my ($photo) = @_;                                                             # Photo file name
  $es{fn $photo}
 }

my @p = sort {lc($a) cmp lc($b)}                                                # Case independent sort
  searchDirectoryTreesForMatchingFiles $home, qw(.png .jpg);                    # Get photos

for my $f(@p)
 {my $a = fpe $home, enFromPhoto($f), $audioX;                                  # Audio file
  owf $a, '' unless -e $a;                                                      # Spanish | English audio
 }

my $Title = spaces($title);

my @h = <<END;                                                                  # Heading html
<!DOCTYPE html>
<html>
<style>
  body    {margin     : 1% 1% 1% 1%;}
  img     {width      : 100%; height: auto; min-width:20vw; max-width:30vw;  max-height:30vh; }
  .en     {font-weight: bold; font-family:" Century Gothic", serif; font-size:200%;}
  #table  {display    : flex; flex-wrap: wrap;}
  .thing  {text-align : center}
  .hidden {display    : none}
</style>
<body>
<h1 onclick="playTitle.play()">$Title</h1>

<p>Click on the words to hear them in English.  Show words in:
<input checked="1" type="checkbox" id="toggleEn">English
<input checked="1" type="checkbox" id="toggleEs">Spanish

<audio id="playTitle" src="$title.$audioX"></audio>
<div id=table>
END

for my $i(keys @p)                                                              # Images
 {my $p = fne $p[$i];
  my $e = enFromPhoto $p; my $E = spaces($e);
  my $s = esFromPhoto($p) // $E;                                                # Reuse en for proper names
  $audio{$p} = my $a = "$e.$audioX";

  push @h, <<END;
    <div class="thing" onclick="play$e.play()"><table><tr><td><img src="$p"><tr><td class="en">$E<tr><td class="es">$s<tr><td><audio id="play$e" src="$a"></audio></table></div>
END
 }

push @h, <<END;
</div>
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

owf($index, join" ", @h);                                                       # Write html

push my @s, <<END;                                                              # Audio script
<h1>$title</h1>
<table cellpadding=5>
END

for my $p(@p)                                                                   # Audio and words still needing translation
 {my $n = enFromPhoto($p);
  my $a = $audio{fne $p};
  if (!$a or !-e $a or fileSize($a) < 1e3)                                      # Files not yet recorded
   {push @s," <tr><td>$n";
    $translate{$n}++
   }
 }

push @s, <<END;
</table>
</body>
</html>
END

owf($script,    join" \n", @s);                                                 # Write script
owf($translate, join" \n", sort keys %translate);                               # Words needing translation
owf($list,      join" \n", map {pad(enFromPhoto($_), 16)." => 1,"} @p);         # Words needing categories
