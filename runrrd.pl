#!/usr/bin/perl
#
# RRD script stub to run all configured modules
# 2011 (c) by Tobias Diedrich <ranma+github@tdiedrich.de>
# Licensed under GNU GPL.
#
use strict;
use warnings;
use RRDs;

# parse configuration file
my %conf;
#my $return = do "/root/.rrd-conf.pl"; # does not work?!?
#print "return=$return run_modules=";
#print $conf{RUN_MODULES};
eval `/bin/cat ~/.rrd-conf.pl`;

# whoami?
my $hostname = `/bin/hostname`;
chomp $hostname;

my @modules = @{$conf{RUN_MODULES}};

foreach my $module (@modules) {
	my $time = time();
	my $content;
#	my $pid = fork();
#	if ($pid == 0) {
		print "Running module $module: ";
		open FH, "<", "modules/$module";
		read FH, $content, 9999999;
		eval $content;
		close FH;
		$time = time() - $time;
		print "$time seconds\n";
#		exit(0);
#	}
}
my $pid;
while (($pid = wait()) != -1) { print "pid $pid done\n"};
print "Done.\n";
