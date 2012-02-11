package GENDB::GUI::Delete;

$VERSION = 1.2;

use GENDB::GUI::Utils;
use GENDB::Config;
use GENDB::contig;
use GENDB::orf;
use GENDB::Common;

#####################################################
###                                               ###
### TODO:                                         ###
### - include function call to update viewer      ###
###   after contig deletion (refresh contig list) ###
### - add more comments                           ###
### - implement delete on orfs & facts            ###
###                                               ###
#####################################################


#################################################
### delete dialog for contigs in gendbproject ###
#################################################
sub delete_dialog {
    my ($call, $mainref)=@_;
   
    my $selected_contig = undef;
    my $selected_row;
    my $dialog = new Gtk::Dialog;
    $dialog->title("Delete contig:");
    $dialog->set_default_size(50,300); 
    $dialog->set_modal(1);
    $dialog->set_position('mouse');

    my $delete_box = new Gtk::VBox(0,0);
    $delete_box->border_width(5);

    my $label = new Gtk::Label("Choose contig to delete from GENDB:");
    $delete_box->pack_start($label, 0, 0, 5);

    my @cols =  ("Contigs in $GENDB_PROJECT");
    my $list = new_with_titles Gtk::CList( @cols );
    $list->set_column_width(0, 200 );
    $list->signal_connect( 'select_row', \&listrow_selected, \$selected_contig, \$selected_row );
    
    my $contig_ref = GENDB::contig->fetchallby_name;
    $list->freeze;
    foreach $contig_name (sort(keys(%$contig_ref))) {
	my $contig = $contig_ref->{$contig_name};
	$list->append(($contig->name()));	
    };
    $list->thaw;

    ### scrolled window for CList with contigs
    my $listscroller = new Gtk::ScrolledWindow;
    $listscroller->set_policy('automatic', 'automatic');
    $listscroller->add($list);
    $delete_box->pack_start($listscroller, 1, 1, 0);

    ### Put buttons into HButtonBox
    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("Delete contig");
    $ok_button->signal_connect( 'clicked', sub {
	if (defined $selected_contig) {
	    &show_check_delete(\$list, \$selected_contig, \$selected_row);
	}
	else {
	  Utils::show_error("Delete error: No contig selected to delete from GENDB!", $dialog);
	};
    });
    
    my $cancel_button = new Gtk::Button("Cancel");
    $cancel_button->signal_connect( 'clicked', sub { $dialog->destroy; } );

    $button_box->add($ok_button);
    $button_box->add($cancel_button);

    $dialog->vbox->add($delete_box);
    $dialog->action_area->add($button_box);   
    
    $dialog->show_all;
};


#####################################
### create file dialog for delete ###
#####################################
sub listrow_selected {
    my ($widget, $sel_cont_ref, $sel_row_ref, $row, $col, $event) = @_;
    
    if ($event->{'type'} eq 'button_release') {
	if ($event->{'button'} == 1) {
	    my $cont=$widget->get_text($row, 0);
	    $$sel_cont_ref = $widget->get_text($row, 0);
	    $$sel_row_ref = $row;
	
	};
    }
    elsif ($event->{'type'} eq '2button_press') {
	if ($event->{'button'} == 1) {
	    $$sel_cont_ref = $widget->get_text($row, 0);
	    $$sel_row_ref = $row;
	    &show_check_delete(\$widget, $sel_cont_ref, $sel_row_ref);
	};
    };
};


################################################################
### ask once more whether user really wants to delete contig ###
################################################################
sub show_check_delete {
    my ($listref, $contigname_ref, $row_ref) = @_;

    my $contig_list=$$listref;
    my $dialog = new Gtk::Dialog;
    $dialog->title("GenDB:: WARNING - Dialog!");
    $dialog->set_modal(1);
    $dialog->set_position('mouse');
    $dialog->set_policy( 0, 0, 1); 

    my $label = new Gtk::Label("Do you really want to delete contig $$contigname_ref?\nAll Information about Orfs, Facts and the contig itself will be deleted.\nThere is no way to restore these data!");

    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("OK");
    $ok_button->signal_connect( 'clicked', sub { 
	my $contig = GENDB::contig->init_name($$contigname_ref);
	$contig->delete_complete;
	$contig_list->remove($$row_ref);
	$dialog->destroy;
	$$contigname_ref = undef;
	main->update_statusbar("Deleted contig $$contigname_ref and all associated information.");
	main->update_contigs;
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


1;
