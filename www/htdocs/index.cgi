#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use 5.16.0;
no warnings 'experimental::smartmatch';

use Time::HiRes qw(gettimeofday tv_interval);
my $begintime;
BEGIN { $begintime = [gettimeofday()]; }

use CGI ':standard';
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);
use Encode;
use HTML::Entities;
use MaxMind::DB::Reader;
use Template;
use File::Slurper 'read_text';
use XML::Fast;

my $debug = 0;

my @banned;
my $totalplayers  = 0;
my $totalservers  = 0;
my $activeservers = 0;
my $totalbots     = 0;

my $xmlservers  = '/srv/www/xonotic.lifeisabug.com/files/current.xml';
my $checkupdate = '/srv/www/xonotic.lifeisabug.com/files/checkupdate.txt';
my $geodb       = '/usr/share/GeoIP/GeoLite2-City.mmdb';

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

sub measure {
   my $time = shift || $begintime;

   return tv_interval($time);
}

sub printheader {
   if ($debug) {
      use Data::Dumper;
      $$ttvars{debug} = Dumper($ttvars);
   }

   print header(
      -charset => 'utf-8',
   );
}

sub formatnick {
   my $up = pack 'H*', $_;

   $up =~ s/\^x...//g;
   $up =~ s/\^[0-9]//g;

   return encode_entities(Encode::decode_utf8($up));
}

###

my $xmlfile = read_text($xmlservers);
my $xmlin = xml2hash($xmlfile, attr => '', text => 'val');

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

   $$xml{server}{$name} = $_;

   for (@{$$xml{server}{$name}{rules}{rule}}) {
       $$xml{server}{$name}{rule}{$_->{name}} = $_->{val};
   }

   delete $$xml{server}{$name}{rules};

   next unless $$xml{server}{$name}{players};

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

my %ban;

for (keys %{$$xml{server}}) {
   my $key = $_;

   for (@banned) {
      if ($$xml{server}{$key}{address} =~ /\Q$_\E/) {
         $ban{$key}++;
      }
   }
}

delete @{$$xml{server}}{keys %ban};
undef %ban;

for (keys %{$$xml{server}}) {
   my $key = $_;

   $$xml{server}{$_}{realhostname} = encode_entities(Encode::decode_utf8(pack('H*', $_)));
   $$xml{server}{$_}{map} = encode_entities(Encode::decode_utf8(pack('H*', $$xml{server}{$_}{map})));

   $$xml{server}{$_}{numplayers} -= $$xml{server}{$_}{rule}{bots};

   for (keys %{$$xml{server}{$_}{player}}) {
      $$xml{server}{$key}{player}{$_}{nick} = formatnick($_);
   }

   ($$xml{server}{$_}{enc}, $$xml{server}{$_}{d0id}) = defined $$xml{server}{$_}{rule}{d0_blind_id} ? split(' ', $$xml{server}{$_}{rule}{d0_blind_id}) : '-';

   my ($mode, $ver, $impure, $slots, $flags, $mode2) = split(':', $$xml{server}{$_}{rule}{qcstatus});
   $$xml{server}{$_}{version}   = $ver;
   $$xml{server}{$_}{impure}    = substr($impure, 1);
   $$xml{server}{$_}{slots}     = substr($slots, 1);
   #$$xml{server}{$_}{mode}      = uc($mode) eq 'DM' && $$xml{server}{$_}{rule}{hostname} =~ /duel/i ? 'DUEL' : uc($mode);
   $$xml{server}{$_}{mode}      = uc($mode) eq 'DM' && $$xml{server}{$_}{slots} + $$xml{server}{$_}{numplayers} - $$xml{server}{$_}{numspectators} == 2 ? 'DUEL' : uc($mode);
   $$xml{server}{$_}{fballowed} = substr($flags, 1) & 1 ? 1 : 0;
   $$xml{server}{$_}{teamplay}  = substr($flags, 1) & 2 ? 1 : 0;
   $$xml{server}{$_}{stats}     = substr($flags, 1) & 4 ? 1 : 0;
   $$xml{server}{$_}{mode2}     = $mode2 eq 'MXonotic' ? 'VANILLA' : uc(substr($mode2, 1));
   
   $$xml{server}{$_}{numbots}   = $$xml{server}{$_}{rule}{bots};

   $activeservers++ if ($$xml{server}{$_}{numplayers} > 0); 
   $totalservers ++;
   $totalplayers += $$xml{server}{$_}{numplayers};
   $totalbots    += $$xml{server}{$_}{rule}{bots};

   delete $$xml{server}{$_}{rule};

   my $record = $gi->record_for_address((split(':', $$xml{server}{$_}{address}))[0]);
   $$xml{server}{$_}{geo} = $record->{country}{iso_code} ? $record->{country}{iso_code} : '??';
   $$xml{server}{$_}{geo} = 'AU' if ($$xml{server}{$_}{realhostname} =~ /australi/i);
}

$$ttvars{lastupdate}    = time - (stat($xmlservers))[9];
$$ttvars{activeservers} = $activeservers;
$$ttvars{totalservers}  = $totalservers;
$$ttvars{totalplayers}  = $totalplayers;
$$ttvars{totalbots}     = $totalbots;

$$ttvars{s} = $xml;

###

$$ttvars{measure} = \&measure;
printheader();
$tt->process('serverlist.tt', $ttvars) || croak($tt->error);
