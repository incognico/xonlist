#!/usr/bin/env perl

use 5.28.0;

use utf8;
use strict;
use warnings;

use Encode::Simple qw(decode_utf8_lax);
use File::Slurper qw(read_lines read_text);
use JSON::MaybeXS;
use DBI;

my $qstat_json  = '/srv/www/xonotic.lifeisabug.com/app/files/current.json';
my $checkupdate = '/srv/www/xonotic.lifeisabug.com/app/files/checkupdate.txt';
my $db          = '/srv/www/xonotic.lifeisabug.com/app/files/activity.db';

my ($s, @banned, @activity, @name, $dbh);

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

###

sub qfont_decode {
   my @chars;

   my $qstr = shift || '';

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

sub formatname {
   my $up = pack('H*', shift);
   $up =~ s/\^(\d|x[\dA-Fa-f]{3})//g;

   return qfont_decode(decode_utf8_lax($up));
}

sub sqlite_connect {
   unless ($dbh = DBI->connect("DBI:SQLite:dbname=$db", '', '', { AutoCommit => 1 })) {
      say $DBI::errstr;
      return 1;
   }
   else {
      return 0;
   }
}

sub sqlite_disconnect {
   $dbh->disconnect;
}

sub to_db {
   sqlite_connect();

   my ($h) = (gmtime)[2];
   my $h_q = qq{"$h"};

   foreach my $i (0..$#activity) {
      $dbh->do('INSERT INTO activity (server,name,' . $h_q . ') VALUES (?,?,?) ON CONFLICT(server) DO UPDATE SET ' . $h_q . ' = ' . $h_q . ' + 1', undef, $activity[$i], $name[$i], 1);
   }

   sqlite_disconnect();
}

sub parse_list {
   my $s = {};

   my $qstat = decode_json(read_text($qstat_json));

   for ($qstat->@*) {
      next unless ($$_{hostname} && $$_{status} eq 'online');
      next if ($$_{rules}{gameversion} > 65535);
      next if ((split /:([^:]+)$/, $$_{address})[0] ~~ @banned);

      if ($_->{numplayers} > 0) {
         push(@activity, $_->{address});
         push(@name, formatname($_->{name}));
      }

   }

   return;
}

sub update_banned {
   @banned = ();

   for (read_lines($checkupdate)) {
      push (@banned, $1) if ($_ =~ /^B\s+(.+):\s+?$/);
   }

   return;
}

###

update_banned();
parse_list();
to_db();
