package GENDB::GUI::ImportEMBL;

# this packages provides a dialog to import EMBL formatted
# data into GENDB

use File::Basename;
use Gtk;

use GENDB::contig;
use GENDB::orf;
use GENDB::Common;
use GENDB::Config;
use GENDB::Tools::UserConfig;
use GENDB::Tools::Importer::EMBL;

### 
# config area

my $config_dir_parameter_name='EMBL_dialog_dir';
my $contig_name_length=30;

# end of config area
###



# dialog to add an embl file content
sub add_embl {
    my ($call, $mainref)=@_;
   
    my $dialog = new Gtk::Dialog;
    $dialog->title("Import from EMBL file:");
    $dialog->set_modal(1);
    $dialog->set_position('mouse');

    my $import_box = new Gtk::VBox(0,0);
    $import_box->border_width(5);

    ### create entry for import data / file selection
    my $selection_box = new Gtk::HBox(0,0);
    my $file_label = new Gtk::Label("Import entries from file:");
    $selection_box->pack_start( $file_label, 1, 0, 0 );
    my $file_entry = new Gtk::Entry();
    $selection_box->pack_start( $file_entry, 1, 1, 5 );
    my $browse_button = new Gtk::Button("Browse...");
    $browse_button->signal_connect( 'clicked', \&import_filedialog, \$file_entry );
    my $help_box = new Gtk::VBox(1,0);
    $help_box->pack_start($browse_button, 0, 0, 0 );
    $selection_box->pack_start( $help_box, 0, 0, 0 );

    $import_box->pack_start( $selection_box, 1, 1, 0 );
 
    ### Put buttons into HButtonBox
    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("Import entries...");
    $ok_button->signal_connect( 'clicked', sub {
	my $import_file=$file_entry->get_text();
	if ($import_file ne "") {
	    # create an importer
	    my $importer = GENDB::Tools::Importer::EMBL->new($import_file);

	    # parse input file and report errors
	    main->update_statusbar("Parsing file, please wait...");
	    Gtk->main_iteration while ( Gtk->events_pending );
	    my $failure = $importer->parse;
	    if ($failure) {
	      Utils::show_error ("Error while parsing input file: $failure",
				 $dialog);
	    }
	    else {
		main->update_statusbar("Importing data to GENDB....");
		Gtk->main_iteration while ( Gtk->events_pending );
		$failure = $importer->import_data(\&_report);
		if ($failure) {
		  Utils::show_information("Error while importing data: $failure");
		}
		main->update_contigs;
		main->update_statusbar("");
		Gtk->main_iteration while ( Gtk->events_pending );
		$dialog->destroy;
	    }
	}
	else {
	  Utils::show_error("Import error: No import file specified!", $dialog);
	};
    });
    
    my $cancel_button = new Gtk::Button("Cancel");
    $cancel_button->signal_connect( 'clicked', sub { $dialog->destroy; } );

    $button_box->add($ok_button);
    $button_box->add($cancel_button);

    $dialog->vbox->add($import_box);
    $dialog->action_area->add($button_box);   
    
    $dialog->show_all;
};


#####################################
### create file dialog for import ###
#####################################
sub import_filedialog {
    my ($widget, $entry)=@_;
    
    my $file_dialog = new Gtk::FileSelection( "Select file with new contig data" );
    # get path from configuration file
    my $dirname = GENDB::Tools::UserConfig->get_parameter($config_dir_parameter_name);
    if (!$dirname) {
	# set directory to home directory
	$dirname = $ENV{'HOME'}."/";
    }
    $file_dialog->hide_fileop_buttons();
    $file_dialog->set_modal(1);
    $file_dialog->set_filename($dirname);
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
    
    # update entry fields containing file name
    my $entry=$$entry_ref;
    my $file=$fd->get_filename();
    $entry->set_text($file);

    # update user configuration to restore 
    # selected path next time this dialog
    # is used
  GENDB::Tools::UserConfig->set_parameter($config_dir_parameter_name,
					  dirname ($fd->get_filename())."/");

    $fd->destroy;
};

sub _report {
    my ($message_type, $message) = @_;
    if ($message_type eq 'not_unique') {
	my $choice = non_unique_name_dialog($message);
	return $choice;
    }
    elsif ($message_type eq 'inform') {
      Utils::show_information($message, main);
	return;
    }
    elsif ($message_type eq 'status') {
	main->update_statusbar($message, main);
	Gtk->main_iteration while ( Gtk->events_pending );
    }
}


sub non_unique_name_dialog {
    my ($contig_name) = @_;

    my $choice;
    my $dialog_finished = 0;
    my $dialog = new Gtk::Dialog;
    $dialog->title("Entry name is not unique");

    # create a description of the problem 
    my $label = new Gtk::Label("GENDB requires all contig names to be unique.\nThe EMBL file contains an entry named '$contig_name', which is already known to GENDB.");
    $dialog->vbox->pack_start($label, 1, 1, 10);
    
    # create a radiobutton group the let the user choose what to do
    my $rename_button = Gtk::RadioButton->new("Rename the entry for import");
    my $skip_button = Gtk::RadioButton->new("Skip this entry",$rename_button);
    my $abort_button = Gtk::RadioButton->new("Abort import",$rename_button);
    
    
    my $new_name_box=Gtk::HBox->new(0,0);
    my $new_name_label=Gtk::Label->new("New name :");
    my $new_name_entry=Gtk::Entry->new($contig_name_length);
    $new_name_box->pack_start($new_name_label,0,0,5);
    $new_name_box->pack_end($new_name_entry,1,1,5);
    
    # the logic to control the buttons
    $rename_button->signal_connect('toggled', sub {
	# enable/disable the new name entry field
	$new_name_entry->set_sensitive($rename_button->active);
    });

    # pack all button and the entry into the dialog's vbox
    $dialog->vbox->pack_start($rename_button, 0, 1, 5);
    $dialog->vbox->pack_start($new_name_box, 0, 1, 5);
    $dialog->vbox->pack_start($skip_button, 0, 1, 5);
    $dialog->vbox->pack_start($abort_button, 0, 1, 5);
    $skip_button->set_active(1);

    # the ok button
    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button('OK');
    $ok_button->signal_connect('clicked', sub { 
	# check which button is selected
	if ($rename_button->active) {
	    $choice = $new_name_entry->get_text;
	    if ($choice eq "") {
	      Utils::show_information("Please select a new name or choose skip or abort.",main);
		return;
	    }
	}
	elsif ($skip_button->active) {
	    $choice = 0;
	}
	else {
	    $choice = -1;
	}
	Gtk->grab_remove($dialog);
	$dialog->destroy;
	$dialog_finished=1;
    });
    $button_box->add($ok_button);

    # put widgets into dialog box
    $dialog->vbox->border_width(5);
    $dialog->action_area->add($button_box);

    # show dialog and wait for user to click ok
    $dialog->set_modal(1);
    $dialog->set_position('mouse');
    $dialog->show_all;

    while (Gtk->events_pending || !$dialog_finished) {
	Gtk->main_iteration;
    }
    return $choice;
};
