MARC::XML (XML extensions for MAchine Readable Cataloging)
VERSION=0.25, 23 November 1999

This is a cross-platform module. All of the files except README.txt
are LF-only terminations. You will need a better editor than Notepad
to read them on Win32. README.txt is README with CRLF.

DESCRIPTION:

MARC.pm is a Perl 5 module for reading in, manipulating, and outputting
bibliographic records in the USMARC format. You will need to have Perl
5.004 or greater for MARC.pm to work properly. MARC::XML adds support
for converting to and from XML format files. You will need to have both
the MARC and XML::Parser modules installed (both available from CPAN,
XML::Parser is included in Win32 Perl versions 5.005 and above - it is
required by PPM).

MARC::XML can output both single and batches of MARC records. The limit on
the number of records in a batch is determined by the memory capacity of
the machine you are running. The nature of XML::Parser requires reading
a complete XML file during input.

FILES:

    Changes		- for history lovers
    Makefile.PL		- the "starting point" for traditional reasons
    MANIFEST		- file list
    README		- this file for CPAN
    README.txt		- this file for DOS
    XML.pm		- the reason you're reading this

    t			- test directory
    t/marc.dat		- two record data file for testing
    t/test1.t		- basic tests, search, update - MARC input
    t/test2.t		- MARCMaker format tests
    t/test3.t		- Inheritance version of test1.t
    t/test4.t		- XML input version of test1.t
    t/MARCopt.pm	- Inheritance stub module
    t/makrbrkr.mrc	- LoC. MARCMaker reference records
    t/makrtest.src	- MARCMaker source for makrbrkr.mrc
    t/brkrtest.ref	- MARCBreaker output from makrbrkr.mrc

    eg			- example directory
    eg/simple.pl	- converts t/marc.dat into output.xml
    eg/marc2xml.pl	- simple command line converter
    eg/xml2marc.pl	- another simple command line converter
    eg/README		- instructions for examples

INSTALL and TEST:

On linux and Unix, this distribution uses Makefile.PL and the "standard"
install sequence for CPAN modules:
	perl Makefile.PL
	make
	make test
	make install

On Win32, Makefile.PL creates equivalent scripts for the "make-deprived"
and follows a similar sequence.
	perl Makefile.PL
	perl test.pl
	perl install.pl

Both sequences create install files and directories. The test uses a
small sample input file and creates outputs in various formats. You can
specify an optional PAUSE (0..5 seconds) between pages of output. The
'perl t/test1.pl PAUSE' form works on all OS types. The test will
indicate if any unexpected errors occur (not ok).

Once you have installed, you can check if Perl can find it. Change to
some other directory and execute from the command line:

            perl -e "use MARC"

No response that means everything is OK! If you get an error like
* Can't locate method "use" via package MARC *, then Perl is not
able to find MARC.pm--double check that the file copied it into the
right place during the install.

NOTES:

Please let us know if you run into any difficulties using MARC::XML --
We'd be happy to try to help. Also, please contact us if you notice any
bugs, or if you would like to suggest an improvement/enhancement. Email
addresses are listed at the bottom of this page.

The module is provided in standard CPAN distribution format. Additional
documentation is created during the installation (html and man formats).
See the MARC module documentation for more detail on inherited methods.

Download the latest version from CPAN or:

    http://libstaff.lib.odu.edu/depts/systems/iii/scripts/MARCpm

AUTHORS:

    Chuck Bearden cbearden@rice.edu
    Bill Birthisel wcbirthisel@alum.mit.edu
    Charles McFadden chuck@vims.edu
    Ed Summers esummers@odu.edu
    Derek Lane dereklane@pobox.com

COPYRIGHT

Copyright (C) 1999, Bearden, Birthisel, Lane, McFadden, and Summers.
All rights reserved. This module is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.
Portions Copyright (C) 1999, Duke University, Lane.
