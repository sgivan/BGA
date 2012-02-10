package SeqDB::SpTrEMBL;

# parser for multiple SwissProt/TrEMBL entries files

# $Id: SpTrEMBL.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: SpTrEMBL.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.7  2002/03/01 10:17:57  blinke
# chop -> chomp in parse_callback()
#
# Revision 1.6  2001/09/05 14:05:20  blinke
# move to SeqDB hierarchie
#
# Revision 1.5  2001/06/05 15:13:22  blinke
# change chop to chomp at main parse loop
#
# Revision 1.4  2001/04/19 13:17:27  blinke
# fixed requirements
#
# Revision 1.3  2001/04/19 13:04:45  blinke
# *** empty log message ***
#
# Revision 1.2  2001/04/19 13:01:26  blinke
# joined EMBL and SpTrEMBL parser
#
# Revision 1.1  2001/04/18 16:50:02  blinke
# Initial revision
#

use strict;

require SeqDB::SpTrEMBL::Entry;
require SeqDB::PlaybackReader;
use Carp qw(croak);

sub new {
    my $class = shift;
    
    my $self = {};
    bless $self, $class;
    return $self;
}

sub parse {
    my ($self, $reader) = @_;

    while ($reader->lines_left) {
	my $line = $reader->next_line;
	chomp $line;
	next if (!$line);
	$reader->playback_line($line);
	my $sptrembl_entry = SeqDB::SpTrEMBL::Entry->new;
	$sptrembl_entry->parse($reader);
	$self->{entries}->{$sptrembl_entry->{entryname}}=$sptrembl_entry;
    }
}


sub parse_callback ($$$) {
    my ($self, $reader, $callback) = @_;
    
    while ($reader->lines_left) {
	my $line = $reader->next_line;
	chomp $line;
	next if (!$line);
	$reader->playback_line($line);
	my $sptrembl_entry = SeqDB::SpTrEMBL::Entry->new;
	$sptrembl_entry->parse($reader);
	&$callback ($sptrembl_entry);
    }
}

1;
