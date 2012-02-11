package Tools::gff_export;

$VERSION = 1.0;

use GENDB::GENDB_CONFIG;

####################################################
###                                              ###
### TODO:                                        ###
### - add more comments                          ###
### - enable export for list of                  ###
###   selected sequence objects                  ###
####################################################

############################################################
### export genome data to gff file or display it with gv ###
############################################################
sub export_gff {
    my ($call, $contigname, $self)=@_;

    my $bp_num=0;
    my $page_num=1;
    
    my $dialog = new Gtk::Dialog;
    $dialog->title("Export genome data as GFF:");
    $dialog->set_modal(1);
    $dialog->set_policy( 0, 0, 1);
    $dialog->set_position('mouse');

    my $frame = new Gtk::Frame("Configure parameters for gff output:");
    $frame->border_width(8);
    $frame->set_label_align(0.01, 0); 

    my $config_box = new Gtk::VBox(0,0);
    $config_box->border_width(5);
    
    my $scale_box1 = new Gtk::HBox(1,0);
    my $label1 = new Gtk::Label("Kbp per page:");
    $label1->set_justify('left');
    $scale_box1->pack_start( $label1, 1, 0, 0 );
    my $adj1 = new Gtk::Adjustment(0, 0, 1000, 10, 10, 0.0);
    my $scale1 = new Gtk::HScale($adj1);
    $scale1->set_digits(0);
    $scale_box1->pack_end( $scale1, 1, 1, 0 );
    
    $config_box->pack_start( $scale_box1, 1, 1, 0 );
    
    my $scale_box2 = new Gtk::HBox(1,0);
    my $label2 = new Gtk::Label("number of pages:");
    $label2->set_justify('left');
    $scale_box2->pack_start( $label2, 1, 0, 0 );
    my $adj2 = new Gtk::Adjustment(1, 0, 150, 1.0, 1.0, 0.0);
    my $scale2 = new Gtk::HScale($adj2);
    $scale2->set_digits(0);
    $scale_box2->pack_start( $scale2, 1, 1, 0 );
    
    $config_box->pack_start( $scale_box2, 1, 1, 0 );

    $frame->add($config_box);
    
    $adj1->signal_connect( 'value_changed', \&scale1, \$adj2,  );
    $adj2->signal_connect( 'value_changed', \&scale2, \$adj1 );

    my $progressbar = new Gtk::ProgressBar;
    $dialog->vbox->add($frame);
    $dialog->vbox->pack_start($progressbar, 1, 1, 3);
    
    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("Display output with gv");
    $ok_button->signal_connect( 'clicked', sub { 
	if ($contigname) {	      	    
	    $filename=POSIX::tmpnam();
	    &create_gff_file($filename, $contigname, \$progressbar);
	    my $bp_num=$adj1->get_value;
	    my $page_num=$adj2->get_value;
	    if ($bp_num == 0 && $page_num == 0) {
		$page_num=1;
	    };
	    $bp_num*=1000;
	    # execute system calls
	    system("$GENDB_GFF2PS -v -C gendb.rc -N $bp_num -P $page_num $filename > $filename.ps");
	    # use gv cleanup script here !!!
	    system("$GENDB_GV $filename.ps $filename.ps&");
	    unlink $filename;
	};										
    } );
    
    my $export_button = new Gtk::Button("Export to file...");
    $export_button->signal_connect('clicked', \&gff_filedialog, $contigname, \$progressbar);
    
    my $cancel_button = new Gtk::Button("Close");
    $cancel_button->signal_connect( 'clicked', sub { $dialog->destroy; } );

    $button_box->add($ok_button);
    $button_box->add($export_button);
    $button_box->add($cancel_button);

    $dialog->action_area->add($button_box);   
    
    $dialog->show_all;
};


##################################
### create file dialog for gff ###
##################################
sub gff_filedialog {
    my ($widget, $contigname, $prg_ref)=@_;
    
    my $contigfile=$contigname;
    $contigfile=~s/ /_/g;
    my $defaultfile=$ENV{HOME}."/$contigfile.gff";
    my $file_dialog = new Gtk::FileSelection( "File Selection" );
    $file_dialog->hide_fileop_buttons();
    $file_dialog->set_filename($defaultfile);
    $file_dialog->set_modal(1);
    $file_dialog->signal_connect( "destroy", sub { $file_dialog->destroy; });

    # Connect the ok_button to file_ok_sel function
    $file_dialog->ok_button->signal_connect( "clicked", \&file_ok_sel, $file_dialog, $contigname, $prg_ref );
                  
    # Connect the cancel_button to destroy the widget
    $file_dialog->cancel_button->signal_connect( "clicked", sub { $file_dialog->destroy; });
                     
    $file_dialog->show();
};


#############################
### get selected filename ###
#############################
sub file_ok_sel {
    my ($widget, $fd, $contigname, $prg_ref)=@_;

    my $file=$fd->get_filename();
    if (-e $file) {
	&show_check_overwrite($file, $contigname, $prg_ref, \$fd);
    }
    else {
	my @seq_objects = ();
	# fetch data for export
	if ($contigname) {
	    @seq_objects = values (%{GENDB::contig->init_name($contigname)->fetchorfs()});
	};
	&create_gff_file($file, $contigname, $prg_ref);	
	$fd->destroy;
    };
};


##########################################################################
### ask once more whether user really wants to overwrite selected file ###
##########################################################################
sub show_check_overwrite {
    my ($export_file, $contigname, $prg_ref, $parent_ref) = @_;

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
	$$parent_ref->destroy;
	my @seq_objects = ();
	# fetch data for export
	if ($contigname) {
	    @seq_objects = values (%{GENDB::contig->init_name($contigname)->fetchorfs()});
	};   
	&create_gff_file($export_file, $contigname, $prg_ref);
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


#################################
### create temporary gff file ###
#################################
sub create_gff_file {
    my ($filename, $contigname, $prgbar_ref)=@_;

    my @seq_objects = ();
    # fetch data for export
    if ($contigname) {
	@seq_objects = values (%{GENDB::contig->init_name($contigname)->fetchorfs()});
    };
    
    my $obj_num=@seq_objects;

    open (GFF_FILE, "> $filename");
    
    $$prgbar_ref->set_show_text( 1 );
    $$prgbar_ref->set_adjustment( new Gtk::Adjustment( 0, 1, $obj_num, 0, 0, 0 ) );
    my $count=1;
    my $orf;
    foreach $orf (@seq_objects) {
	my $name="";
	my $start=$orf->start;
	my $stop=$orf->stop;
	my $frame=$orf->frame;
	
	my $status="GENDB";
	my $sign="";
	if ($frame=~/-/) {
	    $sign="-";
	}
	else {
	    $sign="+";   
	};
	my $fnum=chop($frame);
	$fnum--;
	
	#get the latest annotation for orf, if any and 
	#use gene name as descriptor, else orf_name
	my $orf_id=$orf->id;
	my $annot=GENDB::annotation->latest_annotation_init_orf_id($orf_id);
	if ($annot eq -1) {
	    $name=$orf->name;
	}
	elsif ($annot->name eq "") {
	    $name=$orf->name;	    
	}
	else {
	    $name=$annot->name;  
	};	

	my $cname=substr($contigname, 0, 8);
	$cname=~s/ /_/g;
	print GFF_FILE "$cname\t$status\torf\t$start\t$stop\t1\t$sign\t$fnum\t$name\n";
	
	while (Gtk->events_pending) {
	    Gtk->main_iteration;
	}
	$$prgbar_ref->set_value($count++);
    };
    
    close (GFF_FILE);
    main->update_statusbar("Exported contig $contigname to GFF.");
};


##########################
### Scaling function 1 ###
##########################
sub scale1 {
    my( $adj, $adj2_ref ) = @_;
       
    my $cv = $adj->get_value;
    my $cur_val = int $cv;
    my $last_num=chop($cur_val);
    
    if (0 <= $last_num && $last_num < 5) {
	$adj->set_value($cur_val * 10);
    }
    elsif (4 < $last_num && $last_num < 10) {
	$adj->set_value(++$cur_val * 10);
    };
    my $adj2=$$adj2_ref;
    $adj2->set_value(1);
};


##########################
### Scaling function 1 ###
##########################
sub scale2 {
    my( $adj, $adj1_ref ) = @_;
       
    my $cur_val = $adj->get_value;
    my $adj1=$$adj1_ref;
    $adj1->set_value(0);
};



1;
