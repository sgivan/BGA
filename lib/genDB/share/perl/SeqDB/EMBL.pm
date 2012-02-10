package SeqDB::EMBL;

# module to parse, store and create EMBL files

# $Id: EMBL.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: EMBL.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.6  2002/03/01 10:17:24  blinke
# chop -> chomp in parse_callback() (was updated in parse() before)
#
# Revision 1.5  2001/06/05 12:11:37  blinke
# chop in main parser loop deletes dot at end of id line, now using chomp
#
# Revision 1.4  2001/04/19 13:17:44  blinke
# fixed requirements
#
# Revision 1.3  2001/04/19 13:00:16  blinke
# joined EMBL and SpTrEMBL parser
#
# Revision 1.2  2001/04/17 14:22:07  blinke
# added parse_callback
#
# Revision 1.1  2001/04/05 14:52:06  blinke
# Initial revision
#

use strict;

require SeqDB::EMBL::Entry;
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
	my $new_embl_entry = SeqDB::EMBL::Entry->new;
	$new_embl_entry->parse($reader);
	$self->{entries}->{$new_embl_entry->{entryname}}=$new_embl_entry;
    }
}


sub parse_callback ($$$) {
    my ($self, $reader, $callback) = @_;
    
    while ($reader->lines_left) {
	my $line = $reader->next_line;
	chomp $line;
	next if (!$line);
	$reader->playback_line($line);
	my $new_embl_entry = SeqDB::EMBL::Entry->new;
	$new_embl_entry->parse($reader);
	&$callback ($new_embl_entry);
    }
}


sub write_to_file ($$) {
    my ($self, $filehandle) = @_;
    print $filehandle $self->write_to_string();
}

sub write_to_string ($) {
    my ($self) = @_;
    my $result;
    foreach (sort (keys %{$self->{entries}})) {
	$result .= $self->{entries}->{$_}->write_to_string;
    }
    return $result;
}
1;
