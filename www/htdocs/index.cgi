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
use File::Slurper qw(read_lines read_text);
use JSON;
use MaxMind::DB::Reader;
use Template;
use Unicode::Truncate;

my $debug = 0;

my $qstat_json  = '/srv/www/xonotic.lifeisabug.com/files/current.json';
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

sub process {
   my $tmpl = shift || 'xonlist';
   my $type = shift || 'text/html';

   if ($debug) {
      require Data::Dumper;
      Data::Dumper->import;
      $$ttvars{debug} = Dumper($ttvars);
   }

   print header(
      -charset => 'utf-8',
      -type    => $type
   );

   $tt->process($tmpl.'.tt', $ttvars) || croak($tt->error);

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

   return qfont_decode(decode_utf8($up));
}

sub score2time {
   my $score = shift || return '-';

   return 0 unless ($score =~ /^[0-9]+/);

   my $tsec = substr($score, -2);
   my $sec  = substr($score, 0, -2);

   return $sec . '.' . $tsec . ' sec.';
}

###

my $qdest   = param('dest')   || 'index';
my $qsingle = param('single') || 0;
my $qpretty = param('pretty') || 0;

my @banned;
for (read_lines($checkupdate)) {
   push (@banned, $1) if ($_ =~ /^B (.+):$/);
}

my $qstat = decode_json(read_text($qstat_json));
my $gi    = MaxMind::DB::Reader->new(file => $geodb);

my ($totalplayers, $totalservers, $activeservers, $totalbots, $vars) = (0, 0, 0, 0);

for (@{$qstat}) {
   next unless ($$_{hostname} && $$_{status} eq 'online');
   next if ($qsingle && $$_{address} ne $qsingle);
   next if ($$_{rules}{gameversion} > 65535);
   next if ((split /:([^:]+)$/, $$_{address})[0] ~~ @banned);

   my $key = $$_{address};
   $$vars{server}{$key} = $_;

   delete $$vars{server}{$key}{$_} for qw(gametype hostname protocol retries status);

   $$vars{server}{$key}{numbots}     = int($$_{rules}{bots});
   $$vars{server}{$key}{numplayers} -= $$_{rules}{bots};

   my $enc;
   ($enc, $$vars{server}{$key}{d0id}) = (defined $$_{rules}{d0_blind_id} ? split(' ', $$_{rules}{d0_blind_id}) : 0, 0);
   $$vars{server}{$key}{enc} = int($enc);

   my ($mode, $ver, $impure, $slots, $flags, $mode2, undef, $scoreinfo) = split(':', $$_{rules}{qcstatus});
   $$vars{server}{$key}{version}   = $ver;
   $$vars{server}{$key}{impure}    = int(substr($impure, 1));
   $$vars{server}{$key}{slots}     = int(substr($slots, 1));
   $$vars{server}{$key}{mode}      = uc($mode) eq 'DM' && $$_{slots} + $$_{numplayers} - $$_{numspectators} == 2 ? 'DUEL' : uc($mode);
   $$vars{server}{$key}{fballowed} = substr($flags, 1) & 1 ? 1 : 0;
   $$vars{server}{$key}{teamplay}  = substr($flags, 1) & 2 ? 1 : 0;
   $$vars{server}{$key}{stats}     = substr($flags, 1) & 4 ? 1 : 0;
   $$vars{server}{$key}{mode2}     = $mode2 eq 'MXonotic' ? 'VANILLA' : uc(substr($mode2, 1));

   if ($scoreinfo && $scoreinfo =~ /([a-z]+)([!<]{0,3})/) {
      $$vars{server}{$key}{scorelabel} = $1;
      $$vars{server}{$key}{scoreflags} = $2;
      $$vars{server}{$key}{scoreorder} = $2 =~ /</ ? 1 : 0;
   }

   $$vars{info}{activeservers}++ if ($$_{numplayers} > 0); 
   $$vars{info}{totalservers} ++;
   $$vars{info}{totalplayers} += $$_{numplayers};
   $$vars{info}{totalbots}    += $$_{rules}{bots};

   delete $$vars{server}{$key}{rules};

   my $rec = $gi->record_for_address((split(':', $$_{address}))[0]);
   $$vars{server}{$key}{geo} = $rec->{country}{iso_code} ? $rec->{country}{iso_code} : '??';
   #$$vars{server}{$key}{geo} = 'AU' if ($$vars{server}{$key}{realname} =~ /australi[as]/i); # shitty workaround

   $$vars{server}{$key}{realname} = decode_utf8(pack('H*', $$_{name}));
   my $map = decode_utf8(pack('H*', $$_{map}));
   $$vars{server}{$key}{map}      = $map;
   $$vars{server}{$key}{maptrunc} = truncate_egc($map, 16) unless ($qdest eq 'json');

   $$_{name} = formatnick($$_{name}) for (@{$$vars{server}{$key}{players}});
}

my $fstat = (stat($qstat_json))[9];

$$vars{info}{lastupdate_epoch} = $fstat;
$$vars{info}{lastupdate}       = time - $fstat;

###

given ($qdest) {
   when('json') { page_json(); }
   default      { page_index(); }
}

sub page_index {
   $$ttvars{measure} = \&measure;
   $$ttvars{s2t} = \&score2time;

   $$vars{info}{single} = $qsingle ? 1 : 0;
   $$ttvars{s} = $vars;

   $qsingle ? process('servers') : process('xonlist');

   return;
}

sub page_json {
   $$vars{info}{measure} = measure($begintime);

   $qpretty ? ($$ttvars{json} = to_json($vars, { utf8 => 1, pretty => 1 })) : ($$ttvars{json} = encode_json($vars));

   process('json', 'application/json');

   return;
}
