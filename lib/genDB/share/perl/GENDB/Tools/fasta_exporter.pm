package Tools::fasta_exporter;

($VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use strict;
use GENDB::Config;
use GENDB::DBMS;
use GENDB::contig;
use GENDB::orf;
use GENDB::annotation;
use GENDB::annotator;
use GENDB::Common;

####################################################
###                                              ###
### TODO:                                        ###
### - add more comments                          ###
###                                              ###
####################################################

#########################################################
### open dialog to export obj to file in FASTA format ###
#########################################################
sub fasta_export_dialog {
    my ($call, $obj, $mainref)=@_;
   
    my $obj_type;
    if ($obj->isa("GENDB::orf")) {
	$obj_type = "ORF";
    }
    elsif ($obj->isa("GENDB::contig")) {
	$obj_type = "Contig";
    }
    else {
	print "ERROR: Wrong object type! Object should be GENDB::orf or GENDB::contig.\n";
	return;
    }

    my $objname = $obj->name;
    my $defaultfile = $ENV{HOME}."/$objname.fas";

    my $dialog = new Gtk::Dialog;
    $dialog->title("Export $obj_type as FASTA:");
    $dialog->set_usize( 500, 150 );
    $dialog->set_modal(1);
    $dialog->set_position('mouse');
    $dialog->set_policy( 0, 0, 1); 

    my $export_box = new Gtk::VBox(0,0);
    $export_box->border_width(5);

    ### create entry for export data / file selection
    my $selection_box = new Gtk::HBox(0,0);
    my $file_label = new Gtk::Label("Export $obj_type $objname to file:");
    $selection_box->pack_start( $file_label, 1, 0, 0 );
    my $file_entry = new Gtk::Entry();
    $file_entry->set_text($defaultfile);
    $selection_box->pack_start( $file_entry, 1, 1, 5 );
    my $browse_button = new Gtk::Button("Browse...");
    $browse_button->signal_connect( 'clicked', \&filedialog, \$file_entry );
    my $help_box = new Gtk::VBox(1,0);
    $help_box->pack_start($browse_button, 0, 0, 0 );
    $selection_box->pack_start( $help_box, 0, 0, 0 );
    
    ### create frame for export options
    my $frame = new Gtk::Frame("Select output content:");
    #$frame->border_width(5);
    $frame->set_label_align(0.01, 0); 

    my $config_box = new Gtk::HBox(0,0);
    $config_box->border_width(5);
    
    my $export_dna_button = new Gtk::RadioButton("Export as DNA");
    $config_box->pack_start( $export_dna_button, 1, 1, 0 );
    
    my $export_aa_button = new Gtk::RadioButton("Export as AA:", $export_dna_button);
    $config_box->pack_start( $export_aa_button, 1, 1, 0 );
    $frame->add($config_box);
    
    if ($obj->isa("GENDB::contig")) {
	$export_aa_button->set_sensitive(0);
    }

    $export_box->pack_start( $selection_box, 1, 1, 0 );
    $export_box->pack_start( new Gtk::HSeparator(), 1, 1, 8 );
    $export_box->pack_start( $frame, 1, 1, 2 );

    ### Put buttons into HButtonBox
    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("Export $obj_type...");
    $ok_button->signal_connect( 'clicked', sub {
	my $export_file=$file_entry->get_text();
	if ($export_file ne "") {
	    if (-e $export_file) {
		&show_check_overwrite($export_dna_button->get_active(), $export_file, $obj, \$dialog);
	    }
	    else {
		&create_fasta_file($export_dna_button->get_active(), $export_file, $obj);	
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
       
    my $file_dialog = new Gtk::FileSelection( "Select file for FASTA export" );
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
    my ($act_button, $export_file, $obj, $parent_ref) = @_;

    my $objname = $obj->name;
    my $dialog = new Gtk::Dialog;
    $dialog->title("GenDB:: WARNING - Dialog!");
    $dialog->set_modal(1);
    $dialog->set_position('mouse');
    $dialog->set_policy( 0, 0, 1); 

    my $label = new Gtk::Label("Do you really want to overwrite $export_file while exporting $objname?");

    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("OK");
    $ok_button->signal_connect( 'clicked', sub { 
	$dialog->destroy;
	&create_fasta_file($act_button, $export_file, $obj, $parent_ref);
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

#############################################
### create FASTA file for selected contig ###
#############################################
sub create_fasta_file {

    my ($as_dna, $filename, $obj, $main_dialog_ref) = @_;

    my $objname = $obj->name;
    
    if ($as_dna) {
      GENDB::Common::create_fasta_file($filename, $objname, $obj->sequence);
    }
    else {
      GENDB::Common::create_fasta_file($filename, $objname, $obj->aasequence);  
    };
    
    if ($main_dialog_ref) {
	$$main_dialog_ref->destroy;
    };
    main->update_statusbar("Exported $objname to FASTA file.");
};


1;
