#!/usr/bin/perl
# $Id$
#
# RRD script to display io stats
# 2003 (c) by Christian Garbs <mitch@cgarbs.de>
# Licensed under GNU GPL.
#
# This script should be run every 5 minutes.
#
use strict;
use warnings;
use RRDs;
use List::Util qw(min);
use File::Basename;

# whoami?
my $hostname = `/bin/hostname`;
chomp $hostname;

my $basename = basename($0);
my $dirname = dirname($0);
my $module = "$dirname/modules/$basename";

print "running module $module...\n";

# parse configuration file
my %conf;
eval(`cat ~/.rrd-conf.pl`);

# set variables

my $batchrun = 1;

my $content;
open FH, "<", $module or die "Can't open $module\n";
read FH, $content, 9999999;
eval $content;
close FH;
