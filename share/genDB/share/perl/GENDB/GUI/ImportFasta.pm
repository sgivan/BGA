package GENDB::GUI::ImportFasta;

use GENDB::contig;
use GENDB::Tools::Importer::Fasta;
use GENDB::GUI::PredictionDialog;
use GENDB::GUI::Utils;
use GENDB::Common;
use Gtk;
use vars qw(@ISA);

@ISA = qw(Gtk::Dialog);

sub new {
    my ($class, $type) = @_;
    my $self = $class->SUPER::new;
    bless $self, $class;

    $self->set_title("Import Fasta File");
    $self->set_position('center');
    
    $self->vbox->set_border_width(5);
    $self->vbox->set_spacing(5);

    my $label = new Gtk::Label("Choose Fasta File:");
    my $hbox = new Gtk::HBox(0, 3);
    my $entry = new Gtk::Entry;
    my $button = new Gtk::Button('Browse');

    $hbox->set_border_width(5);
    $hbox->set_spacing(5);
    $hbox->pack_start_defaults($entry);
    $hbox->pack_start($button, 0, 0, 5);

    $self->vbox->pack_start_defaults($label);
    $self->vbox->pack_start_defaults($hbox);

    my $bb = new Gtk::HButtonBox;
    my $cancel = new Gtk::Button("Cancel");
    if($type eq "Import") {
	my $ok = new Gtk::Button("Import Contigs");
	my $predict = new Gtk::Button("run Gene prediction");
	$ok->signal_connect('clicked', \&import_contigs, $self, $entry, 1);
	$predict->signal_connect('clicked', \&import_and_predict, $self, $entry, 0);
	$bb->pack_start_defaults($ok);
	$bb->pack_start_defaults($predict);
    } else {
	my $ok = new Gtk::Button("Update Contigs");
	$ok->signal_connect('clicked', \&update_contigs, $self, $entry);
	$bb->pack_start_defaults($ok);
    }

    $bb->pack_start_defaults($cancel);
    $self->action_area->add($bb);

    $button->signal_connect('clicked', sub {
	Utils::select_file( 1, sub { $entry->set_text( $_[0] ); }, sub{} );
    });
    $cancel->signal_connect('clicked', sub{$self->destroy});

    return $self;
}

sub set_update_contigs {
    my($self, $contigs) = @_;
    $self->{'update_contigs'} = $contigs;
}

sub update_contigs {
    my(undef, $self, $entry) = @_;
    my %old_contigs;
    foreach(@{$self->{'update_contigs'}}) {
	my $contig = GENDB::contig->init_name($_);
	$contig->name($_."_deprecated");
	$old_contigs{$_} = $contig;
	my %orfs = %{$contig->fetchorfs};
	foreach $orf (values %orfs ) {
	    $orf->name($orf->name."_deprecated");
	}
    }
    my $contigs = &import_contigs(@_); 
    my @contigs = keys %$contigs;
    if(@contigs == 0) {
	foreach(keys %old_contigs) {
	    $old_contigs->name($_);
	}
      Utils::show_error("Update Filed!");
	$self->destroy;
	return;
    }

    if(@contigs > 1) {
      Utils::show_error("Import only one Contig to update!");
	$self->destroy;
	return;
    }

    my $dia = new GENDB::GUI::PredictionDialog(\@contigs);
    $dia->run_after_prediction(sub { $self->run_update(\%old_contigs, $contigs[0]); $dia->destroy });
    $self->hide;
    $dia->signal_connect("destroy", sub { $self->destroy });
    $dia->show_all;
}

sub run_update {
    my($self, $old_contigs, $new_contig) = @_;
    my $contig = GENDB::contig->init_name($new_contig);
  GENDB::contig->update_contigs($old_contigs, $contig);
    $self->destroy;
}

sub import_and_predict {
    my(undef, $self, $entry, $quit) = @_;
    my $contigs = &import_contigs(@_);
    my @contigs = keys %$contigs;
    return if(@contigs == 0);
 
    my $dia = new GENDB::GUI::PredictionDialog(\@contigs);
    $dia->show_all;
    $dia->signal_connect('destroy', sub { $self->destroy });
    $self->hide;
}

sub import_contigs {
    my(undef, $self, $entry, $quit) = @_;
    my $import_file = $entry->get_text;

    if ($import_file ne "") {
	# create an importer
	my $importer = GENDB::Tools::Importer::Fasta->new($import_file);
	$importer->contig_name_length(30);
	# parse input file and report errors
#	main->update_statusbar("Parsing file, please wait...");
	Gtk->main_iteration while ( Gtk->events_pending );
	
#	    main->update_statusbar("Importing data to GENDB....");
	Gtk->main_iteration while ( Gtk->events_pending );
	$failure = $importer->import_contigs(\&_report);
	if ($failure) {
	  Utils::show_information("Error while importing data: $failure");
	}
#	    main->update_contigs;
#	    main->update_statusbar("");
	Gtk->main_iteration while ( Gtk->events_pending );
	if($quit) {
	    $self->destroy;
	} else {
	    return $importer->contigs;
	}
    }
    else {
      Utils::show_error("Import error: No import file specified!", $dialog);
    }
}

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
#	main->update_statusbar($message, main);
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
    my $label = new Gtk::Label("GENDB requires all contig names to be unique.");
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
