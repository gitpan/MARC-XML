#!/usr/bin/perl

# This short script allows you to perform XML -> MARC conversions from the 
# command line. For example:

# Unix:
# xml2marc.pl inputfile.xml outputfile.mrc

# WinXX
# perl xml2marc.pl inputfile.xml outputfile.mrc

($input, $output) = @ARGV;

use MARC::XML;

if (not (-f $input)) { die "Input file \"$input\" does not exist!"}
if (not ($output)) { die "You must specify an output file!"}

$mymarc = MARC::XML->new($input,"xml");
$mymarc->output({file=>">$output",format=>"usmarc"});









