package Tools::genbank_exporter;

use strict;
use GENDB::Config;
use GENDB::DBMS;
use GENDB::contig;
use GENDB::orf;
use GENDB::annotation;
use GENDB::annotator;
use GENDB::feature_type;
use GENDB::Common;

####################################################
###                                              ###
### TODO:                                        ###
### - add more comments                          ###
###                                              ###
####################################################

#############################################################
### open dialog to export a contig to file in EMBL format ###
#############################################################
sub genbank_export_dialog {
    my ($call, $contigname, $mainref)=@_;
   
    my $defaultfile=$ENV{HOME}."/$contigname.gbk";

    my $dialog = new Gtk::Dialog;
    $dialog->title("Export contig in GENBANK format:");
    $dialog->set_usize( 500, 120 );
    $dialog->set_modal(1);
    $dialog->set_position('mouse');
    $dialog->set_policy( 0, 0, 1); 

    my $export_box = new Gtk::VBox(0,0);
    $export_box->border_width(5);

    ### create entry for export data / file selection
    my $selection_box = new Gtk::HBox(0,0);
    my $file_label = new Gtk::Label("Export contig $contigname to file:");
    $selection_box->pack_start( $file_label, 1, 0, 0 );
    my $file_entry = new Gtk::Entry();
    $file_entry->set_text($defaultfile);
    $selection_box->pack_start( $file_entry, 1, 1, 5 );
    my $browse_button = new Gtk::Button("Browse...");
    $browse_button->signal_connect( 'clicked', \&filedialog, \$file_entry );
    my $help_box = new Gtk::VBox(1,0);
    $help_box->pack_start($browse_button, 0, 0, 0 );
    $selection_box->pack_start( $help_box, 0, 0, 0 );

    my $progressbar = new Gtk::ProgressBar;
    
    $export_box->pack_start( $selection_box, 1, 1, 0 );
    $export_box->pack_start( new Gtk::HSeparator(), 1, 1, 8 );
    $export_box->pack_start( $progressbar, 1, 1, 3);

    ### Put buttons into HButtonBox
    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("Export contig...");
    $ok_button->signal_connect( 'clicked', sub {
	my $export_file=$file_entry->get_text();
	if ($export_file ne "") {
	    if (-e $export_file) {
		&show_check_overwrite(\$progressbar, $export_file, $contigname, \$dialog);
	    }
	    else {
		&create_embl_file(\$progressbar, $export_file, $contigname);	
		$dialog->destroy;
	    };
	}
	else {
	  Utils::show_error("Export error: No file specified!", $dialog);
	};
    });
    
    my $cancel_button = new Gtk::Button("Cancel");
    $cancel_button->signal_connect( 'clicked', sub { $dialog->destroy; } );

    $button_box->add($ok_button);
    $button_box->add($cancel_button);

    $dialog->vbox->add($export_box);
    $dialog->action_area->add($button_box);   
    
    $dialog->show_all;
};

#####################################
### create file dialog for export ###
#####################################
sub filedialog {
    my ($widget, $entry)=@_;
       
    my $file_dialog = new Gtk::FileSelection( "Select file for GENBANK export" );
    $file_dialog->set_modal(1);
    $file_dialog->set_filename($$entry->get_text());
    $file_dialog->signal_connect( "destroy", sub { $file_dialog->destroy; });

    # Connect the ok_button to file_ok_sel function
    $file_dialog->ok_button->signal_connect( "clicked", \&file_ok_sel, $file_dialog, $entry );
                  
    # Connect the cancel_button to destroy the widget
    $file_dialog->cancel_button->signal_connect( "clicked", sub { $file_dialog->destroy; });
    
    $file_dialog->show();
};

#############################
### get selected filename ###
#############################
sub file_ok_sel {
    my ($widget, $fd, $entry_ref)=@_;
    
    my $entry=$$entry_ref;
    my $file=$fd->get_filename();
    $entry->set_text($file);
    $fd->destroy;
};

##########################################################################
### ask once more whether user really wants to overwrite selected file ###
##########################################################################
sub show_check_overwrite {
    my ($prgbar_ref, $export_file, $contigname, $parent_ref) = @_;

    my $dialog = new Gtk::Dialog;
    $dialog->title("GenDB:: WARNING - Dialog!");
    $dialog->set_modal(1);
    $dialog->set_position('mouse');
    $dialog->set_policy( 0, 0, 1); 

    my $label = new Gtk::Label("Do you really want to overwrite $export_file while exporting $contigname?");

    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("OK");
    $ok_button->signal_connect( 'clicked', sub { 
	$dialog->destroy;
	&create_embl_file($prgbar_ref, $export_file, $contigname, $parent_ref);
    } );

    my $cancel_button = new Gtk::Button("Cancel");
    $cancel_button->signal_connect('clicked', sub { 
	$dialog->destroy;
    } );

    $button_box->add($ok_button);
    $button_box->add($cancel_button);

    $dialog->vbox->border_width(5);
    $dialog->vbox->pack_start($label, 1, 1, 10);
    $dialog->action_area->add($button_box);   
    
    $dialog->show_all;
};

############################################
### create genbank file for selected contig ###
############################################
sub create_embl_file {

    my ($prgbar_ref, $filename, $contigname, $main_dialog_ref) = @_;

    $$prgbar_ref->set_show_text( 1 );

    #create date stamp
    my $time=time();
    my @date = localtime($time);
    my $date = sprintf("%.2d.%.2d.%4d",
		       $date[3], $date[4]+1, $date[5]+1900);


    open (FILE, "> $filename");

    my $contig=GENDB::contig->init_name($contigname);
    my $contig_id=$contig->id;
    my $c_seq=$contig->sequence;
    my $c_len=length($c_seq);
    my $user = $ENV{'USER'};

    print FILE "LOCUS       $contigname DNA $c_len bp $date   
DEFINITION  $GENDB_PROJECT.
ACCESSION   $contigname
VERSION
KEYWORDS    .
SOURCE
  ORGANISM
REFERENCE   1 (bases 1 to $c_len)
AUTHORS     $user
TITLE
JOURNAL
FEATURES             Location/Qualifiers
     source          1..$c_len
                     /organism=\"   \"\n";
    
    #fetch orfs, annotations and write them to file

    my $contig_orfs_ref=GENDB::orf->fetchbySQL("contig_id=$contig_id ORDER BY start");
    my @contig_orfs=@$contig_orfs_ref;
    my $contig_num=@contig_orfs;
    
    $$prgbar_ref->set_adjustment( new Gtk::Adjustment( 0, 1, $contig_num, 0, 0, 0 ) );
    my $count=1;
    my $o;
    foreach $o (@contig_orfs) {
	# no export for tRNA..
	next if ($o->frame == 0);

	# get some general ORF properties for all objects
	my $oname=$o->name;
	my $start=$o->start;
	my $stop=$o->stop;

	# get latest annotation
	my $annot=GENDB::annotation->latest_annotation_init_orf_id($o->id);
	my $annot_name=$annot->name;
	my $annot_product=$annot->product;
	my $annot_descr=$annot->description;
	my $annot_comment=$annot->comment;
	my $annot_ec=$annot->ec;
	my $annot_embl_feat_id = $annot->feature_type;

	# check EMBL feature and write feature to file
	if ($annot_embl_feat_id) {
	    my $embl_feat = GENDB::feature_type->init_id($annot_embl_feat_id);
	    my $embl_feature = $embl_feat->name;
	    my $spaces = 17 - length($embl_feature);
	    if ($spaces < 0) {
		$spaces = 0;
		$embl_feature = substr($embl_feature, 0, 17);
	    }
	    my $space = "";
	    for (my $i=1;$i<$spaces;$i++) {
		$space.=" ";
	    }

	    # check frame
	    if ($o->frame > 0) { 
		print FILE "     $embl_feature$space$start..$stop\n";
	    }
	    else {
		print FILE "     ".$embl_feature.$space."complement($start..$stop)\n";
	    };
	}
	else {
	    # all ORFs without annotated EMBL feature are considered as CDS	
	    if ($o->frame > 0) { 
		print FILE "     CDS             $start..$stop\n";
	    }
	    else {
		print FILE "     CDS             complement($start..$stop)\n";
	    };
	};
   
	# write additional annotation information
	if ($annot_name) {
	    print FILE "                     /gene=\"$annot_name\"\n";
	}
	else {
	    print FILE "                     /gene=\"$oname\"\n";
	};
	if ($annot_product) {
	    my $clen=length($annot_product);	

	    if ($clen < 47) {
		print FILE "                     /product=\"$annot_product\"\n";
	    }
	    else {
		my $trennPos=rindex($annot_product," ",47)+1;
		my $cline=substr($annot_product,0,$trennPos);
		
		print FILE "                     /product=\"$cline";	  
		my ($cctr,$actpos)=();
		while (($trennPos+59) < $clen) {	
		    $cctr=$trennPos;
		    $trennPos=rindex($annot_product," ",$trennPos+59)+1;
		    $actpos=$trennPos-$cctr;
		    $cline=substr($annot_product,$cctr,$actpos);
		    print FILE "\n                     $cline";
		};
		$cline=substr($annot_product,$trennPos,59);
		print FILE "\n                     $cline\"\n";
	    };
	};
	if ($annot_ec) {
	    print FILE "                     /EC_number=\"$annot_ec\"\n";
	};
	if ($annot_descr) {
	    my $clen=length($annot_descr);	

	    if ($clen < 47) {
		print FILE "                     /function=\"$annot_descr\"\n";
	    }
	    else {
		my $trennPos=rindex($annot_descr," ",47)+1;
		my $cline=substr($annot_descr,0,$trennPos);
		
		print FILE "                     /function=\"$cline";	  
		my ($cctr,$actpos)=();
		while (($trennPos+59) < $clen) {	
		    $cctr=$trennPos;
		    $trennPos=rindex($annot_descr," ",$trennPos+59)+1;
		    $actpos=$trennPos-$cctr;
		    $cline=substr($annot_descr,$cctr,$actpos);
		    print FILE "\n                     $cline";
		};
		$cline=substr($annot_descr,$trennPos,59);
		print FILE "\n                     $cline\"\n";
	    };
	};
	if ($annot_comment) {
	    $annot_comment=~s/-/- /g;
	    $annot_comment =~s /\n/\;/g;
	    
	    my $clen=length($annot_comment);	
	    if ($clen < 51) {
		print FILE "                     /note=\"$annot_comment\"\n";
	    }
	    else {		
		my $trennPos=rindex($annot_comment," ",51)+1;				    
		my $cline=substr($annot_comment,0,$trennPos);
		
		print FILE "                     /note=\"$cline";	  
		my ($cctr,$actpos)=();
		while (($trennPos+59) < $clen) {	
		    $cctr=$trennPos;
		    $trennPos=rindex($annot_comment," ",$trennPos+59)+1;
		    $actpos=$trennPos-$cctr;
		    $cline=substr($annot_comment,$cctr,$actpos);
		    print FILE "\n                     $cline";
		};
		$cline=substr($annot_comment,$trennPos,59);
		print FILE "\n                     $cline\"\n";
	    };
	};
	

	# write translation into AA
	print FILE "                     /transl_table=11\n";
	
	my $aaseq=$o->aasequence;
	my $aalen=length($aaseq);
	my $aaline=substr($aaseq,0,45);

	print FILE "                     /translation=\"$aaline";
	my $aactr=45;
	while ($aactr < $aalen) {	    
	    $aaline=substr($aaseq,$aactr,59);
	    print FILE "\n                     $aaline";
	    $aactr+=59;
	};
	print FILE "\"\n";
	
	while( Gtk->events_pending ) {
	    Gtk->main_iteration;
	}
	$$prgbar_ref->set_value($count++);
    };    

    ###############################
    # print complete DNA sequence #
    ###############################
    # count As, Ts, Gs and Cs...
    $c_seq =~ tr/A-Z/a-z/;
    my $as = ($c_seq =~ tr/a/a/);
    my $ts = ($c_seq =~ tr/t/t/);
    my $gs = ($c_seq =~ tr/g/g/);
    my $cs = ($c_seq =~ tr/c/c/);
    my $oth=$c_len-$as-$ts-$gs-$cs;

    print FILE "BASE COUNT\t$as a\t$cs c\t$gs g\t$ts t\nORIGIN\n";
    
    my $ctr = 0;
    my $lctr = 0;
    my $bp_num = 0;
    my $line = "";
    my $div = $c_len/60;
    $div = int $div;
    print FILE "        1 ";
    my $spaces = 8;
    while ($bp_num < ($div*60)) {
	$lctr++;
	$line.=substr($c_seq, $ctr, 10)." ";
	$ctr+=10;
	if ($lctr == 6) {
	    $lctr=0;
	    chop($line);
	    my $bp=$line;
	    $bp=~s/\s//g;
	    $bp_num+=length($bp);
	    my $space = substr("         ", 0, $spaces - length($ctr)+1);
	    my $basectr = $ctr + 1;
	    print FILE "$line\n$space$basectr ";
	    $line="";
	};
	
    };
    
    if (($ctr+1) < $c_len) {
	while ($ctr < $c_len) {
	    $line.=substr($c_seq,$ctr,10)." ";
	    $ctr+=10;
	};
	chop($line);
	my $bp=$line;
	$bp=~s/\s//g;
	$bp_num+=length($bp);
	my $spaces=65-length($line);    
	my $i;
	for ($i=0;$i<$spaces;$i++) {
	    $line.=" ";
	};
	
	print FILE "$line\n//";
    };
    close (FILE);
    
    if ($main_dialog_ref) {
	$$main_dialog_ref->destroy;
    };
    main->update_statusbar("Exported contig $contigname to GENBANK.");
};

1;
