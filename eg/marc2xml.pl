#!/usr/bin/perl

# This short script allows you to perform MARC -> XML conversions from the 
# command line. For example:

# Unix:
# marc2xml.pl inputfile.mrc outputfile.xml

# WinXX
# perl marc2xml.pl inputfile.mrc outputfile.xml

($input, $output) = @ARGV;

use MARC::XML;

if (not (-f $input)) { die "Input file \"$input\" does not exist!"}
if (not ($output)) { die "You must specify an output file!"}

$mymarc = MARC::XML->new($input,"usmarc");
$mymarc->output({file=>">$output",format=>"xml"});

