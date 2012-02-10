package GENDB::Tools::Importer::Fasta;
use strict;
use IO::File;

# $Id: Fasta.pm,v 1.1.1.1 2005/02/22 18:05:37 givans Exp $
# $Log: Fasta.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:37  givans
#
#
# Revision 1.3  2001/12/18 10:11:42  alice
# Returns requests for new names, when
# name is too long
# name is an empty string
# name is not unique
#
# Revision 1.2  2001/12/06 13:15:55  alice
# *** empty log message ***
#
# Revision 1.1  2001/12/06 13:14:50  alice
# Initial revision
#
# Fasta contig importer for GENDB
# from a multiple sequence file


# first evaluate if contig is already in the database and 
# also if the name isn't to long !
# and if there is a name and a file given !!

# create an instance of this importer

sub new {
    my ($class, $filename) = @_;
    my $self;
    my $error_state;

    # is it a readable file ?
    my $file = IO::File->new($filename);
    if (!ref $file) {
			$error_state = "Cannot open $filename for reading";
			$self ->{error_state} = $error_state;
			bless $self, ref $class || $class;	    
			return $self;
    }

    # is it a multiple sequence file ?
    my $contigs = GENDB::Common::read_fasta_file($filename);
    
    unless ($contigs) {
			$error_state =  "No contigs found in $filename\n";
    }

    $self = {
    					error_state => $error_state,
							contigs => $contigs,
	     				imported_contigs => {},
	     			};
    bless $self, ref $class || $class;
    return $self;
}

sub contigs {
    my ($self, $contigs) = @_;
    if ($contigs) {
			$self->{contigs} = $contigs;
    }
    return $_[0]->{contigs};
}

sub contig_name_length {
    my ($self, $contig_name_length) = @_;
    if ($contig_name_length) {
			$self->{contig_name_length} = $contig_name_length;
    }
    return $self->{contig_name_length};
}

sub imported_contigs {
    return $_[0] ->{imported_contigs};
}

# Callback options identical to the callback used in EMBL.pm
# the callback is called with two parameters, error msg
# and error content
# 
# error codes (so far):
# 
# 'not_unique' - content is the name of the EMBL entry
#                callback returns :
#                 0       -  skip this entry 
#                 
#      ""(empty string)   - skip this entry
#                -1       - abort import
#                'string' - rename entry and try again
# 'inform'     - content is a message to be displayed


sub import_contigs {
    my ($self, $callback) = @_;
		#printf("\n\nimport_contigs() called from %s\n",scalar(caller()));
    # is it a readable file ?
    if($self ->{error_state}) {
 			return $self->{error_state};
    }
    my $contigs = $self ->contigs();
    
    my $db_contig_names = GENDB::contig->contig_names();
    
    my ($seq_name,$seq);
    #print "entering CONTIG.  \$contigs is a '", ref($contigs), "'\n";
    #print "\$contigs has '", scalar(keys(%$contigs)), "' keys\n";
    my $cnt = 0;
    CONTIG: while (my ($seq_name, $seq) = each (%$contigs)) {
			#printf("cnt = %d\n", ++$cnt);
			#print "seq name = '$seq_name', length = ", length($seq), "\n";
			# looking for already existent names
			if (defined($db_contig_names->{$seq_name})) {
					#print "'$seq_name' is defined\n";
					$seq_name= &$callback('not_unique',"I.  Name '$seq_name' is not unique, please choose another one");
					$seq_name = undef;
					
					if ($seq_name eq -1) {
						return "Aborted by user";
				
					}
					if ($seq_name eq 0 || $seq_name eq "") {
						&$callback('inform',"Skipping contig");
						next CONTIG;
					}
			}
			# is the name too long ?
			#if (length($seq_name) > ($self->contig_name_length() - 5)) {
			if (length($seq_name) > ($self->contig_name_length(length($seq_name)))) {
					$seq_name = undef;
					$seq_name= &$callback('not_unique',"II.  Name '$seq_name' is too long, please choose a name shorter than "
								.($self ->contig_name_length() - 5)." letters");
					if ($seq_name eq -1) {
						return "Aborted by user";
					}
					if ($seq_name eq 0 || $seq_name eq "") {
						&$callback('inform',"Skipping contig");
						next CONTIG;
					}
					if (exists $db_contig_names->{$seq_name}) {
						redo CONTIG;	
					}
			}
		
			# introduce new sequences into database...
			#print "creating contig with name '$seq_name'\n";
			my $contig = GENDB::contig -> create($seq_name, $seq);
			if ($contig == -1) {
					&$callback('inform',"Contig import: Skipping contig $seq_name");
			}
			my $contig_id = $contig->id();
			my $real_contig = GENDB::contig->init_id($contig_id);
			if ($seq_name ne $real_contig->name()) {
					$real_contig->delete();
					&$callback('inform',"Contig import: Skipping contig $seq_name");
			}
			$contig->length(length $seq);
			$self ->{imported_contigs} ->{$seq_name} = $seq;
    }
    #print "returning from import_contig()\n\n";
}

1;
