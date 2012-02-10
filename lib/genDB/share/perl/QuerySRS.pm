package QuerySRS;

# litte module to encapsulate access to SRS servers

# $Id: QuerySRS.pm,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $
# $Log: QuerySRS.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:36  givans
#
#
# Revision 1.2  2004/01/23 18:25:39  genDB
# Modified SRS query to use noSession instead of newId
#

# $Log: QuerySRS.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:36  givans
#
#
# Revision 1.2  2004/01/23 18:25:39  genDB
# Modified SRS query to use noSession instead of newId
#
# Revision 1.1  2004/01/23 16:56:48  genDB
# Initial revision
#
# Revision 1.24  2003/01/22 14:14:27  blinke
# added zfg_srs server target
# stopped module from queriing SRS server if no server was defined
#
# Revision 1.23  2002/05/03 12:03:51  blinke
# added caching of session id to decrease srs server load
#
# Revision 1.22  2002/04/22 15:38:33  blinke
# improved proxy usage (now using env variables)
#
# Revision 1.21  2002/03/15 11:01:55  blinke
# small change in database setup
#
# Revision 1.20  2002/02/07 12:24:48  blinke
# removed html parser and use simple regexps instead (THIS BREAKS SRS-6.1.1 !)
#
# Revision 1.19  2002/02/05 16:07:30  blinke
# removed srs 6.0 entry
# added srs-6.1.3 entry
#
# Revision 1.18  2002/02/04 13:08:56  blinke
# added "-newId" to enforce creation of new session id
#
# Revision 1.17  2001/09/17 13:26:51  blinke
# *** empty log message ***
#
# Revision 1.16  2001/09/13 09:06:38  blinke
# added internal-6.1 srs server
# updated ebi server
#
# Revision 1.15  2001/09/05 14:21:36  blinke
# added database mapping for trembl, tremblnew and swissprot
#
# Revision 1.14  2001/06/21 11:47:11  blinke
# *** empty log message ***
#
# Revision 1.13  2001/06/21 11:36:36  blinke
# *** empty log message ***
#
# Revision 1.12  2001/06/21 11:31:05  blinke
# added regexp to remove unwanted lines in fasta entries
#
# Revision 1.11  2001/06/20 15:11:34  blinke
# spaces are now converted to %20 in cgi queries
#
# Revision 1.10  2001/06/18 12:59:50  blinke
# little fix to strip off first two lines
#
# Revision 1.9  2001/06/11 11:58:34  blinke
# fixed spaces in cgi queries
#
# Revision 1.8  2001/06/06 13:14:39  blinke
# removed double entry for formats
#
# Revision 1.7  2001/06/06 13:10:52  blinke
# complete new rewrite of server queries
# no need for getz (command line tool) anymore
#
# Revision 1.6  2001/05/22 07:55:56  blinke
# corrected URL
#
# Revision 1.5  2001/04/18 15:32:07  blinke
# correct handling of spaces in database names
#
# Revision 1.4  2001/04/18 15:29:05  blinke
# added method to return SRS URL
#
# Revision 1.3  2001/04/18 15:04:37  blinke
# added support for querying several databases
#
# Revision 1.2  2001/04/18 14:51:44  blinke
# first version
#

use vars qw($cached_id $srs_server $formats $http_proxy);
use strict;
use LWP::UserAgent;
use HTTP::Request;
use Carp qw(carp croak);

# CONFIG SECTION

my $servers = { 
    # symbolic name for genetik SRS
    "zfg_srs" => { url => 'http://srs.genetik.uni-bielefeld.de/cgi-bin/',
		  dbs => { 'nt' => 'embl',
			   'nr' => 'swall pir',
			   'Pfam' => 'pfamhmm',
			   'trembl' => 'trembl',
			   'tremblnew' => 'tremblnew',
			   'sprot' => 'swissprot',
			   'enzyme' => 'ENZYME'
			   }
	       },

    # internal srs server
    "intern" => { url => 'http://srs.genetik.uni-bielefeld.de/cgi-bin/',
		  dbs => { 'nt' => 'embl',
			   'nr' => 'swall pir',
			   'Pfam' => 'pfamhmm',
			   'trembl' => 'trembl',
			   'tremblnew' => 'tremblnew',
			   'sprot' => 'swissprot',
			   'enzyme' => 'ENZYME'
			   }
	      },
    
    # external srs server located at EBI
    "ebi_old" => { url => 'http://srs.ebi.ac.uk/srs6bin/cgi-bin/',
	       dbs => { 'nt' => 'embl emblnew',
			'nr' => 'swissprot sptrembl tremblnew',
			'Pfam' => 'pfamhmm',
			'trembl' => 'sptrembl remtrembl',
			'tremblnew' => 'tremblnew',
			'sprot' => 'swissprot' } 
	   },
#	SAG configured IUBIO SRS server
    "iubio" => { url => 'http://iubio.bio.indiana.edu/srsbin/cgi-bin/',
	       dbs => { 'nt' => 'embl emblnew',
			'nr' => 'refseqp genpept',
			'Pfam' => 'pfamhmm',
			'trembl' => 'sptrembl remtrembl',
			'tremblnew' => 'tremblnew',
			'SWISSPROT' 	=> 	'swissprot',
			'INTERPRO'	=>	'interpro',
			'PIR'		=>	'pir',
			'REFSEQP'	=>	'refseqp',
			'PFAMA'		=>	'pfama',
		 } 
	   },
#	SAG configured columbia
    "columbia" => { url => 'http://walnut.bioc.columbia.edu/srs71bin/cgi-bin/',
               dbs => { 'nt' => 'embl emblnew',
                        'nr' => 'refseqp genpept',
                        'Pfam' => 'pfamhmm',
                        'trembl' => 'sptrembl remtrembl',
                        'tremblnew' => 'tremblnew',
                        'SWISSPROT'     =>      'swissprot',
                        'INTERPRO'      =>      'interpro',
                        'PIR'           =>      'pir',
                        'REFSEQP'       =>      'refseqp',
                        'PFAMA'         =>      'pfama',
                 }
	},
    "ebi" => { url => 'http://srs.ebi.ac.uk/srsbin/cgi-bin/',
               dbs => { 'nr' => 'refseqp genpept',
                        'SWISSPROT'     =>      'swissprot',
                        'INTERPRO'      =>      'interpro',
                        'PIR'           =>      'pir',
                        'REFSEQP'       =>      'refseqp',
                        'PFAMA'         =>      'pfama',
                 }
	},
    "sanger" => { url => 'http://srs.sanger.ac.uk/srsbin/cgi-bin/',
               dbs => { 'nr' => 'refseqprotein',
                        'SWISSPROT'     =>      'swissprot',
                        'INTERPRO'      =>      'interpro',
                        'PIR'           =>      'pir',
                        'REFSEQP'       =>      'refseqprotein',
                        'PFAMA'         =>      'pfama',
                 }
	},


};

# default: use internal SRS 6.1.3 server
#my $srs_server = $servers->{intern};
my $srs_server = $servers->{iubio};

# mapping of output formats to format numbers used at server queries
my $formats={names => 1,
	     complete => 2,
	     seqsimple => 3,
	     fasta => 7,
	     swissview => 8,
	     protchart => 9 };

# cached id used for this session
my $cached_id="";

# should we use a http proxy ?
# my $http_proxy='proxy.my-domain.org:3128';
my $http_proxy;

1;


sub set_server ($$) {
#	my ($package, $filename, $line) = caller();
#	print "setting server: p: '$package', f: '$filename', l: '$line'\n";
    my ($class, $server) = @_;
    if ($server) {
	if (!defined $servers->{$server}) {
	    warn "unknown server $server, not changing setting";
	    return;
	}
	$srs_server = $servers->{$server};
    }
    else {
	$srs_server = 0;
    }
    $cached_id="";
}

sub set_proxy ($$) {
    my ($class, $proxy) = @_;
    $http_proxy=$proxy;
}

sub _compose_query_URL {
    my ($dbname, $dbid, $format) = @_;
    return if ($srs_server == 0);
    my $query = $srs_server->{url}."wgetz?";
    if ($cached_id eq "") {
	# no cached id, so create a new one
#	$query .= "-newId+";
      $query .= "-noSession+";
    }
    else {
	# use the cached id to prevent the srs server from
	# creating a new session for each query
	$query .= "-id+$cached_id+";
    }
    if ($format) {
	$query .= "-vn+".$formats->{$format}."+-sn+1+";
    }
    if (defined ($srs_server->{dbs}->{$dbname})) {
	$query .="-e+[{".$srs_server->{dbs}->{$dbname}."}-ID:$dbid]";
    }
    else {
	$query .="-e+[{$dbname}-ID:$dbid]";
    }
    $query =~ s/ /%20/g;
    return $query;
}

sub _get_SRS_record_from_server {
    my ($dbname, $dbid, $format) = @_;

    return if ($srs_server == 0);
    my $ua = new LWP::UserAgent;
    if ($http_proxy) {
	$ua->proxy('http',$http_proxy);
    }
    while (1) {
	my $query =_compose_query_URL($dbname, $dbid, $format);
	my $res = HTTP::Request->new (GET=> $query);
	my $resp=$ua->request($res);
	# Check the outcome of the response
	if ($resp->is_success) {
	    if ($cached_id eq "") {
		my $result = $resp->content;
		# try to extract the session id from a form field
		# this should be the easiest way to get
		# (all other occurences of that id are inside A HREF tags)
		($cached_id) = ($result =~ /<INPUT TYPE=hidden NAME=userId VALUE=(\S+)>/);
		if (!defined ($cached_id)) {
		    # better luck next time...
		    $cached_id = "";
		}
		return $result;
	    }
	    return $resp->content;
	} else {
	    if ($cached_id) {
		# may our session id has become invalid
		# clear it and try it again
		$cached_id="";
	    }
	    else {
		# no chance, even with a new session id
		carp ("failed SRS query : $query");
		return "";
	    }
	}
    }
}

sub get_plain_entry ($$) {
    return if ($srs_server == 0);
    return _text_between_pre(_get_SRS_record_from_server($_[0], $_[1], 'complete'));
}

sub get_html_entry ($$) {
    return if ($srs_server == 0);
    return _get_SRS_record_from_server($_[0], $_[1], 'complete');
}

sub get_fasta_entry ($$) {
    return if ($srs_server == 0);
    return _text_between_pre(_get_SRS_record_from_server($_[0], $_[1], 'fasta'));
}

sub _text_between_pre {
    my ($text) = @_;

    # cut off everything except the text between <PRE>-tags
    $text =~ s/^.*<pre>(.*)<\/pre>.*$/$1/smi;
    
    # the text itself may contain links...remove them..
    $text =~ s/<[^<]*?>//msgi;

    # remove leading newlines...
    $text =~ s/^(\n+)//;
    return $text;
}

sub get_entry_URL ($$) {
    my ($dbnames, $dbid) = @_;
    return if ($srs_server == 0);
    my $link = _compose_query_URL($dbnames, $dbid);
    $link =~ s/ /%20/g;
    return $link;
}
