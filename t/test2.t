#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test1.t'

use lib '.','./t';	# for inheritance and Win32 test
use lib './blib/lib','../blib/lib','./lib','../lib','..';
# can run from here or distribution base

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..81\n"; }
END {print "not ok 1\n" unless $loaded;}
use MARC::XML 0.3;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

use strict;

my $tc = 2;		# next test number

use strict;
use File::Compare;

sub out_cmp {
    my $outfile = shift;
    my $reffile = shift;
    if (-s $outfile && -s $reffile) {
        return is_zero (compare($outfile, $reffile));
    }
    printf ("not ok %d\n",$tc++);
}

sub is_zero {
    my $result = shift;
    if (defined $result) {
        return is_ok ($result == 0);
    }
    printf ("not ok %d\n",$tc++);
}

sub is_ok {
    my $result = shift;
    printf (($result ? "" : "not ")."ok %d\n",$tc++);
    return $result;
}

sub is_bad {
    my $result = shift;
    printf (($result ? "not " : "")."ok %d\n",$tc++);
    return (not $result);
}

my $file = "makrbrkr.mrc";
my $file2 = "brkrtest.ref";
my $file3 = "makrtest.src";
my $file4 = "ansel.ent";

my $testdir = "t";
if (-d $testdir) {
    $file = "$testdir/$file";
    $file2 = "$testdir/$file2";
    $file3 = "$testdir/$file3";
    $file4 = "$testdir/$file4";
}
unless (-e $file) {
    die "Missing sample file for MARCMaker tests: $file\n";
}
unless (-e $file2) {
    die "Missing results file for MARCBreaker tests: $file2\n";
}
unless (-e $file3) {
    die "Missing source file for MARCMaker tests: $file3\n";
}
unless (-e $file4) {
    die "Missing declaration file for XML tests: $file4\n";
}

my $naptime = 0;	# pause between output pages
if (@ARGV) {
    $naptime = shift @ARGV;
    unless ($naptime =~ /^[0-5]$/) {
	die "Usage: perl test?.t [ page_delay (0..5) ]";
    }
}

my $x;
unlink 'output.txt', 'output.html', 'output3.xml', 'output.isbd',
       'output.urls', 'output2.bkr', 'output.mkr', 'output.bkr';

   # Create the new MARC::XML object. You can use any variable name you like...
   # Read the MARCMaker file into the MARC::XML object.

unless (is_ok ($x = MARC::XML->new($file3,"marcmaker"))) {	# 2
    die "could not create MARC::XML from $file3\n";
    # next test would die at runtime without $x
}

is_ok (8 == $x->marc_count);					# 3

   #Output the MARC::XML object to a marcmaker file with nolinebreak
is_ok ($x->output({file=>">output.bkr",'format'=>"marcmaker",
	nolinebreak=>'y'}));					# 4
out_cmp ("output.bkr", $file2);					# 5

   # rebuild directory and length data
my $y;
is_ok ($y = $x->output({'format'=>"marc"}));			# 6

   #Output the MARC::XML object to an ascii file
is_ok ($x->output({file=>">output.txt",'format'=>"ASCII"}));	# 7

   #Output the MARC::XML object to a marcmaker file
is_ok ($x->output({file=>">output2.bkr",'format'=>"marcmaker"}));	# 8

   #Output the MARC::XML object to a marc file
is_ok ($x->output({file=>">output.mkr",'format'=>"marc"}));	# 9

out_cmp ("output.mkr", $file);					# 10
$^W = 0;

   #Output the MARC::XML object to an xml file without DTD
   # lineterm, encoding, charset, and standalone specify defaults
is_ok ($x->output({file=>">output3.xml",'format'=>"xml"}));	# 11 
my $head1 = '<?xml version="1.0" encoding="US-ASCII" standalone="%s"?>'."\n";
my $head2 = "<!DOCTYPE marc SYSTEM \"$file4\">\n";
my $head3 = '<field type="000">01201nam  2200253 a 4500</field>'."\n";

is_ok(open CF, "output3.xml");					# 12
my @xml_file = <CF>;
close CF;

is_ok(sprintf($head1, "yes") eq shift @xml_file);		# 13
is_ok("<marc>\n" eq shift @xml_file);				# 14
is_ok("\n" eq shift @xml_file);					# 15
is_ok("<record>\n" eq shift @xml_file);				# 16
is_ok($head3 eq shift @xml_file);				# 17
is_ok("</marc>\n" eq pop @xml_file);				# 18
is_ok("\n" eq pop @xml_file);					# 19
is_ok("</record>\n" eq pop @xml_file);				# 20
is_ok("</field>\n" eq pop @xml_file);				# 21

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

   # Output the MARC::XML object to an xml file with DTD
   # lineterm, encoding, charset, and standalone specify defaults
is_ok ($x->output({file=>">output3.xml",'format'=>"xml",
		   dtd_file=>"$file4"}));			# 22

is_ok(open CF, "output3.xml");					# 23
@xml_file = <CF>;
close CF;

is_ok(sprintf($head1, "no") eq shift @xml_file);		# 24
is_ok($head2 eq shift @xml_file);				# 25
is_ok("<marc>\n" eq shift @xml_file);				# 26
is_ok("\n" eq shift @xml_file);					# 27
is_ok("<record>\n" eq shift @xml_file);				# 28
is_ok($head3 eq shift @xml_file);				# 29
is_ok("</marc>\n" eq pop @xml_file);				# 30
is_ok("\n" eq pop @xml_file);					# 31
is_ok("</record>\n" eq pop @xml_file);				# 32
is_ok("</field>\n" eq pop @xml_file);				# 33

my $m;
unless (is_ok ($m = MARC::XML->new("output3.xml"))) {		# 34
    die "could not create MARC::XML from output3.xml\n";
    # next test would die at runtime without $m
}
is_ok (8 == $m->marc_count);					# 35

   # rebuild directory and length data
my $z;
is_ok ($z = $m->output({'format'=>"marc"}));			# 36
is_ok ($y eq $z);						# 37

undef $m;
undef $z;

my ($m000) = $x->getvalue({record=>'1',field=>'000'});
my ($m001) = $x->getvalue({record=>'1',field=>'001'});
is_ok ($m000 eq "01201nam  2200253 a 4500");			# 38
is_ok ($m001 eq "tes96000001 ");				# 39

my ($m002) = $x->getvalue({record=>'1',field=>'002'});
my ($m003) = $x->getvalue({record=>'1',field=>'003'});
is_bad (defined $m002);						# 40
is_ok ($m003 eq "ViArRB");					# 41

my ($m004) = $x->getvalue({record=>'1',field=>'004'});
my ($m005) = $x->getvalue({record=>'1',field=>'005'});
is_bad (defined $m004);						# 42
is_ok ($m005 eq "199602210153555.7");				# 43

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

my ($m006) = $x->getvalue({record=>'1',field=>'006'});
my ($m007) = $x->getvalue({record=>'1',field=>'007'});
is_bad (defined $m006);						# 44
is_bad (defined $m007);						# 45

my ($m008) = $x->getvalue({record=>'1',field=>'008'});
my ($m009) = $x->getvalue({record=>'1',field=>'009'});
is_ok ($m008 eq "960221s1955    dcuabcdjdbkoqu001 0deng d");	# 46
is_bad (defined $m009);						# 47

my ($m260a) = $x->getvalue({record=>'8',field=>'260',subfield=>'a'});
my ($m260b) = $x->getvalue({record=>'8',field=>'260',subfield=>'b'});
my ($m260c) = $x->getvalue({record=>'8',field=>'260',subfield=>'c'});
is_ok ($m260a eq "Washington, DC :");				# 48
is_ok ($m260b eq "Library of Congress,");			# 49
is_ok ($m260c eq "1955.");					# 50

my @m260 = $x->getvalue({record=>'8',field=>'260'});
is_ok ($m260[0] eq "Washington, DC : Library of Congress, 1955. ");	# 51

my ($m245i1) = $x->getvalue({record=>'8',field=>'245',subfield=>'i1'});
my ($m245i2) = $x->getvalue({record=>'8',field=>'245',subfield=>'i2'});
my ($m245i12) = $x->getvalue({record=>'8',field=>'245',subfield=>'i12'});
is_ok ($m245i1 eq "1");						# 52
is_ok ($m245i2 eq "2");						# 53
is_ok ($m245i12 eq "12");					# 54

is_ok (3 == $x->selectmarc(["1","7-8"]));			# 55
is_ok (3 == $x->marc_count);					# 56

my @records=$x->searchmarc({field=>"020"});
is_ok(2 == scalar @records);					# 57
is_ok($records[0] == 2);					# 58
is_ok($records[1] == 3);					# 59

@records=$x->searchmarc({field=>"020",subfield=>"c"});
is_ok(1 == scalar @records);					# 60
is_ok($records[0] == 3);					# 61

@records = $x->getupdate({field=>'020',record=>2});
is_ok(7 == @records);						# 62

is_ok($records[0] eq "i1");					# 63
is_ok($records[1] eq " ");					# 64

if ($naptime) {
    print "++++ page break\n";
    sleep $naptime;
}

is_ok($records[2] eq "i2");					# 65
is_ok($records[3] eq " ");					# 66
is_ok($records[4] eq "a");					# 67
is_ok($records[5] eq "8472236579");				# 68
is_ok($records[6] eq "\036");					# 69

is_ok(1 == $x->deletemarc({field=>'020',record=>2}));		# 70
$records[6] = "c";
$records[7] = "new data";
is_ok($x->addfield({field=>'020',record=>2}, @records));	# 71

@records=$x->searchmarc({field=>"020",subfield=>"c"});
is_ok(2 == scalar @records);					# 72
is_ok($records[0] == 2);					# 73
is_ok($records[1] == 3);					# 74

@records = $x->getvalue({record=>'2',field=>'020',delimiter=>'|'});
is_ok(1 == scalar @records);					# 75
is_ok($records[0] eq "|a8472236579|cnew data");			# 76

is_ok(1 == $x->deletemarc({field=>'020',record=>2,subfield=>'c'}));	# 77
@records=$x->searchmarc({field=>"020",subfield=>"c"});
is_ok(1 == scalar @records);					# 78
is_ok($records[0] == 3);					# 79

@records = $x->getvalue({record=>'2',field=>'020',delimiter=>'|'});
is_ok(1 == scalar @records);					# 80
is_ok($records[0] eq "|a8472236579");				# 81

