#!/usr/bin/perl

# This short script shows you how to read in the MARC file "marc.dat"
# (located in the 't' directory), and convert it XML.

use lib '../blib/lib';
use MARC::XML;

my $file = "marc.dat";
my $testfile = "t/marc.dat";
my $egfile = "../t/marc.dat";
if (-e $testfile) {
    $file = $testfile;
}
elsif (-e $egfile) {
    $file = $egfile;
}
unless (-e $file) {
    die "No MARC sample file found\n";
}

$mymarc = MARC::XML->new($file,"usmarc");
$mymarc->output({file=>">output.xml",format=>"xml"});

