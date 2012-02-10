package GENDB::Tools::FastaStorage;

# package to cache access to fasta databases

use GENDB::Common;

($VERSION) = ('$Revision: 1.1.1.1 $' =~ /([\d\.]+)/g);

$cache = {};

sub put_into_storage {
    my ($class, $key, $filename) = @_;

    my $sequences = GENDB::Common::read_fasta_file($filename);
    if (scalar keys %$sequences) {
	$cache->{$key}=$sequences;
    }
}

sub get_fasta {
    my ($class, $key, $entry) = @_;
    
    if (exists ($cache->{$key}->{$entry})) {
	return $cache->{$key}->{$entry};
    }
    warn "retrieving non existent fasta storage element: key = $key, entry = $entry";
    return -1;
}

sub has_key {
    my ($class, $key) = @_;
    return exists ($cache->{$key});
}
