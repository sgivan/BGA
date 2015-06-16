########################################################################
#
# This module defines extensions to the automagically created file
# contig.pm. Add your own code below.
#
########################################################################

use GENDB::Common;
use GENDB::orf;
require GENDB::contig_cgrb;
1;

############################################################
#
# Update contigs:
# compare orfs: change contig_id of orfs in old and new
# move old orfs to new contig
# delete all $old_contigs 
#
#############################################################

sub update_contigs {
    my($class, $old_contigs, $new_contig) = @_;
    my %old_orfs;
    my $new_orfs;
    my %changes;

    foreach(values %$old_contigs) {
	$changes{$_->id} = [];
	my %orfs = %{$_->fetchorfs};
	foreach $orf (values %orfs ) {
	    push(@{$old_orfs{$orf->length}}, $orf);
	}
    }
    
    my %orfs = %{$new_contig->fetchorfs};
    foreach $orf (values %orfs ) {
	push(@{$new_orfs{$orf->length}}, $orf);
    }

    my @orfs_to_move;
    foreach my $length (keys %old_orfs) {
	my @new_orfs = sort {$a->start <=> $b->start} @{$new_orfs{$length}};
	my @old_orfs = sort {$a->start <=> $b->start} @{$old_orfs{$length}};
	for(my $j = 0; $j < @old_orfs; $j++) {
	    next if($old_orfs[$j] == -1);
	    my $orf = $old_orfs[$j];
	    for(my $i = 0; $i < @new_orfs; $i++) {
		next if($new_orfs[$i] == -1);
		if($new_orfs[$i]->sequence eq $orf->sequence) {
		    push(@{$changes{$orf->contig_id}}, [$orf->stop, $new_orfs[$i]->stop]);
		    $orf->contig_id($new_orfs[$i]->contig_id);
		    $orf->stop($new_orfs[$i]->stop);
		    $orf->start($new_orfs[$i]->start);
		    $orf->frame($new_orfs[$i]->frame);
		    my $name = $new_orfs[$i]->name;
		    my $delanno = $new_orfs[$i]->latest_annotation;
                    $delanno->delete if($delanno != -1);
		    my %annos = %{$new_orfs[$i]->fetch_annotations}; 
		    foreach $anno (values %annos) {
			$anno->orf_id($orf->id);
		    }
		    for(my $k = 0; $k < $i; $k++) {
			$new_orfs[$k] = -1;
		    }
		    $new_orfs[$i]->delete;
		    $orf->name($name);
		    $new_orfs[$i] = -1;
		    $old_orfs[$j] = -1;
		    last;
		}
	    }
	}

	foreach(@old_orfs) {
	    if($_ != -1) {
		push @orfs_to_move, $_;
	    }
	}
    }

    foreach my $orf (@orfs_to_move) {
	my $name = $orf->name;
	$name =~ s/_deprecated//g;
	$name .= "_deprecated";
	$orf->name($name);
	my $found = 0;
        my @sortlist = reverse sort {($a->[0] <=> $b->[0])} @{$changes{$orf->contig_id}};
        foreach( @sortlist ) {
            if($_->[0] <= $orf->start) {
                $found = 1;
                my $diff = $orf->start - $_->[0];
                my $new_start = $_->[1] + $diff;
                $orf->stop($new_start + $orf->length);
                $orf->start($new_start);
                last;
            }
        } 
        if(!$found) {
            my $firstorf = pop @sortlist;
            my $diff = $orf->start - $firstorf->[0];
            my $new_start = $firstorf->[1] + $diff;
            $orf->stop($new_start + $orf->length);
            $orf->start($new_start);
        }
        $orf->status($ORF_STATE_IGNORED);
	$orf->contig_id($new_contig->id);
    }

    foreach(values %$old_contigs) {
	$_->delete_complete;
    }
}

########################################################################
# delete contig, all orfs of contig and all facts 
########################################################################
sub delete_complete {
    my($self) = @_;

    foreach $orf (values %{$self->fetchorfs}){
	$orf->delete_complete;
    }
    $self->delete;
}

######################################################################
# get all ORF objects in a given range from the database efficiently #
# input: start and stop position in contig  sequence                 #
# output: hash reference on ORF objects                              #
######################################################################
sub fetchorfs{
    my ($self,$start,$stop) = @_;

    local %orf = ();
    my $sth;
    
    $contig_id=$self->{'id'};
    
    if ((defined $start) && (defined $stop)) {
        $sth = $GENDB_DBH->prepare(qq {
            SELECT molweight, contig_id, startcodon, name, status, stop, ag, gc, frame, isoelp, id, start FROM orf
            WHERE contig_id='$contig_id' AND start>='$start' AND stop<='$stop'
            });
    } else {
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

sub fetchorfs_arrayref {
    my ($self,$start,$stop) = @_;

    my $hashref = $self->fetchorfs($start,$stop);

    my @array = values(%$hashref);

    return \@array;
}


#################################################
# count the number of orfs (not marked ignored) #
# input: just the contig object itself          #
# output: number of ORFs                        #
#################################################
sub num_orfs{
    my ($self) = @_;

    my $contig_id=$self->{'id'};
    my $number=0;
    
    # select all orf that are not marked ignored (2) for contig object
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, id FROM orf
	    WHERE contig_id = '$contig_id' AND status < 2
	    });
    $sth->execute;
    
    while ($sth->fetchrow_array) {
	$number++;
    }
    
    return $number;
};


##############################################
# count the number of annotated ORFs (genes) #
# input: just the contig object itself       #
# ouput: number of annotated ORFs            #
##############################################
sub num_genes{
    my ($self) = @_;

    my $contig_id=$self->{'id'};
    my $number=0;
    
    # select all orfs for contig that are annotated
    my $sth = $GENDB_DBH->prepare(qq {
	SELECT name, id FROM orf
	    WHERE  status = 1  AND contig_id = $contig_id
	    });
    
    $sth->execute;
    
    while ($sth->fetchrow_array) {
	$number++;
    }
    
    return $number;   
};


#################################################
# get a list of all ORFs with different states  #
# input: just the contig object itself          #
# output: array with: [0] = number of orfs      #
#                     [1] = orfs with state "0" #
#                     [2] = orfs with state "1" #
#                      etc.                     #
#                     [last] = number of rnas   #
#################################################
sub orf_stats {
    my ($self) = @_;

    my $orfs = $self->fetchorfs;

    my @states     = (0,0,0,0,0);
    my $orf_count  = 0;
    my $rna_count  = 0;

    foreach $orf (values (%$orfs)) {
        if($orf->name =~ /.*RNA.*/) {
            $rna_count++;
        } else {
            $orf_count++;
            $states[$orf->status]++;
        }
    }

    unshift @states, ($orf_count);
    push    @states, $rna_count;
 
    return @states;
};


##################################################
# fetch all ORFs within a given range            #
# input:                                         #
#   $start = start position of range,            #
#   $stop  = stop position of range              #
#                                                #
# setting $stop to $contig->length() will        #
# return all orfs with a start position > $start #
# etc.                                           #
# output: list (array) of ORF objects            #
##################################################
sub fetchOrfsinRange {    
    my ($self, $start, $stop) = @_;

    my $contig_id = 0;

    if( ref $self eq 'GENDB::contig' ) {
	$contig_id = $self->id;
    }

    if ($contig_id) {
	return GENDB::orf->fetchbySQL("start >= $start AND stop <= $stop AND contig_id=$contig_id ORDER BY start");
    }
    else {
	return GENDB::orf->fetchbySQL("start >= $start AND stop <= $stop");
    }
};


###################################################
# fetches all ORFs overlapping a defined position #
# input: position in DNA sequence                 #
# output: list (array) of ORF objects             #
###################################################
sub fetchOrfsatPosition {    
    my ($self, $position) = @_;

    my $contig_id = 0;

    if( ref $self eq 'GENDB::contig' ) {
	$contig_id = $self->id;
    }
    
    if ($contig_id) {
        return GENDB::orf->fetchbySQL("start <= $position AND stop >= $position AND contig_id=$contig_id");
    }
    else {
        return GENDB::orf->fetchbySQL("start <= $position AND stop >= $position");
    }
};


##########################################################
# translate contig dna sequence into different aa frames #
# input: frame and option to fill gaps in sequence       #
# output: amino acid sequence                            #
##########################################################
sub getTranslationFrame {    
    my ($self, $frame, $fill) = @_;

    if ($frame > 0) {	
	$aa_seq = join ("  ", split("", translate( substr ($self->sequence, abs($frame)-1))));
	if ($fill) {
	    $aa_seq = join ("  ", split("",$aa_seq));
	}
    }
    else {
	$aa_seq = substr($self->sequence, abs($frame) - 1);
	substr($aa_seq, -(CORE::length ($aa_seq) % 3)) = "" if (CORE::length ($aa_seq) % 3);
	$aa_seq = reverse(translate(reverse_complement($aa_seq)));
	if ($fill) {
	    $aa_seq = join ("  ", split("",$aa_seq));
	}
    }

    return $aa_seq;
};

# returns the names of all contigs as hash (key == names,
# values == 1).
# this methods can be used to check a number of new
# sequences before importing them and fail if the new
# contig's names are not unique
sub contig_names {
    my ($class) = @_;

    my $sth = $GENDB_DBH->prepare('SELECT name FROM contig');
    $sth->execute;
    
    my %names;
    while ($name = $sth->fetchrow_array) {
	$names{$name} = 1;
    }
    return \%names;
}
#require GENDB::contig_cgrb;
