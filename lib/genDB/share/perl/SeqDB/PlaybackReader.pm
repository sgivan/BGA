package SeqDB::PlaybackReader;

# this package is part of the EMBL and SpTrEMBLparser 
# it contains a little handler for writing
# look-a-head parser

# $Id: PlaybackReader.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $

# $Log: PlaybackReader.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.5  2002/03/01 10:48:51  blinke
# added check to destroy method (prevent error message about undefined value if PlaybackReader don't use a file handle)
#
# Revision 1.4  2001/09/05 14:06:32  blinke
# moved to SeqDB hierarchie
#
# Revision 1.3  2001/04/19 14:29:44  blinke
# removed an error in next_line (reading from non existant file handle)
#
# Revision 1.2  2001/04/19 12:58:06  blinke
# joined EMBL and SpTrEMBL parser
#
# Revision 1.1  2001/04/05 14:53:08  blinke
# Initial revision
#

use strict;

1;

sub new ($) {
    my $class = shift;

    my $self = { playback => [],
		 file => undef };
    bless $self, $class;
    return $self;
}
		 
sub load_string ($$) {
    my ($self, $string) = @_;

    @{$self->{playback}} = split "\n", $string;
}

sub load_file ($$) {
    my ($self, $file) = @_;

    # flush playback buffer
    $self->{playback} = [];

    # store file (handle/object)
    $self->{file} = $file;
}

sub playback_line {
    unshift @{$_[0]->{playback}}, $_[1];
}

sub next_line {
    my $self = shift;
    
    # use playback buffer if lines left..
    if (scalar @{$self->{playback}}) {
	return shift @{$self->{playback}};
    }
    # else read line from file...
    if (defined ($self->{file})) {
	return my $line = $self->{file}->getline;
    }
    return;
}

sub lines_left {
    my $self = shift;
    if (scalar @{$self->{playback}}) {
	return 1;
    }
    return 0 if (!$self->{file});
    my $line;
    if ($line = $self->{file}->getline) {
	$self->playback_line ($line);
	return 1;
    }
    return 0;
}

sub DESTROY {
    close $_[0]->{file} if ($_[0]->{file});
}

