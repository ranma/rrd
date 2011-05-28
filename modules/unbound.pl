#!/usr/bin/perl -w
#
# RRD script to display unbound statistics
# 2011 Copyright (C)  Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL v3 or later.
#
# This script should be run every 5 minutes.
#

# set variables
my $datafile = "$conf{DBPATH}/unbound.rrd";
my $picbase  = "$conf{OUTPATH}/unbound-";

# global error variable
my $ERR;

# generate database if absent
if ( ! -e $datafile ) {
    RRDs::create($datafile,
		 "--step=60",
		 "DS:hit:ABSOLUTE:600:0:150000",
		 "DS:miss:ABSOLUTE:600:0:150000",
		 "DS:time_avg:GAUGE:600:0:30",
		 "DS:time_median:GAUGE:600:0:30",
		 'RRA:AVERAGE:0.5:1:600',
		 'RRA:AVERAGE:0.5:6:700',
		 'RRA:AVERAGE:0.5:24:775',
		 'RRA:AVERAGE:0.5:288:797',
		 'RRA:MAX:0.5:1:600',
		 'RRA:MAX:0.5:6:700',
		 'RRA:MAX:0.5:24:775',
		 'RRA:MAX:0.5:288:797'
		 );
      $ERR=RRDs::error;
      die "ERROR while creating $datafile: $ERR\n" if $ERR;
      print "created $datafile\n";
}

# get data
open STATUS, '/usr/sbin/unbound-control stats|' or die "can't open unbound-control: $!";
my %stats = (
    'total.num.cachehits' => 0,
    'total.num.cachemiss' => 0,
    'total.recursion.time.avg' => 0,
    'total.recursion.time.median' => 0,
);
while (my $line = <STATUS>) {
    chomp $line;
    my ($key, $value) = split /=/, $line, 2;
    $stats{$key} = $value;
}
close STATUS or die "can't close unbound-control: $!";

# update database
RRDs::update($datafile,
	     "N:$stats{'total.num.cachehits'}:$stats{'total.num.cachemiss'}:$stats{'total.recursion.time.avg'}:$stats{'total.recursion.time.median'}"
	     );
$ERR=RRDs::error;
die "ERROR while updating $datafile: $ERR\n" if $ERR;

# draw pictures
foreach ( [3600, "hour"], [86400, "day"], [604800, "week"], [31536000, "year"] ) {
    my ($time, $scale) = @{$_};
    RRDs::graph($picbase . $scale . ".png",
		"--start=-${time}",
		'--lazy',
		'--imgformat=PNG',
		"--title=${hostname} unbound stats (last $scale)",
		"--width=$conf{GRAPH_WIDTH}",
		"--height=$conf{GRAPH_HEIGHT}",
		
		"DEF:hit=${datafile}:hit:AVERAGE",
		"DEF:miss_o=${datafile}:miss:AVERAGE",
		"DEF:hit_max=${datafile}:hit:MAX",
		"DEF:miss_o_max=${datafile}:miss:MAX",
		'CDEF:miss=0,miss_o,-',
		'CDEF:miss_max=0,miss_o_max,-',

		"DEF:time_avg_o=${datafile}:time_avg:AVERAGE",
		"DEF:time_median=${datafile}:time_median:AVERAGE",
		'CDEF:time_avg=0,time_avg_o,-',
		
		'AREA:hit_max#D0FFD0:max hit',
		'AREA:miss_max#FFD0D0:max miss',
		'AREA:hit#00F000:avg hit',
		'AREA:miss#F00000:avg miss',
		'LINE1:time_median#0000F0:median time [s]',
		'LINE1:time_avg#0000F0:avg time [-s]',
		'COMMENT:\n',
		);
    $ERR=RRDs::error;
    die "ERROR while drawing $datafile $time: $ERR\n" if $ERR;
}
