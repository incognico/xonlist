#!/usr/bin/env perl

use 5.28.0;

use utf8;
use strict;
use warnings;

use DBI;
use GD;
use List::Util qw(max);
#use Data::Dumper;

my $db = '/srv/www/xonotic.lifeisabug.com/app/files/activity.db';
my $font_path = '/srv/www/xonotic.lifeisabug.com/app/files/Xolonium-Regular.ttf';
my $font_size = 10;

my ($s, $dbi, $dbh);
my ($r_max, $g_max, $b_max) = (51, 196, 240);

###

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

sqlite_connect();

###

my $data = $dbh->selectall_hashref('SELECT * from activity', 'server');

sqlite_disconnect();

my @all_values;
foreach my $server (values %$data) {
    for my $hour (0..23) {
        push @all_values, $server->{$hour} 
            if defined $server->{$hour} && $server->{$hour} > 0;
    }
}
my $max_val = 0;
my $total = 0;
foreach my $server (values %$data) {
    for my $hour (0..23) {
        my $val = $server->{$hour} || 0;
        $max_val = $val if $val > $max_val;
        $total += $val;
    }
    $server->{total} = $total;
    $total = 0;
}

# Draw
my $cell_width = 50;
my $cell_height = 30;
my $left_margin = 50;
my $right_margin = 550;
my $total_margin = $left_margin + $right_margin;
my $horizontal_margin_total = $left_margin + $right_margin;

my $top_margin = 25;
my $bottom_margin = 25;
my $vertical_margin_total = $top_margin + $bottom_margin;

my @servers = reverse sort { $data->{$a}{total} <=> $data->{$b}{total} } keys %$data;
$#servers = 49 if $#servers > 49;

# Size
my $width = 24 * $cell_width + $horizontal_margin_total;
my $height = scalar(@servers) * $cell_height + $vertical_margin_total;

my $image = GD::Image->new($width, $height, 1);

my $white = $image->colorAllocate(255,255,255);
my $black = $image->colorAllocate(0,0,0);
my $gray = $image->colorAllocate(200,200,200);

# Draw heatmap
$image->filledRectangle(0, 0, $width, $height, $white);

# Y (servernames)
for my $i (0..$#servers) {
   my $x = $left_margin + (24 * $cell_width) + 10;
   my $y = $top_margin + $i * $cell_height + $font_size + 8;
   $image->stringFT(
        $black,
        $font_path,
        $font_size,
        0,
        $x,
        $y,
        sprintf('#%d: %s', $i+1,$data->{$servers[$i]}{name}),
    );
}

# X (hours)
for my $hour (0..23) {
   my $x = $left_margin + $hour * $cell_width + 5;
   my $y = $height - $bottom_margin + $font_size + 6;
   $image->stringFT(
      $black,
      $font_path,
      $font_size,
      0,
      $x,
      $y,
      sprintf('%.2d:00', $hour),
   );
}

# Heatmap cells
for my $i (0..$#servers) {
    my $server = $servers[$i];

    for my $hour (0..23) {
       my $value = defined $data->{$server}{$hour} ? $data->{$server}{$hour} : 0;

       my $ratio = $max_val > 0 ? ($value / $max_val) : 0;
      
       my $r = int(255 - (255 - $r_max) * $ratio);
       my $g = int(255 - (255 - $g_max) * $ratio);
       my $b = int(255 - (255 - $b_max) * $ratio);
       
       my $color = $image->colorAllocate($r, $g, $b);

       my $x = $left_margin + $hour * $cell_width;
       my $y = $top_margin + $i * $cell_height;
        
       $image->filledRectangle($x, $y, $x + $cell_width, $y + $cell_height, $color);
       $image->rectangle($x, $y, $x + $cell_width, $y + $cell_height, $gray);
    }
}

open my $out, '>', '/srv/www/xonotic.lifeisabug.com/app/public/heatmap.png' or die $!;
binmode $out;
print $out $image->png;
close $out;

