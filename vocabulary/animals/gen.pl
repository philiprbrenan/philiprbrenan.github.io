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
use utf8;

my $title     = "Animals";                                                      # Title
my $home      = "/home/phil/z/spanish/animals/";                                # Home folder
my $audioX    = "wav";                                                          # Audio extension
my $imagesPL  = 6;                                                              # Images per line
my $index     = fpe $home, qw(animals html);                                    # English index
my $script    = fpe $home, qw(zScript html);                                    # Audio script
my $translate = fpe $home, qw(zTranslate txt);                                  # Words to be translated by chat gpt
my $list      = fpe $home, qw(zList      txt);                                  # Words to be listed
my $aTitle    = fpe $home, $title, $audioX;                                     # Main title sequence
my %audio;                                                                      # Audio files corresponding to photgraphs
my %translate;                                                                  # Translations still needed

owf($aTitle, '') unless -e $aTitle;

sub enFromPhoto($)                                                              # English name from photo
 {my ($photo) = @_;                                                             # Photo file name
  fn $photo
 }

my %es = (                                                                      # Spanish
    bear       => "oso",
    bird       => "pájaro",
    cat        => "gato",
    cock       => "gallo",
    cow        => "vaca",
    crab       => "cangrejo",
    crocodile  => "cocodrilo",
    dolphin    => "delfín",
    donkey     => "burro",
    duck       => "pato",
    eagle      => "águila",
    giraffe    => "jirafa",
    gorilla    => "gorila",
    hen        => "gallina",
    horse      => "caballo",
    koala      => "koala",
    leopard    => "leopardo",
    monkey     => "mono",
    mouse      => "ratón",
    octopus    => "pulpo",
    pig        => "cerdo",
    rhino      => "rinoceronte",
    seagull    => "gaviota",
    seal       => "foca",
    shark      => "tiburón",
    sheep      => "oveja",
    snake      => "serpiente",
    tiger      => "tigre",
    walrus     => "morsa",
    whale      => "ballena",
    zebra      => "cebra",
);

my %africa = (                                                                  # Live in Africa
bird       => 1,
crocodile  => 1,
giraffe    => 1,
gorilla    => 1,
leopard    => 1,
monkey     => 1,
rhino      => 1,
zebra      => 1,
);

my %fly = (                                                                     # Animals that fly
bird             => 1,
duck             => 1,
eagle            => 1,
seagull          => 1);

my %farm = (                                                                    # Farm animals
cat              => 1,
cock             => 1,
cow              => 1,
donkey           => 1,
duck             => 1,
hen              => 1,
horse            => 1,
mouse            => 1,
pig              => 1,
sheep            => 1);

my %swim = (                                                                    # Animals that like to swim
bear             => 1,
crab             => 1,
crocodile        => 1,
dolphin          => 1,
duck             => 1,
octopus          => 1,
seagull          => 1,
seal             => 1,
shark            => 1,
walrus           => 1,
whale            => 1);

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
  body    {margin     : 1% 1% 1% 1%;}
  img     {width      : 100%; height: auto; min-width:20vw; max-width:30vw;  max-height:30vh; }
  .en     {font-weight: bold; font-family:" Century Gothic", serif; font-size:200%;}
  #table  {display    : flex; flex-wrap: wrap;}
  .thing  {text-align : center}
  .hidden {display    : none}
</style>
<body>
<h1 onclick="playTitle.play()">$title</h1>

<p>Click on the words to hear them in English.  Show words in:
<input checked="1" type="checkbox" id="toggleEn">English
<input checked="1" type="checkbox" id="toggleEs">Spanish

<p>Choose animals that:
<input type="checkbox" id="toggleAfrica"> live in Africa,
<input type="checkbox" id="toggleFly"> can fly,
<input type="checkbox" id="toggleFarm">are found on a farm,
<input type="checkbox" id="toggleSwim">like to swim.

<audio id="playTitle" src="$title.$audioX"></audio>
<div id=table>
END

for my $i(keys @p)                                                              # Images
 {my $p = fne $p[$i];
  my $e = enFromPhoto $p;
  my $s = esFromPhoto($p)//'*****';                                             # Perhaps not yet translated
  $audio{$p} = my $a =" $e.$audioX";

  my ($africa, $fly, $farm, $swim) =                                            # Capabilities
   ($africa{$e} ?" africa" : '',
    $fly   {$e} ?" fly"    : '',
    $farm  {$e} ?" farm"   : '',
    $swim  {$e} ?" swim"   : '');

  push @h, <<END;
    <div class="thing $africa $fly $farm $swim" onclick="play$e.play()"><table><tr><td><img src="$p"><tr><td class="en">$e<tr><td class="es">$s<tr><td><audio id="play$e" src="$a"></audio></table></div>
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

function find(array, element)
 {for (const elem of array)
   {if (elem === element)
     {return 1
     }
   }
  return 0
 }

function tShow()
 {const africa = document.querySelectorAll('.africa')
  const farm   = document.querySelectorAll('.farm')
  const fly    = document.querySelectorAll('.fly')
  const swim   = document.querySelectorAll('.swim')
  const All    = document.querySelectorAll('.thing')
  let   all    = [...All]

  if (toggleAfrica.checked)
   {const f = []
    for(const a of all) if (find(africa, a)) f.push(a)
    all = f
   }

  if (toggleFarm.checked)
   {const f = []
    for(const a of all) if (find(farm, a)) f.push(a)
    all = f
   }

  if (toggleFly.checked)
   {const f = []
    for(const a of all) if (find(fly,  a)) f.push(a)
    all = f
   }

  if (toggleSwim.checked)
   {const f = []
    for(const a of all) if (find(swim, a)) f.push(a)
    all = f
   }
  for(const a of All)
   {find(all, a) ? a.classList.remove('hidden') : a.classList.add('hidden')
   }
 }

toggleEn.addEventListener('change', tEn); tEn()
toggleEs.addEventListener('change', tEs); tEs()

toggleAfrica.addEventListener('change', tShow)
toggleFarm  .addEventListener('change', tShow)
toggleFly   .addEventListener('change', tShow)
toggleSwim  .addEventListener('change', tShow)
tShow()
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
   {my $s = esFromPhoto($p);
    push @s," <tr><th>$s<td>$n<td>$n<td>$n" if $s;
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
