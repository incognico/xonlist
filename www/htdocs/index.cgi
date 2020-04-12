#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use 5.16.0;
no warnings 'experimental::smartmatch';

use Time::HiRes qw(gettimeofday tv_interval);
my $begintime;
BEGIN { $begintime = [gettimeofday()]; }

use CGI qw(header param -utf8);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Encode::Simple qw(encode_utf8 decode_utf8);
use HTML::Entities;
use MaxMind::DB::Reader;
use Template;
use File::Slurper 'read_text';
use XML::Fast;
use JSON;

my $debug = 0;

my $xmlservers  = '/srv/www/xonotic.lifeisabug.com/files/current.xml';
my $checkupdate = '/srv/www/xonotic.lifeisabug.com/files/checkupdate.txt';
my $geodb       = '/home/k/GeoLite2-City.mmdb';

my $ttvars = {
   title => 'Xonotic Server List',
   url   => 'https://xonotic.lifeisabug.com',
};

my %ttopts = (
   INCLUDE_PATH => '/srv/www/xonotic.lifeisabug.com/templates/',
   PRE_CHOMP    => 2,
   POST_CHOMP   => 2,
);

croak("template folder $ttopts{INCLUDE_PATH} does not exist") unless (-e $ttopts{INCLUDE_PATH});

my $tt = Template->new(\%ttopts);

###

sub measure {
   my $time = shift || $begintime;

   return tv_interval($time);
}

sub printheader {
   my $type = shift || 'text/html';

   if ($debug) {
      use Data::Dumper;
      $$ttvars{debug} = Dumper($ttvars);
   }

   print header(
      -charset => 'utf-8',
      -type    => $type
   );

   return;
}

my @qfont_unicode_glyphs = (
   "\N{U+0020}",     "\N{U+0020}",     "\N{U+2014}",     "\N{U+0020}",
   "\N{U+005F}",     "\N{U+2747}",     "\N{U+2020}",     "\N{U+00B7}",
   "\N{U+0001F52B}", "\N{U+0020}",     "\N{U+0020}",     "\N{U+25A0}",
   "\N{U+2022}",     "\N{U+2192}",     "\N{U+2748}",     "\N{U+2748}",
   "\N{U+005B}",     "\N{U+005D}",     "\N{U+0001F47D}", "\N{U+0001F603}",
   "\N{U+0001F61E}", "\N{U+0001F635}", "\N{U+0001F615}", "\N{U+0001F60A}",
   "\N{U+00AB}",     "\N{U+00BB}",     "\N{U+2022}",     "\N{U+203E}",
   "\N{U+2748}",     "\N{U+25AC}",     "\N{U+25AC}",     "\N{U+25AC}",
   "\N{U+0020}",     "\N{U+0021}",     "\N{U+0022}",     "\N{U+0023}",
   "\N{U+0024}",     "\N{U+0025}",     "\N{U+0026}",     "\N{U+0027}",
   "\N{U+0028}",     "\N{U+0029}",     "\N{U+00D7}",     "\N{U+002B}",
   "\N{U+002C}",     "\N{U+002D}",     "\N{U+002E}",     "\N{U+002F}",
   "\N{U+0030}",     "\N{U+0031}",     "\N{U+0032}",     "\N{U+0033}",
   "\N{U+0034}",     "\N{U+0035}",     "\N{U+0036}",     "\N{U+0037}",
   "\N{U+0038}",     "\N{U+0039}",     "\N{U+003A}",     "\N{U+003B}",
   "\N{U+003C}",     "\N{U+003D}",     "\N{U+003E}",     "\N{U+003F}",
   "\N{U+0040}",     "\N{U+0041}",     "\N{U+0042}",     "\N{U+0043}",
   "\N{U+0044}",     "\N{U+0045}",     "\N{U+0046}",     "\N{U+0047}",
   "\N{U+0048}",     "\N{U+0049}",     "\N{U+004A}",     "\N{U+004B}",
   "\N{U+004C}",     "\N{U+004D}",     "\N{U+004E}",     "\N{U+004F}",
   "\N{U+0050}",     "\N{U+0051}",     "\N{U+0052}",     "\N{U+0053}",
   "\N{U+0054}",     "\N{U+0055}",     "\N{U+0056}",     "\N{U+0057}",
   "\N{U+0058}",     "\N{U+0059}",     "\N{U+005A}",     "\N{U+005B}",
   "\N{U+005C}",     "\N{U+005D}",     "\N{U+005E}",     "\N{U+005F}",
   "\N{U+0027}",     "\N{U+0061}",     "\N{U+0062}",     "\N{U+0063}",
   "\N{U+0064}",     "\N{U+0065}",     "\N{U+0066}",     "\N{U+0067}",
   "\N{U+0068}",     "\N{U+0069}",     "\N{U+006A}",     "\N{U+006B}",
   "\N{U+006C}",     "\N{U+006D}",     "\N{U+006E}",     "\N{U+006F}",
   "\N{U+0070}",     "\N{U+0071}",     "\N{U+0072}",     "\N{U+0073}",
   "\N{U+0074}",     "\N{U+0075}",     "\N{U+0076}",     "\N{U+0077}",
   "\N{U+0078}",     "\N{U+0079}",     "\N{U+007A}",     "\N{U+007B}",
   "\N{U+007C}",     "\N{U+007D}",     "\N{U+007E}",     "\N{U+2190}",
   "\N{U+003C}",     "\N{U+003D}",     "\N{U+003E}",     "\N{U+0001F680}",
   "\N{U+00A1}",     "\N{U+004F}",     "\N{U+0055}",     "\N{U+0049}",
   "\N{U+0043}",     "\N{U+00A9}",     "\N{U+00AE}",     "\N{U+25A0}",
   "\N{U+00BF}",     "\N{U+25B6}",     "\N{U+2748}",     "\N{U+2748}",
   "\N{U+2772}",     "\N{U+2773}",     "\N{U+0001F47D}", "\N{U+0001F603}",
   "\N{U+0001F61E}", "\N{U+0001F635}", "\N{U+0001F615}", "\N{U+0001F60A}",
   "\N{U+00AB}",     "\N{U+00BB}",     "\N{U+2747}",     "\N{U+0078}",
   "\N{U+2748}",     "\N{U+2014}",     "\N{U+2014}",     "\N{U+2014}",
   "\N{U+0020}",     "\N{U+0021}",     "\N{U+0022}",     "\N{U+0023}",
   "\N{U+0024}",     "\N{U+0025}",     "\N{U+0026}",     "\N{U+0027}",
   "\N{U+0028}",     "\N{U+0029}",     "\N{U+002A}",     "\N{U+002B}",
   "\N{U+002C}",     "\N{U+002D}",     "\N{U+002E}",     "\N{U+002F}",
   "\N{U+0030}",     "\N{U+0031}",     "\N{U+0032}",     "\N{U+0033}",
   "\N{U+0034}",     "\N{U+0035}",     "\N{U+0036}",     "\N{U+0037}",
   "\N{U+0038}",     "\N{U+0039}",     "\N{U+003A}",     "\N{U+003B}",
   "\N{U+003C}",     "\N{U+003D}",     "\N{U+003E}",     "\N{U+003F}",
   "\N{U+0040}",     "\N{U+0041}",     "\N{U+0042}",     "\N{U+0043}",
   "\N{U+0044}",     "\N{U+0045}",     "\N{U+0046}",     "\N{U+0047}",
   "\N{U+0048}",     "\N{U+0049}",     "\N{U+004A}",     "\N{U+004B}",
   "\N{U+004C}",     "\N{U+004D}",     "\N{U+004E}",     "\N{U+004F}",
   "\N{U+0050}",     "\N{U+0051}",     "\N{U+0052}",     "\N{U+0053}",
   "\N{U+0054}",     "\N{U+0055}",     "\N{U+0056}",     "\N{U+0057}",
   "\N{U+0058}",     "\N{U+0059}",     "\N{U+005A}",     "\N{U+005B}",
   "\N{U+005C}",     "\N{U+005D}",     "\N{U+005E}",     "\N{U+005F}",
   "\N{U+0027}",     "\N{U+0041}",     "\N{U+0042}",     "\N{U+0043}",
   "\N{U+0044}",     "\N{U+0045}",     "\N{U+0046}",     "\N{U+0047}",
   "\N{U+0048}",     "\N{U+0049}",     "\N{U+004A}",     "\N{U+004B}",
   "\N{U+004C}",     "\N{U+004D}",     "\N{U+004E}",     "\N{U+004F}",
   "\N{U+0050}",     "\N{U+0051}",     "\N{U+0052}",     "\N{U+0053}",
   "\N{U+0054}",     "\N{U+0055}",     "\N{U+0056}",     "\N{U+0057}",
   "\N{U+0058}",     "\N{U+0059}",     "\N{U+005A}",     "\N{U+007B}",
   "\N{U+007C}",     "\N{U+007D}",     "\N{U+007E}",     "\N{U+25C0}"
);

sub qfont_decode {
    my $qstr = shift // '';
    my @chars;

    for (split('', $qstr)) {
       my $i = ord($_) - 0xE000;
       my $c = ($_ ge "\N{U+E000}" && $_ le "\N{U+E0FF}")
          ? $qfont_unicode_glyphs[$i % @qfont_unicode_glyphs]
          : $_;
        #printf "<$_:$c|ord:%d>", ord;
        push @chars, $c if defined $c;
    }

    return join '', @chars;
}

sub formatnick {
   my $up = pack 'H*', shift // '';

   $up =~ s/\^(\d|x[\dA-Fa-f]{3})//g;

   return encode_entities(qfont_decode(decode_utf8($up)));
}

###

my @banned;

my $qdest = param('dest') || 'index';
my $xmlin = xml2hash(read_text($xmlservers), attr => '', text => 'val');

open(my $fh, "<", $checkupdate)
   or croak("Can't open update file: $!");

while (my $line = <$fh>) {
   chomp $line;
   push (@banned, $1) if ($line =~ /^B (.+):$/);
}

close $fh;

my $gi = MaxMind::DB::Reader->new(file => $geodb);

my $xml;

for (@{$$xmlin{qstat}{server}}) {
   my $name = $_->{name};

   next unless defined $name; 

   $$xml{server}{$name} = $_ unless ($$xml{server}{$name}{address} ~~ @banned);

   delete $$xml{server}{$name}{name};

   for (@{$$xml{server}{$name}{rules}{rule}}) {
       $$xml{server}{$name}{rule}{$_->{name}} = $_->{val};
   }

   delete $$xml{server}{$name}{rules};

   unless ($$xml{server}{$name}{players}) {
      delete $$xml{server}{$name}{players};
      next;
   }

   if (ref($$xml{server}{$name}{players}{player}) eq 'ARRAY') {
      for (@{$$xml{server}{$name}{players}{player}}) {
         $$xml{server}{$name}{player}{$_->{name}} = $_;
      }
   }
   elsif (ref($$xml{server}{$name}{players}{player}) eq 'HASH') {
      $$xml{server}{$name}{player}{$$xml{server}{$name}{players}{player}{name}}{name}  = $$xml{server}{$name}{players}{player}{name}  if exists $$xml{server}{$name}{players}{player}{name};
      $$xml{server}{$name}{player}{$$xml{server}{$name}{players}{player}{name}}{score} = $$xml{server}{$name}{players}{player}{score} if exists $$xml{server}{$name}{players}{player}{score};
      $$xml{server}{$name}{player}{$$xml{server}{$name}{players}{player}{name}}{ping}  = $$xml{server}{$name}{players}{player}{ping}  if exists $$xml{server}{$name}{players}{player}{ping};
      $$xml{server}{$name}{player}{$$xml{server}{$name}{players}{player}{name}}{team}  = exists $$xml{server}{$name}{players}{player}{team} ? $$xml{server}{$name}{players}{player}{team} : 0;
   }

   delete $$xml{server}{$name}{players};
}

my $totalplayers  = 0;
my $totalservers  = 0;
my $activeservers = 0;
my $totalbots     = 0;

for my $key (keys %{$$xml{server}}) {
   $$xml{server}{$key}{realhostname} = encode_entities(decode_utf8(pack('H*', $key)));
   $$xml{server}{$key}{map} = encode_entities(decode_utf8(pack('H*', $$xml{server}{$key}{map})));

   $$xml{server}{$key}{numplayers} -= $$xml{server}{$key}{rule}{bots};

   for (keys %{$$xml{server}{$key}{player}}) {
      $$xml{server}{$key}{player}{$_}{nick} = formatnick($_);
      delete $$xml{server}{$key}{player}{$_}{name};
   }

   ($$xml{server}{$key}{enc}, $$xml{server}{$key}{d0id}) = defined $$xml{server}{$key}{rule}{d0_blind_id} ? split(' ', $$xml{server}{$key}{rule}{d0_blind_id}) : '-';

   my ($mode, $ver, $impure, $slots, $flags, $mode2) = split(':', $$xml{server}{$key}{rule}{qcstatus});
   $$xml{server}{$key}{version}   = $ver;
   $$xml{server}{$key}{impure}    = substr($impure, 1);
   $$xml{server}{$key}{slots}     = substr($slots, 1);
   #$$xml{server}{$key}{mode}      = uc($mode) eq 'DM' && $$xml{server}{$key}{rule}{realhostname} =~ /duel/i ? 'DUEL' : uc($mode);
   $$xml{server}{$key}{mode}      = uc($mode) eq 'DM' && $$xml{server}{$key}{slots} + $$xml{server}{$key}{numplayers} - $$xml{server}{$key}{numspectators} == 2 ? 'DUEL' : uc($mode);
   $$xml{server}{$key}{fballowed} = substr($flags, 1) & 1 ? 1 : 0;
   $$xml{server}{$key}{teamplay}  = substr($flags, 1) & 2 ? 1 : 0;
   $$xml{server}{$key}{stats}     = substr($flags, 1) & 4 ? 1 : 0;
   $$xml{server}{$key}{mode2}     = $mode2 eq 'MXonotic' ? 'VANILLA' : uc(substr($mode2, 1));
   
   $$xml{server}{$key}{numbots}   = $$xml{server}{$key}{rule}{bots};

   $activeservers++ if ($$xml{server}{$key}{numplayers} > 0); 
   $totalservers ++;
   $totalplayers += $$xml{server}{$key}{numplayers};
   $totalbots    += $$xml{server}{$key}{rule}{bots};

   delete $$xml{server}{$key}{rule};

   my $rec = $gi->record_for_address((split(':', $$xml{server}{$key}{address}))[0]);
   $$xml{server}{$key}{geo} = $rec->{country}{iso_code} ? $rec->{country}{iso_code} : '??';
   $$xml{server}{$key}{geo} = 'AU' if ($$xml{server}{$key}{realhostname} =~ /australi[as]/i); # shitty workaround
}

$$ttvars{lastupdate}    = time - (stat($xmlservers))[9];
$$ttvars{activeservers} = $activeservers;
$$ttvars{totalservers}  = $totalservers;
$$ttvars{totalplayers}  = $totalplayers;
$$ttvars{totalbots}     = $totalbots;

$$ttvars{measure} = \&measure;

###

given ($qdest) {
   when('json') { page_json(); }
   default      { page_index(); }
}

sub page_index {
   $$ttvars{s} = $xml;
   printheader();
   $tt->process('serverlist.tt', $ttvars) || croak($tt->error);
}

sub page_json {
   $$xml{info}{lastupdate}    = time - (stat($xmlservers))[9];
   $$xml{info}{activeservers} = $activeservers;
   $$xml{info}{totalservers}  = $totalservers;
   $$xml{info}{totalplayers}  = $totalplayers;
   $$xml{info}{totalbots}     = $totalbots;

   $$xml{info}{measure} = measure($begintime);

   $$ttvars{json} = to_json($xml, { utf8 => 1, pretty => 1 });

   printheader('application/json');
   $tt->process('json.tt', $ttvars) || croak($tt->error);
}
