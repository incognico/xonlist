package xonlist;

use 5.28.0;

use utf8;
use strict;
use warnings;

use feature 'signatures';
no warnings qw(experimental::signatures experimental::smartmatch);

use Dancer2 ':nopragmas';
use Encode::Simple qw(encode_utf8 decode_utf8_lax);
use File::Slurper qw(read_lines read_text);
use MaxMind::DB::Reader;
use Unicode::Truncate;

our $VERSION = '0.1';

my $qstat_json  = config->{'filedir'} . '/current.json';
my $checkupdate = config->{'filedir'} . '/checkupdate.txt';

my $modes = {
   'ARENA'     => 'Duel Arena',
   'AS'        => 'Assault',
   'BR'        => 'Battle Royale',
   'CA'        => 'Clan Arena',
   'CONQUEST'  => 'Conquest',
   'COOP'      => 'Cooperative',
   'CQ'        => 'Conquest',
   'CTF'       => 'Capture the Flag',
   'CTS'       => 'Race - Complete the Stage',
   'DM'        => 'Deathmatch',
   'DOM'       => 'Domination',
   'DOTC'      => 'Defense of the Core (MOBA)',
   'DUEL'      => 'Duel',
   'FT'        => 'Freeze Tag',
   'INF'       => 'Infection',
   'INV'       => 'Invasion',
   'JAILBREAK' => 'Jailbreak',
   'JB'        => 'Jailbreak',
   'KA'        => 'Keepaway',
   'KH'        => 'Key Hunt',
   'LMS'       => 'Last Man Standing',
   'MAYHEM'    => 'Mayhem',
   'NB'        => 'Nexball',
   'ONS'       => 'Onslaught',
   'RACE'      => 'Race',
   'RC'        => 'Race',
   'RUNE'      => 'Runematch',
   'RUNEMATCH' => 'Runematch',
   'SNAFU'     => '???',
   'SURV'      => 'Survival',
   'TDM'       => 'Team Deathmatch',
   'TKA'       => 'Team Keepaway',
   'TMAYHEM'   => 'Team Mayhem',
   'VIP'       => 'Very Important Player',
};

my $teams = {
    5 => 1, # red
   14 => 2, # blue
   13 => 3, # yellow
   10 => 4, # pink
};

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

my $ttsubs = {
   ordinate => \&ordinate,
   s2t      => \&score2time,
   utrunc   => \&truncate_egc,
};

my ($s, @banned);
my ($fstat_json, $fstat_checkupdate) = (0, 0);

###

sub qfont_decode ($qstr = '') {
   my @chars;

   for (split('', $qstr)) {
      next if ($_ eq "\{U+FFFD}");

      my $i = ord($_) - 0xE000;
      my $c = ($_ ge "\N{U+E000}" && $_ le "\N{U+E0FF}")
      ? $qfont_unicode_glyphs[$i % @qfont_unicode_glyphs]
      : $_;
      #printf "<$_:$c|ord:%d>", ord;

      push(@chars, $c) if (defined $c);
   }

   return join('', @chars) if @chars;
   return 'unknown';
}

sub formatnick ($p) {
   my $up = pack('H*', $p);
   $up =~ s/\^(\d|x[\dA-Fa-f]{3})//g;

   return qfont_decode(decode_utf8_lax($up));
}

sub score2time ($score) {
   return '-' if ($score == 0);

   my $sec = substr($score, 0, -2, '');

   return $sec . '.' . $score . ' sec.';
}

sub ordinate ($num) {
   return $num . ($num =~ /(^|[^1])([123])$/ ? qw/st nd rd/[$2-1] : 'th');
}

sub parse_list ()
{
   $s = {};

   my $qstat = decode_json(read_text($qstat_json));
   my $gi    = MaxMind::DB::Reader->new(file => config->{'geodb'});

   my ($totalplayers, $totalservers, $activeservers, $totalbots) = (0, 0, 0, 0);

   for ($qstat->@*) {
      next unless ($$_{hostname} && $$_{status} eq 'online');
      next if ($$_{rules}{gameversion} > 65535);
      next if ((split /:([^:]+)$/, $$_{address})[0] ~~ @banned);

      my $key = $$_{address};
      $$s{server}{$key} = $_;

      delete $$s{server}{$key}{$_} for qw(gametype hostname protocol retries status);

      $$s{server}{$key}{numbots}     = int($$_{rules}{bots});
      $$s{server}{$key}{numplayers} -= $$_{rules}{bots};

      my $enc;
      ($enc, $$s{server}{$key}{d0id}) = (defined $$_{rules}{d0_blind_id} ? split(/ /, $$_{rules}{d0_blind_id}, 2) : 0, 0);
      $$s{server}{$key}{enc} = int($enc);

      # gametype:version:P<pure>:S<slots>:F<flags>:M<mode>::plabel,plabel:tlabel,tlabel:teamid:tscore,tscore:teamid:tscore,tscore
      # gametype:version:P<pure>:S<slots>:F<flags>:M<mode>:T<?>::plabel,plabel:tlabel,tlabel:teamid:tscore,tscore:teamid:tscore,tscore
      $$_{rules}{qcstatus} = '?:::' unless (defined $$_{rules}{qcstatus});
      $$_{rules}{qcstatus} = (defined $1 ? $1 : '?') . ':?:P9999:S0:F0:MUnknown::' . (defined $2 ? $2 : '') if ($$_{rules}{qcstatus} =~ /^([a-z\?]+):::(.+)?$/);
      $$_{rules}{qcstatus} =~ s/:F[0-9]+:\KT[^:]+://;
      my ($mode, $ver, $impure, $slots, $flags, $mode2, undef, $pscoreinfo, $tscoreinfo, @tscores) = split(/:/, $$_{rules}{qcstatus});
      $$s{server}{$key}{version}   = $ver;
      $$s{server}{$key}{impure}    = int(substr($impure, 1));
      $$s{server}{$key}{slots}     = int(substr($slots, 1));
      $$s{server}{$key}{mode}      = uc($mode) eq 'DM' && $$_{slots} + $$_{numplayers} - $$_{numspectators} == 2 ? 'DUEL' : uc($mode);
      $$s{server}{$key}{modefull}  = $$modes{$$s{server}{$key}{mode}};
      $$s{server}{$key}{fballowed} = substr($flags, 1) & 1 ? 1 : 0;
      $$s{server}{$key}{teamplay}  = substr($flags, 1) & 2 ? 1 : 0;
      $$s{server}{$key}{stats}     = substr($flags, 1) & 4 ? 1 : 0;
      $$s{server}{$key}{mode2}     = $mode2 eq 'MXonotic' ? 'VANILLA' : uc(substr($mode2, 1));

      my $scoreinfo_re = qr/^([a-z]+)([!<]+)?(?:,([a-z]+)([!<]+)?)?$/;

      if (defined $pscoreinfo && $pscoreinfo =~ /$scoreinfo_re/) {
         $$s{server}{$key}{scoreinfo}{player}{label} = $1;
         $$s{server}{$key}{scoreinfo}{player}{flags} = defined $2 ? $2 : '';
         $$s{server}{$key}{scoreinfo}{player}{order} = defined $2 && $2 =~ /</ ? 1 : 0;
         # secondary player score is not active in xon yet (fullstatus)
      }

      if (defined $tscoreinfo && $tscoreinfo =~ /$scoreinfo_re/) {
         $$s{server}{$key}{scoreinfo}{team}{pri}{label} = $1;
         $$s{server}{$key}{scoreinfo}{team}{pri}{flags} = defined $2 ? $2 : '';
         $$s{server}{$key}{scoreinfo}{team}{pri}{order} = defined $2 && $2 =~ /</ ? 1 : 0;

         if (defined $3) {
            $$s{server}{$key}{scoreinfo}{team}{prefer} = 'sec';
            $$s{server}{$key}{scoreinfo}{team}{sec}{label} = $3;
            $$s{server}{$key}{scoreinfo}{team}{sec}{flags} = defined $4 ? $4 : '';
            $$s{server}{$key}{scoreinfo}{team}{sec}{order} = defined $4 && $4 =~ /</ ? 1 : 0;
         }
         else {
            $$s{server}{$key}{scoreinfo}{team}{prefer} = 'pri';
         }

         while (my ($k, $v) = splice(@tscores, 0, 2)) {
            if ($$s{server}{$key}{scoreinfo}{team}{prefer} eq 'sec') {
               ($$s{server}{$key}{scoreinfo}{team}{pri}{score}{$$teams{$k}},
                $$s{server}{$key}{scoreinfo}{team}{sec}{score}{$$teams{$k}}) = map { int } split(/,/, $v, 2);
            }
            else {
               $$s{server}{$key}{scoreinfo}{team}{pri}{score}{$$teams{$k}} = int($v);
            }
         }
      }

      $$s{info}{activeservers}++ if ($$_{numplayers} > 0);
      $$s{info}{totalservers} ++;
      $$s{info}{totalplayers} += $$_{numplayers};
      $$s{info}{totalbots}    += $$_{rules}{bots};

      $$s{server}{$key}{gamedir} = $$s{server}{$key}{rules}{modname};
      delete $$s{server}{$key}{rules};

      my $rec = $gi->record_for_address((split(/:/, $$_{address}))[0]);
      $$s{server}{$key}{geo} = $rec->{country}{iso_code} ? $rec->{country}{iso_code} : '??';

      $$s{server}{$key}{realname} = formatnick($$_{name});
      $$s{server}{$key}{map}      = formatnick($$_{map});

      for ($$s{server}{$key}{players}->@*) {
         $$_{name} = formatnick($$_{name});

         $$_{team} = 0 unless (defined $$_{team});
         if ($$_{score} == -666 || $$_{score} == -616 || $$_{name} eq 'unconnected') {
            $$_{prio} = 2;
            $$_{team} = 0;
         }
         elsif ($$_{score} == 0 && ($$s{server}{$key}{scoreinfo}{player}{label} && $$s{server}{$key}{scoreinfo}{player}{label} =~ /^(fastest|time)$/) || $$s{server}{$key}{teamplay} && $$_{team} == 0) {
            $$_{prio} = 1;
         }
         else {
            $$_{prio} = 0;
         }
      }
   }

   $$s{info}{lastupdate_epoch} = $fstat_json = (stat($qstat_json))[9];

   return;
}

sub update_banned () {
   @banned = ();

   for (read_lines($checkupdate)) {
      push (@banned, $1) if ($_ =~ /^B\s+(.+):\s+?$/);
   }

   $fstat_checkupdate = (stat($checkupdate))[9];

   return;
}

sub detect_changes () {
   update_banned() unless ((stat($checkupdate))[9] == $fstat_checkupdate);
   parse_list()    unless ((stat($qstat_json))[9]  == $fstat_json);

   $$s{info}{lastupdate} = time - $fstat_json;

   return;
}

###

prepare_app {
   detect_changes();
};

hook before => sub ($) {
   detect_changes();
};

hook before_template_render => sub ($tokens) {
   $$tokens{dbg} = to_dumper($tokens) if (config->{'environment'} eq 'development');
   $$tokens{rjz}++ if query_parameters->get('rjz'); # https://rocketjump.zone/browser/
};

get '/' => sub ($) {
   my $ttvars = { s => $s };

   $$ttvars{$_} = $$ttsubs{$_} for (keys $ttsubs->%*);

   template 'xonlist.tt', $ttvars;
};

get '/server/:server' => sub ($) {
   my $server = route_parameters->get('server');
   my $ttvars = { selection => 1, embed => 1 };

   $$ttvars{$_} = $$ttsubs{$_} for (keys $ttsubs->%*);
   $$ttvars{s}{server}{$server} = $$s{server}{$server} if (defined $$s{server}{$server});

   template 'embed.tt', $ttvars;
};

get '/servers' => sub ($) {
   my @servers = query_parameters->get_all('s');
   my $ttvars = { selection => 1 };

   $$ttvars{$_} = $$ttsubs{$_} for (keys $ttsubs->%*);

   for (keys $$s{server}->%*) {
      next if (!($_ ~~ @servers));
      $$ttvars{s}{server}{$_} = $$s{server}{$_} if (defined $$s{server}{$_});
   }

   template 'servers.tt', $ttvars;
};

get '/endpoint/json' => sub ($) {
   my $pretty = query_parameters->get('pretty');

   #send_as JSON => $s; # nuu pretty print :(

   content_type 'application/json';

   delayed {
      content $pretty ? (to_json($s, { utf8 => 1, pretty => 1 })) : encode_json($s);
   };
};

1;
