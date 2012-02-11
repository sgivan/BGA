#!/usr/bin/env perl

use strict;
use Gtk;
use IO::Handle;
use Gnome;
use GENDB::Config;
use GENDB::GENDB_CONFIG;
use GENDB::GUI::Utils;
use GENDB::GUI::Import;
use GENDB::GUI::ImportEMBL;
use GENDB::GUI::ImportGenBank;
use GENDB::GUI::Delete;
use GENDB::GUI::Statistic;
use GENDB::GUI::ContigView;
use GENDB::GUI::ContigOverView;
use GENDB::GUI::SequenceCanvas;
use GENDB::GUI::OrfEditor;
use GENDB::GUI::OrfCreator;
use GENDB::GUI::SequenceEditor;
use GENDB::GUI::FrameshiftCorrection;
use GENDB::GUI::GeneTree;
use GENDB::GUI::VirtualGel;
use GENDB::GUI::JobStatusWindow;
use GENDB::GUI::UpdateDialog;
use GENDB::Pathways::Pathways;
use GENDB::Pathways::KeggPathways;
use GENDB::Tools::gff_export;
use GENDB::Common;
use GENDB::annotation;
use GENDB::GUI::UserConfDialog;

STDOUT->autoflush(1);
my $RELEASE = "1.1.1";
my $startup;
my $statusbar;

BEGIN {
    init Gnome "GENDB";
    $startup = new Gtk::Window( 'toplevel' );
    $startup->set_title( "GENDB:: Startup" );
    $startup->set_position('center');
    $startup->set_policy( 0, 0, 1); 
    $startup->signal_connect('delete_event', sub{1});
    $startup->realize;

    my $style = $startup->get_style()->bg( 'normal' );
    my ( $pixmap, $mask ) = Gtk::Gdk::Pixmap->create_from_xpm( $startup->window, $style, "$GENDB_INSTALL_DIR/share/splash.xpm" );
    # a pixmap widget to contain the pixmap
    my $pixmapwid = new Gtk::Pixmap( $pixmap, $mask );
    # a button to contain the pixmap widget
    my $startbox = new Gtk::VBox( 0, 0 );
    $startbox->pack_start($pixmapwid, 1, 1, 0);

    $statusbar = new Gtk::Statusbar;
    $statusbar->push(1, "Please wait! Starting up ...");
    Gtk->main_iteration while ( Gtk->events_pending );
    $startbox->pack_start($statusbar, 1, 1, 0);
    $startup->add( $startbox );
    $startup->show_all;
    Gtk->main_iteration while ( Gtk->events_pending );
    
    $statusbar->push(1, "Please wait! Initializing modules ...");
    Gtk->main_iteration while ( Gtk->events_pending );    
    
}END;

#####
# setup http proxy
#
if (!defined($ENV{http_proxy}) && $GENDB_HTTP_PROXY) {
    # no proxy defined and a proxy was setup in config file -> use it
    $ENV{http_proxy}=$GENDB_HTTP_PROXY;
}

#####
# setup http server
#
QuerySRS->set_server($GENDB_SRS);

####################################################################
# Fetch all annotated EC numbers for latest annotation of all ORFs #
####################################################################
$statusbar->push(1, "Please wait! Fetching annotated EC numbers ...");
Gtk->main_iteration while ( Gtk->events_pending );
my ($ec_list, $orfecs_ref) = GENDB::annotation::fetchall_ecs();


##################################
# Remove duplicates from ec_list #
##################################
my @ecnums=split(',',$ec_list);
$statusbar->push(1, "Please wait! Removing duplicates from EC list ...");
Gtk->main_iteration while ( Gtk->events_pending );
my $ec;
my %unique_ec_hash=();

foreach $ec (@ecnums) {
    $unique_ec_hash{$ec}=1;
};

$statusbar->push(1, "Please wait! GENDB is coming up ...");
Gtk->main_iteration while ( Gtk->events_pending );

# create all Widgets
my $canvas = new Gnome::Canvas;
my $mainWindow = new Gtk::Window( 'toplevel' );
my $mainbox = new Gtk::VBox( 0, 0 );
my $notebook = new Gtk::Notebook;
my $mainpaned = new Gtk::VPaned;
my $statusbar = new Gtk::Statusbar;
my $progress = new Gtk::ProgressBar;
my $contigview = new GENDB::GUI::ContigView;
my $genetree = new GeneTree;
my $pathways = new GENDB::Pathways::Pathways(\%unique_ec_hash, $orfecs_ref);
my $keggpathways = new GENDB::Pathways::KeggPathways(\%unique_ec_hash);
my $statistics = new Statistic;
my $contigoverview = new ContigOverView;
my $baseview = new SequenceCanvas;
my $viewbox = new Gtk::VPaned;
my $bvwin = undef;
my $update = 1;

$baseview->set_visible_size( 300 );
$notebook->set_border_width(3);

$mainbox->pack_start( &menuBar, 0, 0, 0 );

&create_page( $contigview, 'Contigs', 0 );
&create_page( $genetree, 'Annotated genes', 1 );
&create_page( $pathways, 'PathFinder', 2 );
&create_page( $keggpathways, 'Kegg Pathways', 3 );
&create_page( $statistics, 'Statistics', 4 );

&make_baseview_selection_cb($baseview);

$viewbox->add1( $contigoverview );
$viewbox->add2( $baseview );
$viewbox->set_position( 70 );
$viewbox->gutter_size( 10 );

$mainpaned->set_position( 500 );
$mainpaned->gutter_size( 10 );
$mainpaned->add1( $notebook );
$mainpaned->add2( $viewbox );
$mainbox->pack_start_defaults( $mainpaned );
$statusbar->pack_end( $progress, 0, 0, 0 );
$mainbox->pack_end( $statusbar, 0, 0, 0 );

$mainWindow->add( $mainbox );
$mainWindow->set_usize( 1000, 800 );

$progress->set_format_string( "%v from %u %p%%" ); 
$contigview->set_progress( $progress );
$pathways->set_progress( $progress );
$keggpathways->set_progress( $progress );
$statistics->set_progress( $progress );
$genetree->set_progress( $progress );

$contigview->set_base_view( $baseview );

# signals
$mainWindow->signal_connect( 'destroy', sub{ Gtk->exit( 0 ); } );
$contigview->signal_connect( 'contig_changed', sub {$contigoverview->set_contig( $_[0] );} );
$statistics->signal_connect( 'contig_changed', sub {$contigoverview->set_contig( $_[0] );} );
$contigoverview->signal_connect( 'contig_changed', \&set_contig );

$mainWindow->set_title( "GENDB:: $GENDB_PROJECT" );

my $page = GENDB::Tools::UserConfig->get_parameter( "orf information" );
$contigview->set_information_widget( $page );

$startup->destroy;
$mainWindow->show_all;

main Gtk;



#########################
###    Subroutines    ###
#########################

########################################################
# Create the Menubar and all necessary Menus/MenuItems #
########################################################
sub menuBar {
    my $mb = new Gtk::MenuBar;

    # Items in MenuBar
    my $manage_item = new Gtk::MenuItem( "Management" );
    my $wizards_item = new Gtk::MenuItem( "Wizards" );
    my $options_item = new Gtk::MenuItem( "Options" );
    my $menubar_help_item = new Gtk::MenuItem( "Help");
    $menubar_help_item->right_justify;
    
    # Append items to MenuBar
    $mb->append($manage_item);
    $mb->append($wizards_item);
    $mb->append($options_item);
    $mb->append($menubar_help_item);
    
    #####################################
    # Menu for main Management in GenDB #
    #####################################
    my $manage_menu = new Gtk::Menu;
    
    # Create the menu items
    my $add_contig_item = new Gtk::MenuItem( "Import new contig..." );
    my $add_embl_item = new Gtk::MenuItem ("Import from EMBL file...");
    my $add_genbank_item = new Gtk::MenuItem ("Import from GenBank file...");
    my $delete_contig_item = new Gtk::MenuItem( "Delete contig..." );
    my $export_data = new Gtk::MenuItem( "Export data..." );
    $export_data->set_sensitive(0);
    my $export_gff = new Gtk::MenuItem( "Export gff..." );
    $export_gff->set_sensitive(0);
    my $update_item = Gtk::MenuItem->new("Update contigs...");
    my $quit_item = new Gtk::MenuItem( "Quit" );
    
    # Add them to the menu
    $manage_menu->append( $add_contig_item );
    $manage_menu->append($add_embl_item);
    $manage_menu->append($add_genbank_item);
    $manage_menu->append( $delete_contig_item );
    $manage_menu->append($update_item);
    $manage_menu->append( new Gtk::MenuItem() );
    ### $manage_menu->append( $export_data );
    ### $manage_menu->append( $export_gff );
    ### $manage_menu->append( new Gtk::MenuItem() );
    $manage_menu->append( $quit_item );
    
    # Attach the callback functions to the activate signal
    $add_contig_item->signal_connect( 'activate', \& GENDB::GUI::Import::add_contig, \$mainbox );
    $add_embl_item->signal_connect('activate',\& GENDB::GUI::ImportEMBL::add_embl, \$mainbox);
    $add_genbank_item->signal_connect('activate', \& GENDB::GUI::ImportGenBank::add_genbank, \$mainbox);
    $delete_contig_item->signal_connect( 'activate', \& GENDB::GUI::Delete::delete_dialog, \$mainbox );
    $export_data->signal_connect( 'activate', \&export_data );    
    $export_gff->signal_connect( 'activate', \& Tools::gff_export::export_gff );
    $update_item->signal_connect('activate', sub {
	my $dia = new GENDB::GUI::UpdateDialog;
	$dia->show_all;
    });

    $quit_item->signal_connect( 'activate', sub{ Gtk->exit( 0 ); } );
    
    $manage_item->set_submenu($manage_menu);

    #######################################
    # Menu for available Wizards in GenDB #
    #######################################
    my $wizards_menu = new Gtk::Menu;
    
    # Create the menu items
    my $sequence_editor = new Gtk::MenuItem( "Sequence Editor..." );
    my $frame_correct_item = new Gtk::MenuItem( "Frameshift correction..." );
    my $autoannotator_item = new Gtk::MenuItem( "Auto Annotator..." );
    my $codon_item = new Gtk::MenuItem( 'Virtual 2D Gel' );

    my $orf_editor_item = new Gtk::MenuItem( "ORF Creator..." );
    #$orf_editor_item->set_sensitive(0);
 
    # Add them to the menu
    $wizards_menu->append ($sequence_editor );
    $wizards_menu->append( $frame_correct_item );
    $wizards_menu->append( $orf_editor_item );
#    $wizards_menu->append( $autoannotator_item );
    $wizards_menu->append( $codon_item );
  
    # Attach the callback functions to the activate signal
    $sequence_editor->signal_connect( 'activate', sub {
	new SequenceEditor->show;
    } );
    $autoannotator_item->signal_connect( 'activate', sub {
	new AutoAnnotatorDialog->show;
    } );


    $frame_correct_item->signal_connect( 'activate', sub {
	new FrameshiftCorrection->show;
    } );
    $orf_editor_item->signal_connect( 'activate', sub {
	my $creator = new OrfCreator;
	$creator->set_title("GENDB::OrfCreator");
	$creator->set_position('center');
	$creator->show;
    });
    
    $codon_item->signal_connect( 'activate', sub {
	my $cbdia = new VirtualGel;
	$cbdia->set_title( '2D Gel' );
	$cbdia->show_all;
	$cbdia->set_progress($progress);
	$cbdia->plotter->spot_selection_connect( sub{ 
	    my $orf = GENDB::orf->init_name( $_[0] ); 
	    my $members = $cbdia->plotter->get_class_members;
	    if( defined( $members ) ) {
		$contigview->orf_canvas->group_orfs( $members );
	    }
	    &show_orf( undef, $orf->id ) if( $orf != -1 );
	} );
	$cbdia->signal_connect( 'destroy', sub{ $contigview->orf_canvas->group_orfs } );
	$cbdia->show_gel;
	$cbdia->show_all;
    } );

    $wizards_item->set_submenu($wizards_menu);

    #######################################
    # Menu for available Options in GenDB #
    #######################################
    my $options_menu = new Gtk::Menu;
    
    my $ignored_item = new Gtk::MenuItem('show ignored ORFs in:');
    my $ignored_menu = new Gtk::Menu;
    
    # Create the menu items
    my $show_ignored_orfs_item = new Gtk::CheckMenuItem( "ORF Window" );
    $show_ignored_orfs_item->set_active(GENDB::Tools::UserConfig->get_parameter("ignored_orfs"));
    $show_ignored_orfs_item->set_show_toggle(1);
    $ignored_menu->append($show_ignored_orfs_item);
    
    my $show_ignored_orfs_item_in_list = new Gtk::CheckMenuItem( "ORF List" );
    $show_ignored_orfs_item_in_list->set_active(GENDB::Tools::UserConfig->get_parameter("ignored_orfs_in_list"));
    $show_ignored_orfs_item_in_list->set_show_toggle(1);
    $ignored_menu->append($show_ignored_orfs_item_in_list);
    
    my $show_ignored_orfs_item_in_sequence = new Gtk::CheckMenuItem( "Sequence Window" );
    $show_ignored_orfs_item_in_sequence->set_active(GENDB::Tools::UserConfig->get_parameter("ignored_orfs_in_sequence"));
    $show_ignored_orfs_item_in_sequence->set_show_toggle(1);
    $ignored_menu->append($show_ignored_orfs_item_in_sequence);
    

    $ignored_item->set_submenu($ignored_menu);

    my $baseview_item = new Gtk::MenuItem( "Baseview" );
    my $orflist_item = new Gtk::MenuItem( "ORF Information" );
    my $color_item = new Gtk::MenuItem( "ORF color" );
    my $pathways_item = new Gtk::MenuItem( "Pathways" );
    
    my $center_orf_item = new Gtk::CheckMenuItem( "Center Orf" );
    $center_orf_item->set_active(GENDB::Tools::UserConfig->get_parameter("center_orf"));
    $center_orf_item->set_show_toggle(1);
    $options_menu->append( $center_orf_item );
    
    $center_orf_item->signal_connect('activate', sub {
      GENDB::Tools::UserConfig->set_parameter("center_orf", $center_orf_item->active );
      });

    # Add normal option items to menu
    $options_menu->append( $ignored_item );
    $show_ignored_orfs_item->signal_connect( 'activate', \&show_ignored_orfs, "ignored_orfs" );
    $show_ignored_orfs_item_in_sequence->signal_connect( 'activate', \&show_ignored_orfs, "ignored_orfs_in_sequence" );
    $show_ignored_orfs_item_in_list->signal_connect( 'activate', \&show_ignored_orfs, "ignored_orfs_in_list" );
    
    $options_menu->append( new Gtk::MenuItem() );

    # Add submenus to the menu
    $options_menu->append( $baseview_item );
    $options_menu->append( $orflist_item );
    $options_menu->append( $color_item );
    ### $options_menu->append( $pathways_item );
  
    $options_item->set_submenu($options_menu);

    # Baseview submenu ...
    my $baseview_menu = new Gtk::Menu;
    $baseview_item->set_submenu($baseview_menu);

    # ... and its items
    my $showbaseview_item = new Gtk::CheckMenuItem( "Show" );
    $showbaseview_item->set_active(1);
    $showbaseview_item->set_show_toggle(1);
    $baseview_menu->append($showbaseview_item);
    $showbaseview_item->signal_connect( 'activate', \&show_base_view );

    my $baseview_inwindow_item = new Gtk::CheckMenuItem( "Window" );
    $baseview_inwindow_item->set_active(0);
    $baseview_inwindow_item->set_show_toggle(1);
    $baseview_menu->append($baseview_inwindow_item);
    $baseview_inwindow_item->signal_connect( 'activate', \&base_view_window );
    
    # ORF list submenu ...
    my $orflist_menu = new Gtk::Menu;
    $orflist_item->set_submenu($orflist_menu);

    # ... and its items
    my $showorflist_item = new Gtk::RadioMenuItem( "ORF List" );
    $orflist_menu->append($showorflist_item);
    my $page = GENDB::Tools::UserConfig->get_parameter("orf information");
    $showorflist_item->signal_connect( 'activate', \&show_all_orfs, 0 );
    $showorflist_item->active(0);
    my $showorfdesc_item = new Gtk::RadioMenuItem( "ORF Description", $showorflist_item );
    $orflist_menu->append($showorfdesc_item);
    $showorfdesc_item->signal_connect( 'activate', \&show_all_orfs, 1 );
    $showorfdesc_item->active(0);
    my $showcgplot_item = new Gtk::RadioMenuItem( "CG Content", $showorfdesc_item );
    $orflist_menu->append($showcgplot_item);
    $showcgplot_item->signal_connect( 'activate', \&show_all_orfs, 2 );
    $showcgplot_item->active(0);
    ($showorflist_item, $showorfdesc_item, $showcgplot_item)[$page]->active(1);


    # ORF color submenu ...
    my $color_menu = new Gtk::Menu;
    $color_item->set_submenu( $color_menu );
    
    my $state_item = new Gtk::RadioMenuItem( "State" );
    $color_menu->append($state_item);
    $state_item->signal_connect( 'activate', \&orf_color, 'state' );
    my $funcat_item = new Gtk::RadioMenuItem( "Category", $state_item );
    $color_menu->append($funcat_item);
    $funcat_item->signal_connect( 'activate', \&orf_color, 'funcat' );
    

    # Pathways submenu ...
    my $pathways_menu = new Gtk::Menu;
    $pathways_item->set_submenu($pathways_menu);

    # ... and its items
    my $use_xvcg_item = new Gtk::CheckMenuItem( "Use XVCG" );
    $use_xvcg_item->set_sensitive(0);
    $use_xvcg_item->set_active(1);
    $use_xvcg_item->set_show_toggle(1);
    $pathways_menu->append($use_xvcg_item);
    $use_xvcg_item->signal_connect( 'activate', \&enable_xvcg_usage );
    
    my $auto_redraw_item = new Gtk::CheckMenuItem( "Automatic pathway redraw" );
    $auto_redraw_item->set_sensitive(0);
    $auto_redraw_item->set_active(1);
    $auto_redraw_item->set_show_toggle(1);
    $pathways_menu->append($auto_redraw_item);
    $auto_redraw_item->signal_connect( 'activate', \&enable_auto_redraw );
    
    $options_menu->append( new Gtk::MenuItem );
    my $config_item = new Gtk::MenuItem( 'Configuration' );
    $config_item->signal_connect( 'activate', sub{ 
	my $dia = new UserConfDialog;
	$dia->show_all if($dia != -1);
    });
    $options_menu->append( $config_item );
    
    ##########################################
    # Menu for help and information in GenDB #
    ##########################################
    my $help_menu = new Gtk::Menu;
    
    # Create the menu items
    my $help_item = new Gtk::MenuItem( "Help..." );
    my $job_item = new Gtk::MenuItem( "Job Status..." );
    my $about_item = new Gtk::MenuItem( "About GenDB..." );
 
    # Add them to the menu
    $help_menu->append( $help_item );
    $help_menu->append( $job_item);
    $help_menu->append( $about_item );
  
    # Attach the callback functions to the activate signal
    $help_item->signal_connect( 'activate', \&help );
    $about_item->signal_connect( 'activate', \&show_about );
    $job_item->signal_connect( 'activate', sub {
	my $win = new GENDB::GUI::JobStatusWindow;
	$win->show_all;
    });
	
    $menubar_help_item->set_submenu($help_menu);    
    
    return $mb;
};



sub base_view_window {
    my( $mi ) = @_;
    if( $update ) { 
	if( $mi->active ) {
	    if( $baseview->is_visible ) {
		$bvwin = new Gtk::Window;
		$bvwin->set_title( "BaseView of contig ".$baseview->get_contig_name );
		$bvwin->signal_connect( 'delete_event',  sub { $mi->set_active(0), &base_view_window( $mi ), Gtk->true; } );
		$bvwin->set_usize( 600, 300 );
		$baseview->reparent( $bvwin );
		$viewbox->set_position( 7500 );
		$bvwin->show_all;
	    } else {
		$mi->set_active(0);
	    }
	} else {
	    if( $bvwin ) {
		if( $baseview->is_visible ) {
		    $bvwin->remove( $baseview );
		    $viewbox->add2( $baseview );
		    $bvwin->destroy;
		    $viewbox->set_position( 75 );
		    $bvwin = undef;
		} else {
		    $update = 0;
		    $mi->set_active(1);
		}
	    }
	}
    } else {
	$update = 1;
    }
}



sub show_base_view {
    my( $mi ) = @_;

    if( $mi->active ) {
	if( $bvwin ) {
	    $bvwin->show;
	} else {$viewbox->set_position( 75 );}
	$baseview->showme;
	
    } else {
	if( $bvwin ) {
	    $bvwin->hide;
	}
	$baseview->hideme;
	$viewbox->set_position( 7500 );
    }
};


######################################
# change option value in config file #
######################################
sub show_all_orfs {
    my( $mi, $page ) = @_;

    if( $mi->active ) {
	$contigview->set_information_widget( $page );
      GENDB::Tools::UserConfig->set_parameter( "orf information", $page );
    }
};


#################
# set ORF color #
#################
sub orf_color {
    my( $mi, $color ) = @_;
    if( $mi->active ) {
      GENDB::Tools::UserConfig->set_parameter( "orf_colors", $color );
    }
};

sub show_ignored_orfs {
    my( $mi, $wo ) = @_;
  GENDB::Tools::UserConfig->set_parameter( $wo, ($mi->active) ? 1 : 0 );
    $contigview->orf_canvas->update if( $wo eq 'ignored_orfs' );
    $baseview->update if( $wo eq 'ignored_orfs_in_sequence' );
    $contigview->update_list if( $wo eq 'ignored_orfs_in_list' );
};

sub update_orfs {
    $contigview->update_contig_tree;
    $genetree->update_tree;
}

sub update_contigs {
    $contigview->update_contig_tree;
    $genetree->update_tree;
    $contigoverview->update;
    $baseview->reload_contig;
};

sub update_all {
    $contigview->update_list;
};


########################
# update the statusbar #
########################
sub update_statusbar {
    my ($self, $txt) = @_;

    Gtk->main_iteration while(Gtk->events_pending);
    $statusbar->push(1, $txt);
};


#########################################
# change between normal and busy cursor #
#########################################
sub busy_cursor {
    my ($self, $widget, $busy) = @_;
    
    my $child;
    if ($busy) {
	$mainbox->get_parent_window->set_cursor(Gtk::Gdk::Cursor->new(150));
	if ($widget->children) {
	    foreach $child ($widget->children) {
		if(ref $child eq 'Gtk::BoxChild') {
		    $child->widget->get_parent_window->set_cursor(Gtk::Gdk::Cursor->new(150));
		} else {
		    $child->get_parent_window->set_cursor(Gtk::Gdk::Cursor->new(150));
		}
	    };
	};
    }
    else {
	$mainbox->get_parent_window->set_cursor(Gtk::Gdk::Cursor->new(68));
	if ($widget->children) {
	    foreach $child ($widget->children) {
		if(ref $child eq 'Gtk::BoxChild') {
		    $child->widget->get_parent_window->set_cursor(Gtk::Gdk::Cursor->new(68));
		} else {
		    $child->get_parent_window->set_cursor(Gtk::Gdk::Cursor->new(68));
		}
	    };
	};
    };
    Gtk::Gdk->flush;
    Gtk->main_iteration while ( Gtk->events_pending );
};


#####################################
# get name of current GENDB project #
#####################################
sub gendb_project {
    return $GENDB_PROJECT;
};


#######################################
# change the current contig selection #
#######################################
sub set_contig {
    my $contig = shift;

    $baseview->set_contig( $contig );
    $contigview->set_contig( $contig );
};



sub show_orf {
    my( $self, $orf ) = @_;
    # set_orf holt aus der orf_id den orfnamen und den contignamen und ruft
    # show_contig_orf auf
    if( $contigview->set_orf( $orf ) ) { 
	Gtk->main_iteration while( Gtk->events_pending );
	$contigview->scroll;
	$notebook->set_page(0);
    }
}

sub show_contig_orf {
    my( $self, $contigname, $orfname ) = @_;
    $contigview->show_contig_orf( $contigname, $orfname );
};


##############################################
# open a tab folder in a separate new window #
##############################################
sub to_window {
    my ( $button, $widget, $name, $pos, $active_page ) = @_;

    my $window = new Gtk::Window( 'toplevel' );
    $widget->{'in_external_window'}=1;
    $window->signal_connect( 'destroy', \&back_to_main, $widget, $name, $pos );
    $window->set_title( $name );
    $widget->reparent($window);
    $window->set_usize( 750, 600 );
    if (defined $active_page) {
	$notebook->set_page($active_page);
    };

    $window->show_all;
};


###############################################
# put a window back into the GENDB main frame #
###############################################
sub back_to_main {
    my ( $window, $widget, $name, $pos ) = @_;

    $window->remove( $widget );
    $window->hide;
    $window->destroy;
    $widget->{'in_external_window'}=0;
    &create_page( $widget, $name, $pos );
};


####################################
# create a new notebook tab folder #
####################################
sub create_page {
    my ( $widget, $name, $pos ) = @_;

    my $box = new Gtk::HBox( 0, 0 );
    my $label = new Gtk::Label( $name );
    my $button = new Gtk::Button;
    $button->add( new Gtk::Arrow( 'right', 'etched_in' ) );
    $button->signal_connect( 'clicked', \&to_window, $widget, $name, $pos );
    $box->pack_start( $label, 0, 0, 0 );
    $box->pack_end( $button, 0, 0, 0 );
    $notebook->insert_page( $widget, $box, $pos );
    $notebook->set_page( $pos );
    $box->show_all;
    $notebook->show_all;
};


#############################################
# Show manual and help pages in HTML widget #
#############################################
sub help {    
    
    my $url="file:$GENDB_HELP";
  Utils::open_url( $url );

};


#################################################
# Show information about GENDB and used modules #
#################################################
sub show_about {

    my $about_win = new Gtk::Dialog;
    $about_win->set_title( "GENDB:: About" );
    $about_win->set_position('center');
    $about_win->set_modal(1);
    $about_win->realize;

    my $style = $about_win->get_style()->bg( 'normal' );
    my ( $pixmap, $mask ) = Gtk::Gdk::Pixmap->create_from_xpm( $about_win->window, $style, "$GENDB_INSTALL_DIR/share/splash.xpm" );
    # a pixmap widget to contain the pixmap
    my $pixmapwid = new Gtk::Pixmap( $pixmap, $mask );
    
    my $info_label = new Gtk::Label("GenDB\nRelease $RELEASE\nCenter for Genome Research\nBielefeld, Germany\nDecember, 2002");
    
    my $infobox = new Gtk::HBox( 0, 0 );
    
    $infobox->pack_start($info_label, 1, 1, 5);
    $infobox->pack_start($pixmapwid, 0, 1, 0);

    my @cols =  ("Information about used modules in GenDB:");
    my $list = new_with_titles Gtk::CList( @cols );
    $list->set_column_width(0, 200 );
    
    $list->freeze;
    my $module;
    my $perl_path = join "/",((split "/",$INC{'Exporter.pm'})[0..2]);
    print STDERR "perl path prefix: $perl_path\n";
    foreach $module (sort keys %INC) {
	next if ($INC{$module} =~ /$perl_path/);
	$module =~ s/\//::/g;
	$module =~ s/\.pm//;
	no strict 'refs';
	my $version = ${$module."::VERSION"};
        if ($version) {
	    $list->append(("$module, v. $version"));
	}
        else {
	    $list->append(("$module, no version"));
	};
    };
    $list->thaw;

    ### scrolled window for CList with contigs
    my $listscroller = new Gtk::ScrolledWindow;
    $listscroller->set_policy('automatic', 'automatic');
    $listscroller->add($list);    
    
    $about_win->vbox->pack_start($infobox, 0, 1, 0);
    $about_win->vbox->pack_start( new Gtk::HSeparator(), 0, 1, 3 );
    $about_win->vbox->pack_start($listscroller, 1, 1, 0);

    # Add a buttonbox with close button at the bottom 
    my $button_box = new Gtk::HButtonBox();
    my $close_button = new Gtk::Button("Close");
    $close_button->signal_connect('clicked', sub { 
	$about_win->destroy;
    } );

    $button_box->add($close_button);
    $about_win->action_area->add($button_box);

    $about_win->show_all;
};

sub search_orf {
    my ($self, $params_ref)=@_;
    $notebook->set_page(1);
    $genetree->{'search_widget'}->search_hash($params_ref);
};

# show selected (AA-)Sequence in TextWidget
sub make_baseview_selection_cb {
    my($bv) = @_;
    my($offset, $length) = (0, 0);
    my($start_mark, $stop_mark) = (-1, -1);
    my $strand = 0;
    my %text;
    my $dia = new Gtk::Dialog;
    my $b = new Gtk::Button('Close');
    $b->signal_connect('clicked', sub { $dia->hide } );
    $dia->signal_connect('delete_event', sub{ $dia->hide; return 1 } );
    $dia->action_area->pack_start($b, 0, 0, 3);
    $dia->set_default_size( 400, 400 );
    $dia->set_title('Sequence Exporter');    
    my $poslabel = new Gtk::Label;
    my $stoplabel = new Gtk::Label;
    my $hb = new Gtk::HButtonBox;
    $hb->set_layout('spread');
    $hb->pack_start_defaults($poslabel);
    $hb->pack_end_defaults($stoplabel);
    $dia->vbox->pack_start_defaults($hb);

    foreach(qw( Strand AntiStrand Frame1 Frame2 Frame3 Frame-1 Frame-2 Frame-3 )) {
	my $frame = new Gtk::Frame($_);
	my $scr = new Gtk::ScrolledWindow;
	$scr->set_policy('automatic', 'automatic');
	$text{$_} = new Gtk::Text;
	$scr->add($text{$_});
	$frame->add($scr);
	$dia->vbox->pack_start_defaults($frame);
    }
    
    $bv->canvas->signal_connect_after( 'button_press_event', sub{
	if( $_[1]->{'button'} == 1 ) {
	    my $spos = $bv->world_to_sequence( $_[1]->{'x'} );
	    my $epos = 1;
	   
	    if($_[1]->{'state'} != 4) {
		$start_mark = $spos; 
		$offset =  $spos;
	    } elsif( $_[1]->{'state'} == 4) {
		$start_mark = $offset;
		$epos = $spos - $start_mark;
		return if( $spos == $stop_mark );
		$stop_mark = $spos;
	    }
	    $bv->mark( $start_mark, $spos, $strand ) if( $epos > 0 );
	} elsif( $_[1]->{'button'} == 3 ) {
	    my $spos = $bv->world_to_sequence( $_[1]->{'x'} );
	    my $epos = 1;
	   
	    $start_mark = $offset;
	    $epos = $spos - $start_mark;
	    return if( $spos == $stop_mark );
	    $stop_mark = $spos;
	    $bv->mark( $start_mark, $spos, $strand ) if( $epos > 0 );
	} 
    });

    $bv->canvas->signal_connect_after( 'motion_notify_event', sub{
	if( $start_mark >= 0 ) {
	    my $spos = $bv->world_to_sequence( $_[1]->{'x'} );
	    my $epos = $spos - $start_mark;
	    return if( $spos == $stop_mark );
	    $stop_mark = $spos;
	    if( $epos > 0 ) {
		$bv->mark( $start_mark, $spos, $strand );
	    }
	}
	return 0;
    });
    
    $bv->canvas->signal_connect_after( 'button_release_event', sub{
	my $seq = $bv->get_marked_seq;
	if(!length($seq) || length($seq) > 5000) {
	    $start_mark = -1;
	    return;
	}
	my $rseq = reverse_complement($seq);
	my $frame = 3 - ($start_mark%3);
	$frame = 0 if( $frame == 3 );
	my $stop = $start_mark+length($seq);
	$poslabel->set_text("Start Position: $start_mark");
	$stoplabel->set_text("Stop Position: $stop");

	$text{'Strand'}->delete_text(0, -1);
	$text{'Strand'}->insert_text($seq, 0);

	$text{'AntiStrand'}->delete_text(0, -1);
	$text{'AntiStrand'}->insert_text($rseq, 0);

	foreach(qw( Frame1 Frame2 Frame3 )) {
	    $text{$_}->delete_text(0, -1);
	    $text{$_}->insert_text(translate(substr($seq, $frame, length $seq)), 0);
	    $frame++;$frame = 0 if( $frame == 3 );
	}

	my $frame = 3 - ($start_mark%3);
	$frame = 0 if( $frame == 3 );
	foreach(qw( Frame-1 Frame-2 Frame-3 )) {
	    $text{$_}->delete_text(0, -1);
	    $text{$_}->insert_text(translate(substr($rseq, $frame, length $seq)), 0);
	    $frame++;$frame = 0 if( $frame == 3 );
	}
	
	$dia->set_position('center');
	$dia->show_all;
	$start_mark = -1;
    });
};

