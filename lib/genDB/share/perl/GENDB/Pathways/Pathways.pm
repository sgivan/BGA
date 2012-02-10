package GENDB::Pathways::Pathways;

$VERSION = 1.13;

use strict;
use GENDB::GENDB_CONFIG;
use GENDB::Pathways::PathView;
use GENDB::Pathways::SubwayView;
use GENDB::Pathways::getChunks;
use GENDB::Pathways::DBInterface;
use GENDB::Config;
use GENDB::annotation;
use GENDB::contig;
use GENDB::orf;

use pathwayDB::pathway_sub_paths;

use vars qw(@ISA);

@ISA = qw(Gtk::HPaned);

my $vcg_path = $GENDB_XVCG;

sub new {
    my ($class, $ec_hash_ref, $orfecs_ref) = @_;
    my $self = $class->SUPER::new;

    #########################################################################
    #########################################################################
    ### !!! Fehler in GenDB bei Berechnung der annotierten EC Nummern !!! ###
    #########################################################################
    #########################################################################
    my $in_ext_win=0;

    my %unique_ecs_hash=%$ec_hash_ref;
    my @unique_eclist=keys(%unique_ecs_hash);
    my $totalECNum=@unique_eclist;
    main->update_statusbar("Found $totalECNum different annotated EC numbers!");

    #left for pathway tree and right for canvas and clist
    my $vpaned = new Gtk::VPaned;
    $vpaned->set_position( 300 );
    $vpaned->border_width( 5 );
    $vpaned->gutter_size( 10 );

    #upper for canvas and lower for clist
    $self->set_position( 200 );
    $self->border_width( 5 );
    $self->gutter_size( 10 );

    my @cols =  ( 'Pathways with detected EC numbers', 
		  '#EC numbers', 
		  '#detected EC numbers', 
		  'Score');

    my $list = new_with_titles Gtk::CList( @cols );
    $list->set_column_width(0, 400 );
    $list->set_column_width(1, 130 );
    $list->set_column_width(2, 130 );
    $list->set_column_width(3, 50 );
    $list->set_auto_sort( 1 );

    #frame for pathway tree
    my $cframe = new Gtk::Frame( "Pathways" );

    #scrolled window for pathway tree
    my $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'always' );

    my $tree = new Gtk::CTree(1,0);
    $tree->set_expander_style("square");
    $tree->set_line_style("dotted");
    my $parent = $tree->insert_node(undef,undef,[$GENDB_PROJECT], 5,undef, undef, undef, undef, 0, 1);
    $tree->node_set_row_data($parent,{'root' => $GENDB_PROJECT});

    my $all_pathways_ref=pathwayDB::pathway->fetchall;
    my @all_pathways=@$all_pathways_ref;
    
    my %kPathway_vFoundECs=();

    my $path;
    foreach $path (@all_pathways) {	
	my $pathparent = $tree->insert_node( $parent,undef,[$path->pathway_name], 5, undef, undef, undef, undef, 0, 0 );
	my $pn=$path->pathway_name;
	$tree->node_set_row_data($pathparent, {'name' => $pn} );

	my $i=0;
	my @pathECs = GENDB::Pathways::DBInterface::getAllPathECs($path->pathway_name);
	my $ecNum=@pathECs; 
	
	my $path_ecs_string="";
	my ($ecnr, $pathEC);
	foreach $pathEC (@pathECs) {
	    if ($unique_ecs_hash{$pathEC}) {
		$i++;
		$kPathway_vFoundECs{$pn}{$pathEC} = 1;		
		$path_ecs_string.=$unique_ecs_hash{$pathEC};
	    };
	};
	my $perc = ($i/$ecNum)*100+0.5;
	my $percent = int $perc;
	
	my $s1="#ECs: ".$ecNum;
	my $leaf1 = $tree->insert_node( $pathparent,undef,[$s1], 5, undef, undef, undef, undef, 1, 0 );
	my $s2="#detected ECs: ".$i;
	my $leaf2 = $tree->insert_node( $pathparent,undef,[$s2], 5, undef, undef, undef, undef, 1, 0 );
	my $s3="Score: ".$percent." %";
	my $leaf3 = $tree->insert_node( $pathparent,undef,[$s3], 5, undef, undef, undef, undef, 1, 0 );

	# Fill CList 
	$list->freeze;
	if ($i > 0) {
	    $list->append( ( $pn,
			     $ecNum,
			     $i,
			     $percent."%") );	
	};
	$list->thaw;

    };
    
    ### ScrolledWindow for CList with Pathway information
    my $listscroller = new Gtk::ScrolledWindow;
    $listscroller->add( $list );
    $list->signal_connect( 'click_column', \&sortlist );
    

    $tree->signal_connect( "button_press_event", \&show_pathway_popup, $self  );
    $scroller->add( $tree );
    $tree->show;

    
    my $cscroller = new Gtk::ScrolledWindow;
    $cscroller->set_policy( 'automatic', 'always' );
    $cscroller->get_vadjustment->step_increment(10);
    $cscroller->get_hadjustment->step_increment(10);

    my $cbox = new Gtk::VBox( 0, 0 );
    $cbox->pack_start( $cscroller, 1, 1, 1 );


    $cframe->add( $scroller );
    $self->add1( $cframe );
    $vpaned->add1( $cbox );
    
    $self->add2( $vpaned );
    
    # ScrolledWindow for a clist with annotated ECs for each pathway
    my $orf_ec_scroller = new Gtk::ScrolledWindow;
    my $eclist = new_with_titles Gtk::CList(( 'ORF_id', 'ORF name',"annotated EC numbers"));
    $orf_ec_scroller->add( $eclist );
    $eclist->set_column_visibility(0,0);
    $eclist->set_column_width(1, 300 );
    $eclist->set_column_width(2, 300 );
    $eclist->set_auto_sort( 1 );
    $eclist->signal_connect( 'click_column', \&sortlist );
    $eclist->signal_connect( 'select_row', \&eclistrow_selected, $self );
  
    # ScrolledWindow for a clist with subways for each pathway
    my $subway_scroller = new Gtk::ScrolledWindow;
    my @cols =  ("Subway", "is valid subway", "valid chunks", "invalid chunks");
    my $subwaylist = new_with_titles Gtk::CList( @cols );
    $subway_scroller->add($subwaylist);
    $subwaylist->set_column_width(0, 100 );
    $subwaylist->set_column_width(1, 100 );
    $subwaylist->set_column_width(2, 300);
    $subwaylist->set_column_width(3, 300);
    $subwaylist->set_auto_sort( 1 );
    $subwaylist->signal_connect( 'click_column', \&sortlist );


    # put all different list types into separate notebook pages #
    my $notebook = new Gtk::Notebook;
    $notebook->set_show_border( 0 );
    $notebook->set_show_tabs( 0 );
    $notebook->append_page( $listscroller );
    $notebook->append_page( $orf_ec_scroller );
    $notebook->append_page( $subway_scroller );
    $vpaned->add2( $notebook );

    $self->{ 'notebook' } = $notebook;
    $self->{ 'list_parent' } = $listscroller;
    $self->{ 'canvas_parent' } = $cscroller;
    $self->{ 'canvas_p_p' } = $cbox;
    $self->{ 'tree' } = $tree;
    $self->{ 'eclist' } = $eclist;
    $self->{ 'list' } = $list;
    $self->{ 'sublist' } = $subwaylist;
    $self->{ 'unique_ecs' } = \@unique_eclist;
    $self->{ 'unique_ec_hash' } = \%unique_ecs_hash;
    $self->{ 'pathway_ecs' } = \%kPathway_vFoundECs;
    $self->{ 'orf_ecs_hash' } = $orfecs_ref;
    $self->{ 'in_external_window' } = $in_ext_win;
  
    bless $self;
    return $self;
};


# return the main widget
sub widget {
    my( $self ) = @_;

    return $self;
};


# set progressbar to get used by this widget
sub set_progress {
    my( $self, $progress ) = @_;

    $self->{ 'progress' } = $progress;
};


# toggle sort type between ascending and descending order
sub sortlist {
    my( $list, $col, $self ) = @_;    $list->set_sort_column( $col );
    $list->set_compare_func( \&sort_func );
    $list->sort;
    if ($list->sort_type eq 'ascending') { 
	$list->set_sort_type( 'descending' ); 
    }
    else { 
	$list->set_sort_type( 'ascending' ); 
    };
};


# use this function for sorting the elements in a column
sub sort_func {
    my( $list, $a, $b, $col ) = @_;

    return ( $a <=> $b or $a cmp $b );
};


# Callback for popup menu at Pathway Tree
sub show_pathway_popup {
    my ( $widget, $self, $event ) = @_;
    
    if ($event->{'type'} eq 'button_press') {
	if ($event->{'button'} == 3) {
	    my ($row, $column) = $widget->get_selection_info($event->{'x'}, $event->{'y'});
	    $widget->select_row( $row, $column );
	    my $ctn = $widget->node_nth($row);
	    my $data_ref=$widget->node_get_row_data($ctn);
	    if (!$data_ref) {
		return 0;
	    } 
	    elsif ($data_ref->{'root'}) {
		# Construct a GtkMenu 'root_menu'
		my $root_menu = new Gtk::Menu;
		$root_menu->border_width(1);
		
		# Construct a GtkMenuItem 'show_pathways_with_annotated_ecs'
		my $pathways_with_ecs = new_with_label Gtk::MenuItem("Show pathways with annotated ECs");
		$root_menu->append($pathways_with_ecs);
		$pathways_with_ecs->show;
		
		# Connect all signals now 
		$pathways_with_ecs->signal_connect( 'activate', \&show_pathways_with_ecs, $self );
		
		$root_menu->popup(undef,undef,1,$event->{'time'},undef);
	    } 
	    else {
		my $pathname=$data_ref->{'name'};
		# Construct a GtkMenu 'pathway_menu'
		my $pathway_menu = new Gtk::Menu;    
		$pathway_menu->border_width(1);
		
		# Construct a GtkMenuItem 'display_pathway'
		my $display_pathway = new_with_label Gtk::MenuItem("Display pathway");
		$pathway_menu->append($display_pathway);
		if (defined $GENDB_XVCG) {
		    $display_pathway->show;
		};

		# Construct a GtkMenuItem 'analyze subways'
		my $analyze_subways = new_with_label Gtk::MenuItem("Analyze subways");
		$pathway_menu->append($analyze_subways);
		$analyze_subways->show;
		
		# Construct a GtkMenuItem 'show ECs'
		my $show_ecs = new_with_label Gtk::MenuItem("Show ORFs with annotated ECs");
		$pathway_menu->append($show_ecs);
		$show_ecs->show;
		
		# Connect all signals now 
		$display_pathway->signal_connect( 'activate', \&visualize_pathway, $pathname, $self );
		$show_ecs->signal_connect( 'activate', \&show_orfs_with_ecs, $pathname, $self );
		$analyze_subways->signal_connect( 'activate', \&choose_ext_nodes_dialog, $pathname, $self );
		
		$pathway_menu->popup(undef,undef,1,$event->{'time'},undef); # or use $event->{'button'}
	    };
	};
    };    
};



sub visualize_pathway {
    my ($widget, $pn, $self) = @_;

    main->update_statusbar("Visualizing metabolic pathway $pn. Please wait ...");
    main->busy_cursor($self, 1);
    my $use_xvcg=0;
    my $fac=160;

    my $progressbar=$self->{'progress'};
    $progressbar->set_show_text(1);
    $progressbar->set_adjustment( new Gtk::Adjustment( 0, 1, 100, 0, 0, 0 ) );

    my $top=$self->{ 'canvas_parent' };
    my $identified_pathECs_hashref=$self->{'pathway_ecs'};
    my %identified_pathECs_hash=%$identified_pathECs_hashref;
    my $fh = GENDB::Pathways::PathView::createVCG_file($pn, \%{$identified_pathECs_hash{$pn}}, $fac, \$progressbar);
    
    if ($use_xvcg == 0) {
    
	system("$vcg_path -ppmoutput $fh.ppm -silent -xdpi $fac -ydpi $fac $fh.vcg");

	if ($top->children) {
	    my $child;
	    foreach $child ($top->children) {
		$child->destroy;
	    };
	};
	
	my $canvas = Gnome::Canvas->new() ;

	my $img = Gtk::Gdk::ImlibImage->load_image("$fh.ppm") || die;
	my $imgitem = Gnome::CanvasImage->new($canvas->root,
					      "Gnome::CanvasImage",
					      'image' => $img,
					      'x' => 0,
					      'y' => 0,
					      width => $img->rgb_width,
					      height => $img->rgb_height,
					      );

	my $imgwidth=$img->rgb_width;
	my $imgheight=$img->rgb_height;

	$canvas->set_scroll_region(-$imgwidth/2,-$imgheight/2,$imgwidth/2,$imgheight/2);

	$canvas->show;	
	$top->add($canvas);
	$top->show;

	$progressbar->set_value(100);
	while (Gtk->events_pending) {
	    Gtk->main_iteration;
	};
	
	main->update_statusbar("Visualizing metabolic pathway $pn. Please wait ... Done.");
	main->busy_cursor($self, 0);
	$progressbar->set_value( 0 );
	$progressbar->set_show_text( 0 );
    }
    else {
	system("$vcg_path -silent $fh.vcg&");
    };
};


#########################################
# show ORFs with annotated ECs in CList #
#########################################
sub show_orfs_with_ecs {
    my ($widget, $pn, $self) = @_;

    my $orf_ecs_ref=$self->{'orf_ecs_hash'};
    my %orf_ecs=%$orf_ecs_ref;

    my $eclist = $self->{'eclist'};
    $eclist->freeze;
    $eclist->set_column_title( 2, "annotated EC numbers in $pn" );
    $eclist->clear;

    # fill eclist
    my @pathECs = GENDB::Pathways::DBInterface::getAllPathECs($pn);
    my $e;
    foreach $e (@pathECs) {
	my $orfnames=$orf_ecs{$e};
	chop($orfnames);
	my @orfs=split(",",$orfnames);
	foreach (@orfs) {
	    my $annotation = GENDB::annotation->init_id($_);
	    $eclist->append( ($annotation->orf_id, $annotation->name, $e) );
	};    
    };
    $self->{'notebook'}->set_page( 1 );    
    $eclist->thaw;

};


######################################
# show selected ORF in contigviewer  #
######################################
sub eclistrow_selected {
    my ($widget, $self, $row, $col, $event) = @_;
    
    if ($event->{'type'} eq '2button_press') {
	if ($event->{'button'} == 1) {
	    if (!$self->{'in_external_window'}) {
		main->to_window($self, "Pathways", 2);
		$self->{'in_external_window'}=1;
	    };
	    my $orf_id=$widget->get_text($row, 0);
	    # display selected orf in contigview
	    main->show_orf($orf_id);
	};
    };
};


#############################################
# show CList of pathways with annotated ECs #
#############################################
sub show_pathways_with_ecs {
    my ($widget, $self)=@_;
    
    $self->{'notebook'}->set_page(0);
};


##############################################
# popup dialog to choose two external nodes  #
##############################################
sub choose_ext_nodes_dialog {
    my ($widget, $pn, $self) = @_;
    
    my $dialog = new Gtk::Dialog;
    $dialog->title("Choose external nodes:");
    $dialog->set_modal(1);
    $dialog->set_position('mouse');

    my $frame = new Gtk::Frame("Choose 2 DIFFERENT external nodes from $pn:");
    $frame->border_width(8);
    $frame->set_label_align(0.01, 0); 

    my $selection_box = new Gtk::VButtonBox();
    $selection_box->set_layout_default('spread');
    $selection_box->border_width(5);
    my $optionmenuA = new Gtk::OptionMenu();
    my $optionmenuB = new Gtk::OptionMenu();

    ### create two option menus with all external node names for a selected pathway
    my $ext_nodes_menuA = new Gtk::Menu();
    my $ext_nodes_menuB = new Gtk::Menu();
    my $path_obj=pathwayDB::pathway->init_pathway_name($pn);
    my $p_id=$path_obj->id;
    
    my %ext_nodes=pathwayDB::pathway_nodes->fetchall_ext_nodes($p_id);
    my %rev_ext_nodes=();
    my ($key, $value)=();
    while (($key,$value)=each %ext_nodes) {
	$rev_ext_nodes{$value}=$key;
        my $itemA = new Gtk::MenuItem($value);
	$ext_nodes_menuA->append($itemA);
	$itemA->show;
	my $itemB = new Gtk::MenuItem($value);
	$ext_nodes_menuB->append($itemB);
	$itemB->show;
    };

    $optionmenuA->set_menu($ext_nodes_menuA);
    $optionmenuB->set_menu($ext_nodes_menuB);
    $optionmenuB->set_history(1);
    $selection_box->add($optionmenuA);
    $selection_box->add($optionmenuB);
    $frame->add($selection_box);
    
    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("Show Subways");
    $ok_button->signal_connect( 'clicked', sub { my $n1=$optionmenuA->label();
						 my $n2=$optionmenuB->label();
						 if ($n1 ne $n2) {
						     my $n1_id=$rev_ext_nodes{$n1};
						     my $n2_id=$rev_ext_nodes{$n2};
						     $dialog->destroy;
						     Gtk->main_iteration while ( Gtk->events_pending );
						     &show_subways($widget, $n1, $n1_id, $n2, $n2_id, $pn, ,$p_id, $self);
						 }
						 else {
						    main->update_statusbar("ERROR: Please select TWO DIFFERENT NODES!"); 
						 };
					     } );
				
    my $cancel_button = new Gtk::Button("Cancel");
    $cancel_button->signal_connect( 'clicked', sub { $dialog->destroy; } );

    $button_box->add($ok_button);
    $button_box->add($cancel_button);

    $dialog->vbox->add($frame);
    $dialog->action_area->add($button_box);   
    
    $dialog->show_all;
};


##############################################
# show Subways for selected Pathway in CList #
##############################################
sub show_subways {
    my ($widget, $ext_node_A, $nodeA_id, $ext_node_B, $nodeB_id, $pn, $p_id, $self) = @_;
    
    my $threshval=50;

    my $progressbar=$self->{'progress'};
    $progressbar->set_show_text(1);
    $progressbar->set_adjustment( new Gtk::Adjustment( 0, 0, 100, 0, 0, 0 ) );
    main->update_statusbar("Analyzing subways from $ext_node_A to $ext_node_B. Please wait...");
    main->busy_cursor($self, 1);
        
    my $subwaylist = $self->{'sublist'};
    $subwaylist->clear;

    if (defined $GENDB_XVCG) {
	$subwaylist->signal_connect( 'select_row', \&subwaylistrow_selected, $p_id, $pn, $self);
    };

    # Fetch chunks and fill Listboxes    
    my $identified_pathECs_hashref=$self->{'pathway_ecs'};
    my %identified_pathECs_hash=%$identified_pathECs_hashref;
    $progressbar->set_value(1);
    Gtk->main_iteration while ( Gtk->events_pending );
    my $chk_s_t_ref = GENDB::Pathways::getChunks::get_chunks($p_id, $pn, \%{$identified_pathECs_hash{$pn}}, \$progressbar);
    my %chk_score_tab=%$chk_s_t_ref;
    my %no_hit_subpath_tab=();
    
    $progressbar->set_value(90);
    while (Gtk->events_pending) {
	Gtk->main_iteration;
    };
	   
    my $selected_paths_ref=pathwayDB::pathway_sub_paths->get_selected_sub_paths($p_id,$nodeA_id,$nodeB_id);
    my @sel_paths=@$selected_paths_ref;
    
    $progressbar->set_value(100);
    while (Gtk->events_pending) {
	Gtk->main_iteration;
    };
	
    my $iv_chks=();
    my @path_nums=();
    my $sub_path_chk_str="";
    my @sw_rows = ();
    my @nsw_rows = ();

    # fill subwaylist
    $subwaylist->freeze;
    my $pth;
    foreach $pth (@sel_paths) {
	my $p_num=$pth->p_number;
	my $p_src=$pth->p_source;
	my $p_tar=$pth->p_target;
        my $p_chks=$pth->chunk_string;
	
	$sub_path_chk_str.=$p_num.':'.$p_chks.'%';
	push(@path_nums,$p_num);
	my $valid_chks="";
	my $invalid_chks="";
	my @p_chks=split(',',$p_chks);
	my $p_c;
	foreach $p_c (@p_chks) {
	    my $c_score=$chk_score_tab{$p_c};
	    if ($c_score >= $threshval) {
		$valid_chks.=$p_c.',';
	    }
	    else {
		$invalid_chks.=$p_c.',';
		$iv_chks.='I'.$p_c.',';
	    };
	};
	
    	if ($invalid_chks) { #$p_score==1
	    chop($invalid_chks);
	    chop($valid_chks);
	    $subwaylist->append( ($p_num, 0, $valid_chks, $invalid_chks) );
	}
	else {
	    $subwaylist->append( ($p_num, 1, $p_chks, "") );
	};
    };
    
    $subwaylist->thaw;
    $self->{'notebook'}->set_page(2);
    main->update_statusbar("Analyzing subways from $ext_node_A to $ext_node_B. Please wait... Done.");
    main->busy_cursor($self, 0);
    $progressbar->set_value( 0 );
    $progressbar->set_show_text( 0 );
};


###################################################
# display pathway and visualize a selected subway #
###################################################
sub subwaylistrow_selected {
    my ($widget, $p_id, $pn, $self, $row, $col, $event)=@_;

    if ($event->{'type'} eq '2button_press') {
	if ($event->{'button'} == 1) {	    
	    my $sub_path_nr=$widget->get_text($row, 0);
	    my $sub_path_chks=$widget->get_text($row, 2);
	    my $iv_sub_path_chks=$widget->get_text($row, 3);
	    main->update_statusbar("Visualizing subway in metabolic pathway $pn. Please wait ...");
	    my $use_xvcg=0;
	    my $fac=160;
	    
	    my $progressbar=$self->{'progress'};
	    $progressbar->set_show_text(1);
	    $progressbar->set_adjustment( new Gtk::Adjustment( 0, 0, 100, 0, 0, 0 ) );
	    
	    my $top=$self->{ 'canvas_parent' };
	    my $cursor = Gtk::Gdk::Cursor->new(150);
	    my $gwin=$top->get_parent_window;
	    $gwin->set_cursor($cursor);
	    $progressbar->set_value(1);
	    Gtk->main_iteration while ( Gtk->events_pending );
	    
	    my $identified_pathECs_hashref=$self->{'pathway_ecs'};
	    my %identified_pathECs_hash=%$identified_pathECs_hashref;

	    my $fh = GENDB::Pathways::SubwayView::viewSubway($p_id, $pn, \%{$identified_pathECs_hash{$pn}}, $sub_path_nr, 
					  $sub_path_chks, $iv_sub_path_chks, $fac, \$progressbar);
	    	    
	    $progressbar->set_value(90);
	    Gtk->main_iteration while ( Gtk->events_pending );
	    if ($use_xvcg == 0) {
				
		if ($top->children) {
		    my $child;
		    foreach $child ($top->children) {
			$child->destroy;
		    };
		};
		
		my $canvas = Gnome::Canvas->new() ;
		
		my $img = Gtk::Gdk::ImlibImage->load_image("$fh.ppm") || die;
		my $imgitem = Gnome::CanvasImage->new($canvas->root,
						      "Gnome::CanvasImage",
						      'image' => $img,
						      'x' => 0,
						      'y' => 0,
						      width => $img->rgb_width,
						      height => $img->rgb_height,
						      );
		
		my $imgwidth=$img->rgb_width;
		my $imgheight=$img->rgb_height;
		
		$canvas->set_scroll_region(-$imgwidth/2,-$imgheight/2,$imgwidth/2,$imgheight/2);
		
		$canvas->show;	
		$top->add($canvas);
		$top->show;
		
		$progressbar->set_value(100);
		while (Gtk->events_pending) {
		    Gtk->main_iteration;
		};
		
		my $normal_cursor = Gtk::Gdk::Cursor->new(68);
		$gwin->set_cursor($normal_cursor);
		$cursor=undef;
		main->update_statusbar("Visualizing subway in metabolic pathway $pn. Please wait ... Done.");
		$progressbar->set_value( 0 );
		$progressbar->set_show_text( 0 );
	    }
	    else {
		system("$vcg_path -silent $fh.vcg&");
	    };
	};
    };	    
};


1;
