package Utils;

use GENDB::Tools::UserConfig;
use GENDB::GUI::HTMLWidget;
use GENDB::GENDB_CONFIG;
require Exporter;

@ISA = qw (Exporter);
@EXPORT = qw( show_error show_information show_yesno open_url );

my %fcols = (
    'METABOLISM ' =>'green',
    'ENERGY ' =>'red',
    'CELL GROWTH, CELL DIVISION AND DNA SYNTHESIS ' =>'blue',
    'TRANSCRIPTION ' =>'yellow',
    'PROTEIN SYNTHESIS ' =>'cyan',
    'PROTEIN DESTINATION ' =>'magenta',
    'TRANSPORT FACILITATION ' =>'white',
    'CELLULAR TRANSPORT AND TRANSPORTMECHANISMS ' =>'black',
    'CELLULAR BIOGENESIS (proteins are not localized to the corresponding organelle) ' =>'orange',
    'CELLULAR COMMUNICATION/SIGNAL TRANSDUCTION ' =>'pink',
    'CELL RESCUE, DEFENSE, CELL DEATH AND AGEING ' =>'lightyellow',
    'IONIC HOMEOSTASIS ' =>'purple',
    'CELLULAR ORGANIZATION (proteins are localized to the corresponding organelle) ' =>'darkgreen',
    'TRANSPOSABLE ELEMENTS, VIRAL AND PLASMID PROTEINS' =>'darkblue',
    'CLASSIFICATION NOT YET CLEAR-CUT ' =>'gold',
    'UNCLASSIFIED PROTEINS ' =>'lightgreen'
);

1;

#####################################################
### pops up a dialog box showing an error message ###
### and an "Ok" button                            ###
#####################################################
sub show_error {
    my $text = shift @_;
    my $parent = shift @_;

    my $dialog = new Gtk::Dialog;
    $dialog->title("GenDB:: ERROR - Dialog!");
    $dialog->set_modal(1);
    $dialog->set_position('mouse');

    my $label = new Gtk::Label($text);

    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("OK");
    $ok_button->signal_connect( 'clicked', sub { $dialog->destroy; } );

    $button_box->add($ok_button);

    $dialog->vbox->border_width(5);
    $dialog->vbox->pack_start($label, 1, 1, 10);
    $dialog->action_area->add($button_box);   
    
    $dialog->show_all;
};

###################################################
### pops up a dialog box showing an information ###
### and an "Ok" button                          ###
###################################################
sub show_information {
    my $text = shift @_;
    my $parent = shift @_;

    my $dialog = new Gtk::Dialog;
    $dialog->title("GenDB:: INFORMATION - Dialog!");
    $dialog->set_modal(1);
    $dialog->set_position('mouse');

    my $label = new Gtk::Label($text);

    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("OK");
    $ok_button->signal_connect( 'clicked', sub { $dialog->destroy; } );

    $button_box->add($ok_button);

    $dialog->vbox->border_width(5);
    $dialog->vbox->pack_start($label, 1, 1, 10);
    $dialog->action_area->add($button_box);   
    
    $dialog->show_all;
};


####################################################
### popup a warning dialog with yes/no selection ###
### if yes-button clicked run &$do_yes_ref       ###
### if no-button clicked run &$do_no_ref         ###
####################################################
sub show_yesno {
    my ($text, $parent, $do_yes_ref, $do_no_ref) = @_;

    $do_no_ref = sub{} if( ref $do_no_ref ne 'CODE' );
    $do_yes_ref = sub{} if( ref $do_yes_ref ne 'CODE' );

    my $dialog = new Gtk::Dialog;
    $dialog->title("GenDB:: WARNING - Dialog!");
    $dialog->set_modal(1);
    $dialog->set_position('mouse');

    my $label = new Gtk::Label($text);

    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("OK");
    $ok_button->signal_connect( 'clicked', sub { 
	&$do_yes_ref;
	$dialog->destroy;
    } );
    my $cancel_button = new Gtk::Button("Cancel");
    $cancel_button->signal_connect('clicked', sub { 
	&$do_no_ref;
	$dialog->destroy;
    } );

    $button_box->add($ok_button);
    $button_box->add($cancel_button);

    $dialog->vbox->add($label);
    $dialog->action_area->add($button_box);   
    
    $dialog->show_all;
};


####################################################
### popup a fileselectiondialog                  ###
### and displays a message                       ###
### if ok-button clicked run &$do_ok_ref         ###
### if cancel-button clicked run &$do_cancel_ref ###
###                                              ###
###    first arg = 'selected file'               ###
####################################################
sub show_filesel {
    my( $text, $modal, $do_ok_ref, $do_cancel_ref ) = @_;
    my $dia = new Gtk::Dialog;
    $dia->set_title( 'Select File' );
    $dia->vbox->pack_start_defaults( new Gtk::Label( $text ) );
    my $hbox = new Gtk::HBox( 0, 10 );
    my $fentry = new Gtk::Entry;
    my $sel = new Gtk::Button( 'Browse' );
    $sel->signal_connect( 'clicked', sub {
	select_file( $modal, sub { $fentry->set_text( $_[0] ); }, sub{} );
    } );
    $dia->vbox->set_border_width( 5 );
    $hbox->pack_start_defaults( $fentry );
    $hbox->pack_start_defaults( $sel );
    $dia->vbox->pack_start_defaults( $hbox );

    my $b = new Gtk::Button( "OK" );
    $b->signal_connect( 'clicked', sub { 
	my $file = $fentry->get_text;
	$dia->destroy;
	&$do_ok_ref( $file );
    } );
    $dia->action_area->pack_start_defaults( $b );
			  
    $b = new Gtk::Button( "Cancel" );
    $b->signal_connect( 'clicked', sub { 
	my $file = $fentry->get_text;
	$dia->destroy;
	&$do_cancel_ref( $file );
    } );
    $dia->action_area->pack_start_defaults( $b );
    $dia->set_position( 'center' );
    $dia->show_all;
}


####################################################
### popup a fileselectiondialog                  ###
### if ok-button clicked run &$do_ok_ref         ###
### if cancel-button clicked run &$do_cancel_ref ###
###                                              ###
###    first arg = 'selected file'               ###
####################################################
sub select_file {
    my( $modal, $do_ok_ref, $do_cancel_ref ) = @_;
    my $filesel = new Gtk::FileSelection( 'Select File' );
    $filesel->set_modal( $modal );
    $filesel->ok_button->signal_connect( 'clicked', sub {
	my $file = $filesel->get_filename;
	$filesel->destroy;
	&$do_ok_ref( $file );
    } );

    $filesel->cancel_button->signal_connect( 'clicked', sub {
	my $file = $filesel->get_filename;
	$filesel->destroy;
	&$do_cancel_ref( $file );
    } );

    $filesel->set_position( 'center' );
    $filesel->show;
}

####################################################
###     open URL in Userdefined browser          ###
####################################################

sub open_url {
    my( $url ) = @_;

    my $browser = GENDB::Tools::UserConfig->get_parameter("browser");

    my $cmd = "";
    
    # check for each browser whether it is configured and selected
    # as default browser

    # netscape
    if (defined $GENDB::GENDB_CONFIG::GENDB_NETSCAPE &&
	($browser =~ /netscape/i)) {
	$cmd = $GENDB::GENDB_CONFIG::GENDB_NETSCAPE." -remote 'openURL(".$url.",new-window) ||"..$GENDB::GENDB_CONFIG::GENDB_NETSCAPE." ".$url;
    } 
    
    # konqueror
    elsif (defined $GENDB::GENDB_CONFIG::GENDB_KONQUEROR &&
	     ($browser =~ /.*onqueror/)) {
	$cmd = $GENDB::GENDB_CONFIG::GENDB_KONQUEROR." ".$url;
    }
    
    # opera
    elsif (defined  $GENDB::GENDB_CONFIG::GENDB_OPERA && 
	     ($browser =~ /opera/i)) {
	$cmd = $GENDB::GENDB_CONFIG::GENDB_OPERA." -remote 'openURL(".$url.",new-window)'";
    } 

    # gtk html widget 
    elsif(defined $GENDB::GENDB_CONFIG::GENDB_GTKHTML) {
	# display new gtk window and return 
	my $html = new HTMLWidget( $url );
	$html->set_title( 'GenDB Internal Browser' );
	$html->set_default_size( 800, 600 );
	$html->set_position( 'center' );
	$html->show_all;
	return;
    } else {
      show_error('No usable browser setup found. Please configure browser!');
    }
    
    # execute command and show an error box if the command failed
    system ($cmd." &");
    if ($!) {
	show_error("Cannot start browser, please check your configuration: $!");
    }
}

#######################################################
### dialog to edit user configuration               ###
#######################################################

sub open_config_dialog {
    my $dia = new Gtk::Dialog;
    $dia->set_title( "Configuration" );
    my $hbox = new Gtk::HBox( 0, 0 );
    $hbox->set_border_width( 5 );
    my $browserlist = new Gtk::Combo;
    $browserlist->entry->set_editable( 0 );
    $browserlist->set_popdown_strings( qw( Netscape KDE-Konqueror Opera Internal-Browser ) );
    $browserlist->entry->set_text( GENDB::Tools::UserConfig->get_parameter("browser") );
    $hbox->pack_start_defaults( new Gtk::Label( "Default Browser: " ) );
    $hbox->pack_start_defaults( $browserlist );
    
    $dia->vbox->pack_start_defaults( $hbox );
    
    my $ok = new Gtk::Button( 'OK' );
    my $cancel = new Gtk::Button( 'Cancel' );
    $dia->action_area->pack_start_defaults( $ok );
    $dia->action_area->pack_start_defaults( $cancel );
    
    $ok->signal_connect( 'clicked', sub{ 
        GENDB::Tools::UserConfig->set_parameter( "browser", $browserlist->entry->get_text );
	$dia->destroy
	});
    $cancel->signal_connect( 'clicked', sub{ $dia->destroy } );
    $dia->set_position( 'center' );
    $dia->show_all;
}

###########################################
###                                     ###
###     Dialog to configure FactView    ###
###                                     ###
###########################################

sub open_fact_view_configuration {
    my $dia = new Gtk::Dialog;
    my $list = new_with_titles Gtk::CList(( 'ID', 'Name', 'Description' ));
    $list->set_selection_mode( 'multiple' );
    $list->set_column_visibility( 0, 0 );
    $list->set_column_width( 1, 160 );
    $list->set_column_width( 2, 160 );
    
    my $lscr = new Gtk::ScrolledWindow;
    $lscr->set_policy( 'automatic', 'automatic' );
    $lscr->add( $list );
    my $hbox = new Gtk::HBox( 1, 1 );
    $hbox->pack_start_defaults( new Gtk::Label( 'max Level to Show' ) );
    my $level_combo = new Gtk::Combo;
    $level_combo->set_popdown_strings( 'Level0', 'Level1', 'Level2', 'Level3', 'Level4', 'Level5' );
    $hbox->pack_start_defaults( $level_combo );
    $dia->vbox->pack_start_defaults( $lscr );
    my $tools = GENDB::tool->fetchall;
    my @toollist = split( / /, GENDB::Tools::UserConfig->get_parameter( "toollist" ) );
    $level_combo->entry->set_text( GENDB::Tools::UserConfig->get_parameter( "factlevel" ) );

    foreach my $tool ( @$tools ) {
	$list->append( $tool->id, $tool->name, $tool->description );
    }
    my $i = 0;
    while( $i < $list->rows ) {
	foreach( @toollist ) {
	    if( $list->get_text( $i, 0 ) == $_ ) {
		$list->select_row( $i, 0 );
	    }
	}
	$i++;
    }

    $dia->vbox->pack_end( $hbox, 0, 0, 5 );
    my $ok = new Gtk::Button( 'OK' );
    $ok->signal_connect( 'clicked', sub{ 
	my @rows = $list->selection;
	my $level = $level_combo->entry->get_text;
	my $tools;
	foreach( @rows ) {
	    $tools .= $list->get_text( $_, 0 )." ";
	}
        GENDB::Tools::UserConfig->set_parameter( "toollist", $tools );
	GENDB::Tools::UserConfig->set_parameter( "factlevel", $level );
	$dia->destroy 
	} );
    my $cancel = new Gtk::Button( 'Cancel' );
    $cancel->signal_connect( 'clicked', sub { $dia->destroy } );
    my $bb = new Gtk::HButtonBox;
    $bb->set_layout_default('spread');
    $bb->add( $ok );
    $bb->add( $cancel );
    $dia->action_area->pack_start_defaults( $bb );
    $dia->set_default_size( 450, 300 );
    $dia->set_position( 'center' );
    $dia->show_all;
}

####################################### 
#                                     #
# return the color for a specific ORF #
# 'type' = 'funcat' or 'status'       # 
#######################################

sub get_color_for_orf {
    my( $orf, $type ) = @_;

    if( GENDB::Tools::UserConfig->get_parameter( 'orf_colors' ) eq 'funcat' ) {
	my $a = $orf->latest_annotation;
	if( $a != -1 ) {
	    my $c = $a->category;
	    $c = 243 if( $c eq "" );
	    my $funcat = GENDB::funcat->init_id( $c )->get_toplevel_parent->name;
	    return $fcols{$funcat};
	} else {
	    return 'lightgreen';
	}
    } else {
	return @{GENDB::Tools::UserConfig->get_parameter('orf_status_colors')}[$orf->status]
	    if( $type eq 'normal' );
    
	return @{GENDB::Tools::UserConfig->get_parameter('selected_orf_status_colors')}[$orf->status];
    }
}
