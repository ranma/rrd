#!/usr/bin/perl
# $Id: cgroupcache.pl,v 1.17 2007/04/04 22:02:20 mitch Exp $
#
# RRD script to display cgroup usage
# 2003 (c) by Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL.
#
# This script should be run every 5 minutes.
#
use strict;
use warnings;
use RRDs;

# set variables
my $datafile = "$conf{DBPATH}/cgroupcache.rrd";
my $picbase  = "$conf{OUTPATH}/cgroupcache-";

# watch these paths
my @path = @{$conf{'PROGMEM_CGROUPS'}};
my $paths = grep { $_ ne "" } @path;
my @size;

# global error variable
my $ERR;

# generate database if absent
if ( ! -e $datafile ) {
    # max 100% for each value
    RRDs::create($datafile,
		 "--step=60",
		 "DS:cgroup00:GAUGE:120:0:8000000000",
		 "DS:cgroup01:GAUGE:120:0:8000000000",
		 "DS:cgroup02:GAUGE:120:0:8000000000",
		 "DS:cgroup03:GAUGE:120:0:8000000000",
		 "DS:cgroup04:GAUGE:120:0:8000000000",
		 "DS:cgroup05:GAUGE:120:0:8000000000",
		 "DS:cgroup06:GAUGE:120:0:8000000000",
		 "DS:cgroup07:GAUGE:120:0:8000000000",
		 "DS:cgroup08:GAUGE:120:0:8000000000",
		 "DS:cgroup09:GAUGE:120:0:8000000000",
		 "DS:cgroup10:GAUGE:120:0:8000000000",
		 "DS:cgroup11:GAUGE:120:0:8000000000",
		 "DS:cgroup12:GAUGE:120:0:8000000000",
		 "DS:cgroup13:GAUGE:120:0:8000000000",
		 "DS:cgroup14:GAUGE:120:0:8000000000",
		 "DS:cgroup15:GAUGE:120:0:8000000000",
		 "DS:cgroup16:GAUGE:120:0:8000000000",
		 "DS:cgroup17:GAUGE:120:0:8000000000",
		 "DS:cgroup18:GAUGE:120:0:8000000000",
		 "DS:cgroup19:GAUGE:120:0:8000000000",
		 "RRA:AVERAGE:0.5:1:600",
#		 "RRA:AVERAGE:0.5:2.4:600",
		 "RRA:AVERAGE:0.5:2:720",
#		 "RRA:AVERAGE:0.5:16.8:600",
		 "RRA:AVERAGE:0.5:16:630",
		 "RRA:AVERAGE:0.5:72:600",
		 "RRA:AVERAGE:0.5:876:600"
		 );

      $ERR=RRDs::error;
      die "ERROR while creating $datafile: $ERR\n" if $ERR;
      print "created $datafile\n";
}

# build reverse lookup hash and initialize array
my %path;
for my $idx ( 0..19 ) {
    $path{ $path[$idx] } = $idx;
    $size[ $idx ] = "U";

    my $fname = "/cgroup/$path[$idx]/memory.stat";
    if ($path[$idx] eq "default") {
    	$fname = "/cgroup/memory.stat";
    }
    if (-e $fname && $path[$idx] ne "") {
	open STAT, $fname or die "can't open $fname: $!";
	while (my $line = <STAT>) {
		if ($line =~ /^total_cache ([0-9]+)/) {
			$size[$idx] = $1;
			#print "$path[$idx] $size[$idx]\n";
		}
	}
	close STAT;
    }
}

## parse df
#open DF, "df -P -l|" or die "can't open df: $!";
#while ( my $line = <DF> ) {
#    chomp $line;
#    if ($line =~ /\s(\d{1,3})% (\/.*)$/) {
#	$size[ $path{ $2 } ] = $1 if ( exists $path{ $2 } );
#    }
#}
#close DF or die "can't close df: $!";

# update database
my $string='N';
for my $idx ( 0..19 ) {
    $string .= ":" . ( $size[$idx] );
}
RRDs::update($datafile,
	     $string
	     );
$ERR=RRDs::error;
die "ERROR while updating $datafile: $ERR\n" if $ERR;

# set up colorspace
my $drawn = 0;
my @colors = qw(
		00F0F0
		F0F040
		F000F0
		00F000
		0000F0
		000000
		C0C0C0
		F00000
		F09000
		808080
		009000
		FF0000
		000090
		900090
		009090
		909000
		E00070
		2020F0
		FF00FF
	       );

# draw which values?
my (@def, @line, @gprint);
for my $idx ( 0..19 ) {
    if ( $path[$idx] ne "" ) {
	my $color = $colors[$drawn];
	push @def, sprintf 'DEF:cgroup%02d=%s:cgroup%02d:AVERAGE', $idx, $datafile, $idx;
	push @line, sprintf 'LINE2:cgroup%02d#%s:%s', $idx, $color, $path[$idx];
	$drawn ++;
#	push @gprint, sprintf 'GPRINT:cgroup%02d:AVERAGE:%%9.0lf', $idx;
#	push @gprint, sprintf 'GPRINT:cgroup%02d:MIN:%%9.0lf', $idx;
#	push @gprint, sprintf 'GPRINT:cgroup%02d:MAX:%%9.0lf', $idx;
#	push @gprint, sprintf 'COMMENT:%s\n', $path[$idx];
    }
}

# draw pictures
foreach ( [3600, "hour"], [86400, "day"], [604800, "week"], [31536000, "year"] ) {
    my ($time, $scale) = @{$_};
    RRDs::graph($picbase . $scale . ".png",
		"--start=-$time",
		'--lazy',
		'--imgformat=PNG',
		"--title=${hostname} cgroup cache usage (last $scale)",
		'--upper-limit=100',
		"--width=$conf{GRAPH_WIDTH}",
		"--height=$conf{GRAPH_HEIGHT}",
                '--lower-limit=0',
                '--upper-limit=100',

		@def,

		@line,

#		'COMMENT:\n',
#		'COMMENT:\n',
#		'COMMENT:AVG        MIN        MAX        cgroup\n',
#		@gprint
		);
    $ERR=RRDs::error;
    die "ERROR while drawing $datafile $time: $ERR\n" if $ERR;
}

