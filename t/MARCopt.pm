package MARCopt;
# Inheritance test for test3.t only

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.25';
require Exporter;
use MARC::XML;
@ISA = qw( Exporter MARC::XML );
@EXPORT= qw();
@EXPORT_OK= @MARC::XML::EXPORT_OK;
%EXPORT_TAGS = %MARC::XML::EXPORT_TAGS;

print "MARCopt inherits from MARC::XML\n";
1;
