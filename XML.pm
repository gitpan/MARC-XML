package MARC::XML;

use Carp;
use strict;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $DEBUG);

require 5.004;
require Exporter;
use MARC 1.00;
use XML::Parser; 

$VERSION = 0.25;
$DEBUG = 0;
@ISA = qw(Exporter MARC);
@EXPORT= qw();
@EXPORT_OK= qw();

#### Not using these yet

#### %EXPORT_TAGS = (USTEXT	=> [qw( marc2ustext )]);
#### Exporter::export_ok_tags('USTEXT');
#### $EXPORT_TAGS{ALL} = \@EXPORT_OK;

####################################################################
# variables used in subroutines called by parser                   #
####################################################################

my $count;
my $field;
my @subfields;
my $subfield;
my $i1;
my $i2;
my $fieldvalue;
my $subfieldvalue;
my $recordnum;
my $marc_obj;
my $reorder;

####################################################################
# handlers for the XML elements, the so called "subs style".       #
####################################################################

sub record {
	$count++;
}

sub field {
	(my $expat, my $el, my %atts)=@_;
	$field=$atts{'type'};
	if ($field>9) {
	    $i1=$atts{i1};
	    $i2=$atts{i2};
	}
}

sub field_ {
	(my $expat, my $el)=@_;
	if ($field eq "000") {
	    $recordnum=$marc_obj->createrecord({leader=>$fieldvalue});
	}	
	elsif ($field < 10) {
	    $marc_obj->addfield({
		record=>$recordnum,
		field=>$field,
		ordered=>$reorder,
		value=>[$fieldvalue]
		});
	}
	else {
	    my $subcommand;
	    for (my $i=0; $i<$#subfields; $i=$i+2) {
		$subcommand.="$subfields[$i]=>\"$subfields[$i+1]\",";
	    }
	    chop($subcommand);
	    $marc_obj->addfield({
		record=>$recordnum,
		field=>$field,
		ordered=>$reorder,
		i1=>$i1,
		i2=>$i2,
		value=>[eval($subcommand)]
		});
	}
	$field=undef;
	$i1=undef;
	$i2=undef;
	$fieldvalue=undef;
	@subfields=();
}

sub subfield {
	(my $expat, my $el, my %atts)=@_;
	$subfield=$atts{type};
}

sub subfield_ {
	(my $expat, my $el)=@_;
	push(@subfields,$subfield,$subfieldvalue);
	$subfield=undef;
	$subfieldvalue=undef;
}

sub handle_char {
	(my $expat, my $string)=@_;
	$string=~s/\'/\\\'/g;
	$string=~s/\"/\\\"/g;
	if ($field && not($subfield)) {$fieldvalue.=$string}
	if ($subfield) {$subfieldvalue.=$string}
}

####################################################################
# new() is the constructor method for MARC::XML. new() takes two   #
# arguements which are used to automatically read in the entire    #
# contents of an XML file. If a format other than "xml" is         #
# specified then the MARC.pm new() constructor is called.          #
####################################################################
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $file=shift;
    my $format;
    if ($file) { $format = shift || "xml"; }
    my $rcount;
    my $marc;
    if ($file and $format=~/xml$/oi) {
	$marc = $class->SUPER::new();
	$reorder = shift || "n";
	$rcount = _readxml($marc,$file);
    }
    else {
	$marc = $class->SUPER::new($file,$format);
    }
    bless($marc,$class);
    return $marc;
}

####################################################################
# the output() method overloads the MARC::output method and allows #
# the user to output a MARC object as XML to a file or into a      #
# variable. If the format parameter is not used "xml" is assumed,  #
# and if the format is declared but it doesn't match "xml",        #
# "xml_header", "xml_body", or "xml_footer" then the output        #
# command is passed up to the MARC package to see what can be done #
# with it there.                                                   #
####################################################################
sub output {
    (my $marc, my $params)=@_;
    my $file=$params->{file};
    my $newline = $params->{lineterm} || "\n";
    my $output="";
    unless (exists $params->{'format'}) {
        $params->{'format'} = "xml";
        $params->{lineterm} = $newline;
    }
    if ($params->{'format'} =~ /xml$/oi) {
        $output .="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>$newline$newline<marc>$newline$newline";
	$output .= _marc2xml($marc,$params);
        $output .= "</marc>$newline";
    }
    elsif ($params->{'format'} =~ /xml_header$/oi) {
        $output .="<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>$newline$newline<marc>$newline$newline";
    }
    elsif ($params->{'format'} =~ /xml_body$/oi) {
	$output=_marc2xml($marc,$params);
    }
    elsif ($params->{'format'} =~ /xml_footer$/oi) {
	$output="</marc>$newline";
    }
    else {
	return $marc->SUPER::output($params);
    }    
       #output to a file or return the $output
    if ($params->{file}) {
	if ($params->{file} !~ /^>/) {carp "Don't forget to use > or >>: $!"}
	open (OUT, "$params->{file}") || carp "Couldn't open file: $!";
        binmode OUT;
	print OUT $output;
	close OUT || carp "Couldn't close file: $!";
	return 1;
    }
      #if no filename was specified return the output so it can be grabbed
    else {
	return $output;
    }
}
    
####################################################################
# _readxml is an internal subroutine for reading in MARC data that #
# is encoded in XML. It is called via new()                        #
# XML::Parser must be installed in your Perl library for this to   #
# work. If no records are read in an error will be generated.      #
####################################################################
sub _readxml {
    $marc_obj = shift;
    my $file = shift;
       #create the parser object and parse the xml file
    my $xmlfile = new XML::Parser(Style=>'Subs');
    $xmlfile->setHandlers(Char => \&handle_char);
    $xmlfile->parsefile($file);
    unless ($count) {carp "Error reading XML $!";}
    return $count;    
}

####################################################################
# _marc2xml takes a MARC object as its input and converts it into  #
# XML. The XML is returned as a string                             #
####################################################################
sub _marc2xml {
    my ($marc,$params)=@_;
    my $output;
    my $newline = $params->{lineterm} || "\n";
    my @records;
    if ($params->{records}) {@records=@{$params->{records}}}
    else {for (my $i=1;$i<=$#$marc;$i++) {push(@records,$i)}}
    foreach my $i (@records) {
	my $recout=$marc->[$i]; #cycle through each record
	$output.="<record>$newline";
	foreach my $fields (@{$recout->{array}}) { #cycle through each field 
	    my $tag=$fields->[0];
	    if ($tag<10) { #no indicators or subfields
	          #replace & < > with their corresponding entities 
		my $value=$fields->[1];
		$value=~s/&/&amp;/og; $value=~s/</&lt;/og; $value=~s/>/&gt;/og;
		$output.=qq(<field type="$tag">$value</field>$newline);
	    }
	    else { #indicators and subfields
		$output.=qq(<field type="$tag" i1="$fields->[1]" i2="$fields->[2]">$newline);
		my @subfldout = @{$fields}[3..$#{$fields}];		
		while (@subfldout) { #cycle through subfields
		    my $subfield_type = shift(@subfldout);
		    my $subfield_value = shift(@subfldout);
		    $subfield_value=~s/&/&amp;/og;
		    $subfield_value=~s/</&lt;/og;
		    $subfield_value=~s/>/&gt;/og;
		    $output .= qq(   <subfield type="$subfield_type">);
		    $output .= qq($subfield_value</subfield>$newline);
		} #finish cycling through subfields
		$output .= qq(</field>$newline);
	    } #finish tag test < 10
	}
	$output.="</record>$newline$newline"; #put an extra newline to separate records
    }
    return $output;
}

return 1;

__END__


####################################################################
#                  D O C U M E N T A T I O N                       #
####################################################################

=pod

=head1 NAME

MARC::XML - A subclass of MARC.pm to provide XML support.

=head1 SYNOPSIS

    use MARC::XML;

    #read in some MARC and output some XML
    $myobject = MARC::XML->new("marc.mrc","usmarc");
    $myobject->output({file=>">marc.xml",format=>"xml"});

    #read in some XML and output some MARC
    $myobject = MARC::XML->new("marc.xml","xml");
    $myobject->output({file=>">marc.mrc","usmarc");

=head1 DESCRIPTION

MARC::XML is a subclass of MARC.pm which provides methods for round-trip
conversions between MARC and XML. MARC::XML requires that you have the
CPAN modules MARC.pm and XML::Parser installed in your Perl library.
As a subclass of MARC.pm a MARC::XML object will by default have the full
functionality of a MARC.pm object. See the MARC.pm documentation for details.

The XML file that is read and generated by MARC::XML is not associated with a 
Document Type Definition (DTD). This means that your files need to be
well-formed, but they will not be validated. When performing XML->MARC
conversion it is important that the XML file is structured in a particular
way. Fortunately, this is the same format that is generated by the MARC->XML
conversion, so you should be able to be able to move your data easily between
the two formats.

=head2 Downloading and Intalling

=over 4

=item Download

First make sure that you have B<MARC.pm> and B<XML::Parser> installed.
Both Perl extensions are available from the CPAN
http://www.cpan.org/modules/by-module, and they must be available in 
your Perl library for MARC::XML to work properly.

MARC::XML is provided in standard CPAN distribution format. Download the
latest version from http://www.cpan.org/modules/by-module/MARC/XML. It will
extract into a directory MARC-XML-version with any necessary subdirectories.
Once you have extracted the archive Change into the MARC-XML top directory
and execute the following command depending on your platform.

=item Unix

    perl Makefile.PL
    make
    make test
    make install

=item Win9x/WinNT/Win2000

    perl Makefile.PL
    perl test.pl
    perl install.pl

=item Test

Once you have installed, you can check if Perl can find it. Change to some
other directory and execute from the command line:

    perl -e "use MARC::XML"

If you B<do not> get any response that means everything is OK! If you get an
error like I<Can't locate method "use" via package MARC::XML>.
then Perl is not able to find MARC::XML--double check that the file copied
it into the right place during the install.

=back

=head2 Todo

=over 4

=item *

Checking for field and record lengths to make sure that data read in from
an XML file does not exceed the limited space available in a MARC record.

=item *

Support for MARC E<lt>-E<gt> Unicode character conversions.

=item *

MARC E<lt>-E<gt> EAD (Encoded Archival Description) conversion?

=item *

Support for MARC E<lt>-E<gt> DC/RDF (Dublin Core Metadata encoded in the
Resource Description Framework)?

=item *

Support for MARC E<lt>-E<gt> FGDC Metadata (Federal Geographic Data Committee)
conversion?

=back

=head2 Web Interface

A web interface to MARC.pm and MARC::XML is available at
http://libstaff.lib.odu.edu/cgi-bin/marc.cgi where you can upload records and
observe the results. If you'd like to check out the cgi script take a look at
http://libstaff.lib.odu.edu/depts/systems/iii/scripts/MARCpm/marc-cgi.txt
However, to get the full functionality you will want to install MARC.pm and
MARC::XML on your server or PC.

=head2 Sample XML file

Below is an example of the flavor of XML that MARC::XML will generate and read.
There are only four elements: the I<E<lt>marcE<gt>> pair that serves as the
root for the file; the I<E<lt>recordE<gt>> pair that encloses each record;
the I<E<lt>fieldE<gt>> pair which encloses each field; and the
I<E<lt>subfieldE<gt>> pair which encloses each subfield. In addition the
I<E<lt>fieldE<gt>> and I<E<lt>subfieldE<gt>> tags have three possible
attributes: I<type> which defines the specific tag or subfield ; as well as
I<i1> and I<i2> which allow you to define the indicators for a specific tag.

   <?xml version="1.0" encoding="UTF-8" standalone="yes"?>

   <marc>

   <record>
   <field type="000">00901cam  2200241Ia 45e0</field>
   <field type="001">ocm01047729 </field>
   <field type="003">OCoLC</field>
   <field type="005">19990808143752.0</field>
   <field type="008">741021s1884    enkaf         000 1 eng d</field>
   <field type="040" i1=" " i2=" ">
      <subfield type="a">KSU</subfield>
      <subfield type="c">KSU</subfield>
      <subfield type="d">GZM</subfield>
   </field>
   <field type="090" i1=" " i2=" ">
      <subfield type="a">PS1305</subfield>
      <subfield type="b">.A1 1884</subfield>
   </field>
   <field type="049" i1=" " i2=" ">
      <subfield type="a">VODN</subfield>
   </field>
   <field type="100" i1="1" i2=" ">
      <subfield type="a">Twain, Mark,</subfield>
      <subfield type="d">1835-1910.</subfield>
   </field>
   <field type="245" i1="1" i2="4">
      <subfield type="a">The adventures of Huckleberry Finn :</subfield>
      <subfield type="b">(Tom Sawyer's comrade) : scene, the Mississippi Valley : time, forty to fifty years ago /</subfield>
      <subfield type="c">by Mark Twain (Samuel Clemens) ; with 174 illustrations.</subfield>
   </field>
   <field type="260" i1=" " i2=" ">
      <subfield type="a">London :</subfield>
      <subfield type="b">Chatto &amp; Windus,</subfield>
      <subfield type="c">1884.</subfield>
   </field>
   <field type="300" i1=" " i2=" ">
      <subfield type="a">xvi, 438 p., [1] leaf of plates :</subfield>
      <subfield type="b">ill. ;</subfield>
      <subfield type="c">20 cm.</subfield>
   </field>
   <field type="500" i1=" " i2=" ">
      <subfield type="a">First English ed.</subfield>
   </field>
   <field type="500" i1=" " i2=" ">
      <subfield type="a">State B; gatherings saddle-stitched with wire staples.</subfield>
   </field>
   <field type="500" i1=" " i2=" ">
      <subfield type="a">Advertisements on p. [1]-32 at end.</subfield>
   </field>
   <field type="500" i1=" " i2=" ">
      <subfield type="a">Bound in red S cloth; stamped in black and gold.</subfield>
   </field>
   <field type="510" i1="4" i2=" ">
      <subfield type="a">BAL</subfield>
      <subfield type="c">3414.</subfield>
   </field>
   <field type="740" i1="0" i2="1">
      <subfield type="a">Huckleberry Finn.</subfield>
   </field>
   <field type="994" i1=" " i2=" ">
      <subfield type="a">E0</subfield>
      <subfield type="b">VOD</subfield>
   </field>
   </record>

   </marc>

=head1 METHODS

Here is a list of methods available to you in MARC::XML.

=head2 new()

MARC::XML overides MARC.pm's new() method to create a MARC::XML object. 
Similar to MARC.pm's new() it can take two arguments: a file name, and 
the format of the file to read in. However MARC::XML's new() gives you an 
extra format choice "XML" (which is also the default). Internally, the
XML source is converted to a series of B<addfield()> and B<createrecord()>
calls. The order of MARC tags is preserved by default. But if an optional
third argument is passed to new(), it is used as the I<ordered> option for
the B<addfield()> calls. Due to the nature of XML::Parser, it is not
possible to read only part of an XML input file. Some examples:

      #read in an XML file called myxmlfile.xml
   use MARC::XML;
   $x = MARC::XML->new("myxmlfile.xml","xml");
   $x = MARC::XML->new("needsort.xml","xml","y");

Since the full funtionality of MARC.pm is also available you can read in
other types of files as well. Although new() with no arguments will create
an object with no records, just like MARC.pm, XML format not supported by
openmarc() and nextmarc() for input. But you can output XML from a different
format source.

      #read in a MARC file called mymarcfile.mrc
   use MARC::XML;
   $x = MARC::XML->new("mymarcfile.mrc","usmarc"); 
   $x = MARC::XML->new(); 

=head2 output()

MARC::XML's output() method allows you to output the MARC object as an XML
file. It takes four arguments: I<file>, I<format>, I<lineterm>, and I<records>. 

   use MARC::XML;
   $x = MARC::XML->new("mymarcfile.mrc","usmarc");
   $x->output({file=>">myxmlfile.xml",format=>"xml"});

Or if you only want to output the first record:

   $x->output({file=>">myxmlfile.xml",format=>"xml",records=>[1]});

If you like you can also output portions of the XML file using the I<format> 
options: I<xml_header>, I<xml_body>, and I<xml_footer>. Remember to prefix
your file name with a >> to append though. This example will output
record 1 twice.

   use MARC::XML;
   $x = MARC::XML->new("mymarcfile.mrc","usmarc");
   $x->output({file=>">myxmlfile.xml",format=>"xml_header"});
   $x->output({file=>">>myxmlfile.xml",format=>"xml_body",records=>[1]});
   $x->output({file=>">>myxmlfile.xml",format=>"xml_body",records=>[1]});
   $x->output({file=>">>myxmlfile.xml",foramt=>"xml_footer"});

Instead of outputting to a file, you can also capture the output in a
variable if you wish.

   use MARC::XML;
   $x = MARC::XML->new("mymarcfile.mrc","usmarc");
   $myxml = $x->output({format=>"xml"});

As with new() the full functionality of MARC.pm's output() method are
available to you as well. 
So you could read in an XML file and then output it as ascii text:

   use MARC::XML;
   $x = MARC::XML->new("myxmlfile.xml","xml");
   $x->output({file=>">mytextfile.txt","ascii");

=head1 EXAMPLES

The B<eg> subdirectory contains a few complete examples to get you started.

=head1 AUTHORS

Chuck Bearden cbearden@rice.edu

Bill Birthisel wcbirthisel@alum.mit.edu

Derek Lane dereklane@pobox.com

Charles McFadden chuck@vims.edu

Ed Summers esummers@odu.edu

=head1 SEE ALSO

perl(1), MARC.pm, MARC http://lcweb.loc.gov/marc , XML http://www.w3.org/xml .

=head1 COPYRIGHT

Copyright (C) 1999, Bearden, Birthisel, Lane, McFadden, and Summers.
All rights reserved. This module is free software; you can redistribute
it and/or modify it under the same terms as Perl itself. 23 November 1999.
Portions Copyright (C) 1999, Duke University, Lane.

=cut
