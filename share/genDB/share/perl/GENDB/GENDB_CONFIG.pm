package GENDB::GENDB_CONFIG;

###########################################
### System specific GENDB Configuration ###
###########################################

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw($GENDB_INSTALL_DIR $GENDB_PROJECT_FILE $GENDB_GV $GENDB_XVCG $GENDB_SRS $GENDB_GFF2PS $GENDB_GENOMEPLOT $GENDB_KEGG $GENDB_HELP $GENDB_HTH $GENDB_SAPS $GENDB_SIGNALP $GENDB_TMHMM $GENDB_BLAST_PATH $BLAST_DATABASE_DIR $BLAST_DATABASE_INDEX $GENDB_PFAM $PFAM_DB_DIR $HMMFETCH_TOOL $FORMATDB_TOOL $GENDB_INTERPRO_DIR $GENDB_INTERPRO_TRUE_RESULT $GENDB_INTERPRO_UNKNOWN_RESULT $GENDB_TRNASCANSE $GENDB_GODB_PATH $GENDB_HTTP_PROXY $GENDB_BLAST_LEVEL5_CUTOFF $DEFAULT_FONT $SMALL_FONT $SEQ_FONT);

($VERSION) = ('$Revision: 1.2 $ ' =~ /([\d\.]+)/g);

### 
#
# root directory of GENDB installation
#
#$GENDB_INSTALL_DIR="/local/cluster/genDB";
$GENDB_INSTALL_DIR = "/home/sgivan/projects/BGA/share/genDB";

###
#
# location of project list
#
$GENDB_PROJECT_FILE="$GENDB_INSTALL_DIR/lib/projects.lst";


#### fixed configs

### srs
#$GENDB_SRS = "zfg_srs";
$GENDB_SRS = "sanger";

### gff2ps
#$GENDB_GFF2PS = "$GENDB_INSTALL_DIR/share/exec/gff2ps";

### ghostviewer (this one removes file after quitting gv)
#$GENDB_GV = "/$GENDB_INSTALL_DIR/share/exec/gv_cleanup";
$GENDB_GV = "display";

### KEGG pathway htmls
$GENDB_KEGG = "$GENDB_INSTALL_DIR/share/perl/GENDB/Pathways/";

### help index page
$GENDB_HELP = "$GENDB_INSTALL_DIR/share/texte/manual/gendb_manual/index.html";


#### some smaller tools and helper scripts

### xvcg viewer for visualization of pathways
$GENDB_XVCG="/usr/local/bin/xvcg";

### Tk GenomePlot
$GENDB_GENOMEPLOT="/usr/local/bin/genome_plot.pl";


#### gene prediction


## executable pathname for tRNAScan-SE
#$GENDB_TRNASCANSE="/usr/local/bin/tRNAscan-SE";
#$GENDB_TRNASCANSE = "/share/ircfapps/bin/tRNAscan-SE";
#$GENDB_TRNASCANSE = "/share/ircf/ircfapps/bin/tRNAscan-SE";
$GENDB_TRNASCANSE = "tRNAscan-SE";


#### misc tools for sequence analyzes

### helix-turn-helix tool
#$GENDB_HTH="/usr/local/bin/hth";
$GENDB_HTH="/share/ircf/ircfapps/bin/hth";

### saps (statistical analysis of protein sequences)
#$GENDB_SAPS="/usr/local/bin/saps";
$GENDB_SAPS="/share/ircf/ircfapps/bin/saps";

### signalp (signal peptide)
#$GENDB_SIGNALP="/home/cgrb/givans/scratch/signalp";
$GENDB_SIGNALP="/share/ircf/ircfapps/bin/signalp";

### TMHMM (transmembrane helix)
#$GENDB_TMHMM="/local/cluster/bin/tmhmm";
#$GENDB_TMHMM="/share/ircf/ircfapps/bin/tmhmm";
$GENDB_TMHMM="/share/ircf/ircfapps/share/tmhmm/bin/tmhmm";


#### blast 2 setup
#$blast_install = '/evbio/NCBI/ncbitools/ncbi/build/';
$blast_install = '/share/apps/ircf/blast-2.2.26';
### blast 2 binary
#$GENDB_BLAST_PATH="/usr/local/share/ncbi/build/blastall";
$GENDB_BLAST_PATH="$blast_install/bin/blastall";
#$GENDB_BLAST_PATH="/usr/local/share/ncbi/bin/blastall";
#$GENDB_BLAST_PATH="/home/cgrb/genDB/blastall_rsh";

## indexing of blast database
#$FORMATDB_TOOL="/local/cluster/bin/formatdb";
$FORMATDB_TOOL="$blast_install/bin/formatdb";

## blastable databases, e.g. nt and nr 
#$BLAST_DATABASE_DIR="/dbase/NCBI/db";
$BLAST_DATABASE_DIR="/share/ircf/dbase/BLASTDB";

## index to blastable databases
$BLAST_DATABASE_INDEX=undef;

###
# blast level5 cutoff
#
# if this variable is true, the blast_helper (and related helpers)
# will not create facts which e-value is below the level 5 value.
# this will prevent the database from being flooded by insignificant
# facts
#
$GENDB_BLAST_LEVEL5_CUTOFF="yes";


#### pfam setup

### pfam
#$GENDB_PFAM="/usr/local/bin/hmmpfam";
#$GENDB_PFAM="/local/cluster/bin/hmmpfam";
#$GENDB_PFAM="/home/cgrb/givans/bin/hmmscan";
$GENDB_PFAM="/share/ircf/ircfapps/bin/hmmscan";

## PFam tools
#$HMMFETCH_TOOL="/local/cluster/bin/hmmfetch";
#$HMMFETCH_TOOL="/home/cgrb/givans/bin/hmmfetch";
$HMMFETCH_TOOL="/share/ircf/ircfapps/bin/hmmfetch";

## path to Pfam database
$PFAM_DB_DIR="/share/ircf/dbase/PFAM";


#### browser setup

### netscape browser
$GENDB_NETSCAPE="/usr/bin/mozilla";

### kde konqueror browser
$GENDB_KONQUEROR="/usr/bin/konqueror";

### Gtk::HTML.pm 
$GENDB_GTKHTML=undef;

### opera browser
$GENDB_OPERA=undef;

## http proxy to be used for SRS queries
# set this to undef to disable proxy usage
$GENDB_HTTP_PROXY=undef;


###### INTERPRO configuration

## path to InterProScan
#$GENDB_INTERPRO_DIR="/usr/local/share/iprscan";
$GENDB_INTERPRO_DIR="/local/cluster/iprscan";

## level for interpro true positive results
$GENDB_INTERPRO_TRUE_RESULT=1;

## level for interpro unknown results
$GENDB_INTERPRO_UNKNOWN_RESULT=3;


###
# Fonts
# 
# The fonts used in GENDB
# $SEQ_FONT must be a monospaced font!!!
#

$DEFAULT_FONT   = '-adobe-helvetica-medium-r-normal--12-120-*-*-p-67-*';
$SMALL_FONT     = '-adobe-courier-*-*-*-*-*-100-*-*-*-*-*-*';
$SEQ_FONT       = '-*-courier-medium-r-*-*-14-*-*-*-*-*-*-*';

1;
