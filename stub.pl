#!/usr/bin/perl
#
# RRD script stub to run a module
# 2011 (c) by Tobias Diedrich <ranma+github@tdiedrich.de>
# Licensed under GNU GPL.
#
# Create a symlink to this script (e.g. network.pl -> stub.pl) and it will set
# up the environment and run a the corresponding script from the modules
# subdirectory.
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

my $content;
open FH, "<", $module or die "Can't open $module\n";
read FH, $content, 9999999;
eval $content;
close FH;
