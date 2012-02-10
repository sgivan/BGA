########################################################################
#
# This module defines extensions to the automagically created file
# contig.pm. Add your own code below.
#
########################################################################

use GENDB::Common;
use GENDB::orf;
1;

############################################################
#
# Update contigs:
# compare orfs: change contig_id of orfs in old and new
# move old orfs to new contig
# delete all $old_contigs 
#
#############################################################


######################################################################
# get all ORF objects in a given range from the database efficiently #
# input: start and stop position in contig  sequence                 #
# output: hash reference on ORF objects                              #
######################################################################
sub fetchorfs_exact {
    my ($self,$start,$stop) = @_;
#	print join ' ',caller(), "\n";
    local %orf = ();
    my $sth;
    
    $contig_id=$self->{'id'};
    
    if ((defined $start) && (defined $stop)) {
	$sth = $GENDB_DBH->prepare(qq {
	    SELECT molweight, contig_id, startcodon, name, status, stop, ag, gc, frame, isoelp, id, start FROM orf
		WHERE contig_id='$contig_id' AND start = '$start' AND stop = '$stop'
		});
    }
    else {
	$sth = $GENDB_DBH->prepare(qq {
	    SELECT molweight, contig_id, startcodon, name, status, stop, ag, gc, frame, isoelp, id, start FROM orf
		WHERE contig_id='$contig_id'		
		});
    }
    $sth->execute;
    while (($molweight, $contig_id, $startcodon, $name, $status, $stop, $ag, $gc, $frame, $isoelp, $id, $start) = $sth->fetchrow_array) {
	my $orf = {
		'molweight' => $molweight, 
		'contig_id' => $contig_id, 
		'startcodon' => $startcodon, 
		'name' => $name, 
		'status' => $status, 
		'stop' => $stop, 
		'ag' => $ag, 
		'gc' => $gc, 
		'frame' => $frame, 
		'isoelp' => $isoelp, 
		'id' => $id, 
		'start' => $start
		};
	bless($orf, 'GENDB::orf');
	$orf{$name} = $orf;
    }
    $sth->finish;

    return(\%orf);
};


