#!/usr/bin/perl -w

# The following example handles two problems encountered by the Pacific
# Film Archive at the University of California, Berkeley. When they tried
# to use an early version of MARC::XML to convert existing records from
# an ancient MS-DOS-based program, they discovered they had records which
# did not fully comply with the MARC specification. They also had questions
# about how portable the resulting XML would be. First, the problems:
#
# 1. The leader "000" field had an illegal character (ASCII NUL = 0x00)
#    in space_22 instead of ASCII '0'. This is invalid for both MARC and
#    XML. But MARC.pm could read it, while MARC::XML.pm considered it a
#    "Fatal Error" (passed through XML::Parser from Expat.pm).
#
# 2. The assignment of special MARC characters was not perfect ANSEL. Some
#    codes were not supported, and the lower-case script "el" used the
#    character code 190 (0xBE) instead of the customary 193 (0xC1).
#
# To maximize portability, it was decided after extensive discussion to
# generate XML limited to the 7-bit-clean "US-ASCII" character set with
# all other characters represented as SGML entities. The conversion uses
# the 1:1 mapping referred to in LoC documents as the "register" set -
# a diacritic_plus_character maps to two entities.

# First, a few administrative details. If you run this from someplace
# other than the "eg" directory of the distribution, you will probably
# need to fix the paths.

    use lib '../blib/lib';
    use MARC::XML 0.3;
    my $infile = "pacific0.dat";
    my $outfile = "output.002";
    my $outfile2 = "output.xml";
    my $outtext = "output.txt";
    my $dtdfile = "../t/ansel.ent";	# used in the test suite
    unlink $outfile, $outtext, $outfile2;

    my $count = 0;
    $x = MARC::XML->new;

# We'll start with the second problem. Since character code 193 (ANSEL
# scriptl) is not assigned in the original records, we only have to
# redefine the "faulty" one to the desired entity. Now either 190 or 193
# will generate '&scriptl' in the XML. It would be equally easy to swap
# two codes or assign a new entity to an unused code.

    my $charhash = $x->ansel_default;		# MARC 8-bit character set
    ${$charhash}{chr(0xbe)} = '&scriptl;';	# latin small letter script l

# While you don't need all of these options in every "output_xx" call, it
# is handy to group them in one place.

    my %xml_options = ( 'file'=>">>$outfile2",
			'lineterm'=>"\n",
			'encoding'=>"US-ASCII",
			'standalone'=>"no",
			'charset'=>$charhash,
			'dtd_file'=>"$dtdfile"
		      );
	# lineterm, encoding, and standalone specify defaults

# Let's get a few "preliminaries" out of the way.

    $x->output_header(\%xml_options);

    $x->openmarc({file=>$infile,'format'=>"usmarc"}) ||
		die "Can't open $infile";

# This loop does all the real work. By processing one record at a time,
# we can handle massive archives.

    while ($x->nextmarc(1)) {

# On to problem one. We fetch the leader and convert it to a hash. Then
# write the desired data in the offending field. We could, if desired,
# validate the entire leader. The 'pack_ldr' updates the record.

        my $leader = $x->unpack_ldr(1);
	die "unpack_ldr problem " unless ($leader);
	${$leader}{len_impl} = '0';
        my $leader2 = $x->pack_ldr(1);

# The next two writes are not essential. The output in "usmarc" format
# will rebuild the directory. But the change made above should not have
# invalidated the old one since we wrote to a "fixed length" field. But
# the contents of $outfile will no longer contain ASCII NUL characters.

        $x->output({file=>">>$outfile",'format'=>"usmarc"});
        $x->output({file=>">>$outtext",'format'=>"ascii"});

# The next one outputs XML complete with the remapped entities.

        $x->output_body(\%xml_options);

# Finish the loop.

        $x->deletemarc(); #empty the object for reading in another
	$count++;
    }

# And clean up when done.

    $x->output_footer(\%xml_options);
    $x->closemarc || die "Can't close $infile";

    print "\nprocessed $count records\n";

