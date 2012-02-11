package SeqDB;


# generic frontend to EMBLParser and SpTrEMBLParser

# it reads the first line and propagates the parsing
# to its submodules

# $Id: SeqDB.pm,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $

# $Log: SeqDB.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:36  givans
#
#
# Revision 1.3  2002/03/01 12:04:38  blinke
# fixed loop condition to break at EOF
#
# Revision 1.2  2001/09/06 11:40:37  blinke
# moved to SeqDB hierarchie and renamed to SeqDB.pm
#
# Revision 1.1  2001/09/06 11:39:18  blinke
# Initial revision
#
# Revision 1.4  2001/04/27 12:34:43  blinke
# added spaces at end of ID line regexp
#
# Revision 1.3  2001/04/19 14:18:54  blinke
# corrected header of parse_callback
#
# Revision 1.2  2001/04/19 13:18:11  blinke
# added missing bracket
#
# Revision 1.1  2001/04/19 12:53:41  blinke
# Initial revision
#


use strict;

use SeqDB::PlaybackReader;
use Carp qw(croak);

sub new {
    my $class = shift;
    
    my $self = {};
    bless $self, $class;
    return $self;
}

sub parse {
    my ($self, $reader) = @_;

    my $line;
    while ($reader->lines_left) {
	$line = $reader->next_line;
	chomp $line;
	next if (!$line);
	if ($line =~ /^ID.+AA\.$/) { # AA at end of line -> SwissProt/TrEMBL
	    $reader->playback_line($line);
	    require SeqDB::SpTrEMBL;
	    my $subparser = SeqDB::SpTrEMBL->new;
	    $subparser->parse($reader);
	    return $subparser;
	}
	elsif ($line =~ /^ID.+BP\.$/) { # BP at end of line => EMBL
	    $reader->playback_line($line);
	    require SeqDB::EMBL;
	    my $subparser = SeqDB::EMBL->new;
	    $subparser->parse($reader);;
	    return $subparser;
	}
	else {
	    warn "unknown database type, bailing out...";
	    last;
	}
    }
}

sub parse_callback ($$$) {
    my ($self, $reader, $callback) = @_;
    
    my $line;
    while (1) {
	$line = $reader->next_line;
	chomp $line;
	if ($line =~ /^ID.+AA\.\s*$/) { # AA at end of line -> SwissProt/TrEMBL
	    $reader->playback_line($line);
	    require SeqDB::SpTrEMBL;
	    my $subparser = SeqDB::SpTrEMBL->new;
	    $subparser->parse_callback($reader,$callback);
	    return $subparser;
	}
	elsif ($line =~ /^ID.+BP\.\s*$/) { # BP at end of line => EMBL
	    $reader->playback_line($line);
	    require SeqDB::EMBL;
	    my $subparser = SeqDB::EMBL->new;
	    $subparser->parse_callback($reader,$callback);
	    return $subparser;
	}
	else {
	    warn "unknown database type, bailing out...";
	    last;
	}
    }
}

1;
