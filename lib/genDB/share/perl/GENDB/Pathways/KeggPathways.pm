package GENDB::Pathways::KeggPathways;

$VERSION = 1.7;

use GENDB::Config;
use GENDB::GENDB_CONFIG;
use GENDB::GUI::Utils;
use GENDB::GUI::ListWidget;
use GENDB::Tools::GODB;
use GENDB::orf;
use GD;
use POSIX;
use QuerySRS;

use vars qw(@ISA);

@ISA = qw(Gtk::HPaned);


# location of Kegg html Pathway files and PNG images:
my $data_adr = $GENDB_KEGG;

# compound database url
my $cpd_adr = "http://www.genome.ad.jp/dbget-bin/www_bget?compound+";

my %map_names=();

1;

##################################
# create new KeggPathways widget #
##################################
sub new {
    my ($class, $eclist_ref) = @_;
    my $self = $class->SUPER::new;

    my $in_ext_win=0;       
    my @unique_eclist=keys(%$eclist_ref);   

    #left for pathway tree and right for canvas with PathwayPNGs
    $self->set_position( 200 );
    $self->border_width( 5 );
    $self->gutter_size( 10 );

    #frame for pathway tree
    my $cframe = new Gtk::Frame( "Kegg Pathways" );

    #scrolled window for pathway tree
    my $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'automatic' );

    my $tree = new Gtk::CTree(1,0);
    $tree->set_expander_style("square");
    $tree->set_line_style("dotted");
    my $parent = $tree->insert_node(undef,undef,[$GENDB_PROJECT], 5, undef, undef, undef, undef, 0, 1);
    
    my $all_path_file=$data_adr."pathways.html";
    open(HTML, $all_path_file) || die "Couldn't open $all_path_file!\n";
	
    while (<HTML>) {
	if (/>path:(.*)<\/A>   (.*) - Standard metabolic pathway/) {
	    my $map=$1;
	    my $pn=$2;	
	    my $pathparent = $tree->insert_node( $parent,undef,[$pn], 5, undef, undef, undef, undef, 1, 0 );
	    $tree->node_set_row_data($pathparent, {'name' => $pn, 'map' => $map} );
	    $map_names{$map}=$pn;
	}
	else {
	    next;		    
	};
    };
    close HTML;   
    
    $tree->signal_connect( "button_press_event", \&visualize_kegg_pathway, $self  );
    $cframe->signal_connect( "motion_notify_event", sub { $cframe->grab_focus; } );
    $scroller->add( $tree );
    $cframe->add( $scroller );

    $tree->show;

    my $cscroller = new Gtk::ScrolledWindow;
    $cscroller->set_policy( 'automatic', 'automatic' );
    $cscroller->get_vadjustment->step_increment(10);
    $cscroller->get_hadjustment->step_increment(10);

    $self->add1( $cframe );    
    $self->add2( $cscroller );

    $self->{ 'canvas_parent' } = $cscroller;
    $self->{ 'keggtree' } = $tree;
    $self->{ 'unique_ecs' } = \@unique_eclist;
    $self->{ 'in_external_window' } = $in_ext_win;   
    
    bless $self;
    return $self;
};


###################
# get main widget #
###################
sub widget {
    my( $self ) = @_;

    return $self;
};


#######################
# set the progressbar #
#######################
sub set_progress {
    my( $self, $progress ) = @_;

    $self->{ 'progress' } = $progress;
};


################################
# visualize a selected pathway #
################################
sub visualize_kegg_pathway {
    my ($widget, $self, $event) = @_;

    my $data_ref;
    # button press in tree list on pathway name
    if ($event->{'type'} eq '2button_press') {
	if ($event->{'button'} == 1) {
	    my ($row, $column) = $widget->get_selection_info($event->{'x'}, $event->{'y'});
	    my $ctn = $widget->node_nth($row);
	    $data_ref=$widget->node_get_row_data($ctn);
	};
    }
    # or a pathway has been selected by clicking in the map
    elsif ($self->{'map_click'}) {
	$data_ref->{'map'}=$self->{'act_map'};
	$data_ref->{'name'}=$map_names{$self->{'act_map'}};
    };
    

    # visualize a pathway only if there's a legal data reference on pathway
    if (!$data_ref) {
	return 0;
    }
    else {
	my $pn=$data_ref->{'name'};
	my $map=$data_ref->{'map'};
	$self->{'map_click'}=undef;
	main->update_statusbar("Visualizing KEGG metabolic pathway $pn, map $map. Please wait ...");
	main->busy_cursor($self, 1);

	my $top=$self->{ 'canvas_parent' };	
	if ($top->children) {
	    my $child;
	    foreach $child ($top->children) {
		$child->destroy;
	    };
	};
	
	my $canvas = Gnome::Canvas->new() ;
	
	my $grp = new Gnome::CanvasItem( $canvas->root, 'Gnome::CanvasGroup', 
					 'x', 0, 'y', 0 );
	
	my $ecs_ref=$self->{ 'unique_ecs' };
	my ($img_file, $rects_ref, $circles_ref)=&colorize_map($map, $ecs_ref);
	my $img = Gtk::Gdk::ImlibImage->load_image($img_file) || die;
	my $imgwidth=$img->rgb_width;
	my $imgheight=$img->rgb_height;
	my $imgitem = Gnome::CanvasImage->new($grp,
					      "Gnome::CanvasImage",
					      'image' => $img,
					      'x' => $imgwidth/2,
					      'y' => $imgheight/2,
					      width => $img->rgb_width,
					      height => $img->rgb_height,
					      );
	# remove the image file immediately
	unlink $img_file;

	# create invisible rectangles for enzymes/pathway maps to make them clickable
	my @drawable_rects = @$rects_ref;
	foreach (@drawable_rects) {
	    my $subimgwidth = $_->{'x2'} - $_->{'x1'};
	    my $subimbheight = $_->{'y2'} - $_->{'y1'};
	    my $subimg = $img->crop_and_clone_image( $_->{'x1'}, $_->{'y1'}, $subimgwidth, $subimbheight );

	    my $subimgwidth=$subimg->rgb_width;
	    my $subimgheight=$subimg->rgb_height;
	    my $subimgitem = Gnome::CanvasImage->new($grp,
						     "Gnome::CanvasImage",
						     'image' => $subimg,
						     'x' => $_->{'x1'} + $subimgwidth/2,
						     'y' => $_->{'y1'} + $subimgheight/2,
						     width => $subimgwidth,
						     height => $subimbheight,
						     );     

	    $subimgitem->signal_connect( 'event', \&rect_event, $_, $self );
	};
	
	# draw filled circles for compounds to make them clickable
	my @drawable_circles = @$circles_ref;
	foreach (@drawable_circles) {
	    my $x = $_->{'x'} - $_->{'rad'};
	    my $y = $_->{'y'} - $_->{'rad'};
	    my $subimgwidth = 2 * ($_->{'rad'});
	    my $subimbheight = 2 * ($_->{'rad'});
	    my $subimg = $img->crop_and_clone_image( $x, $y, $subimgwidth, $subimbheight );
	    
	    my $subimgwidth=$subimg->rgb_width;
	    my $subimgheight=$subimg->rgb_height;
	    my $subimgitem = Gnome::CanvasImage->new($grp,
						     "Gnome::CanvasImage",
						     'image' => $subimg,
						     'x' => $x + $subimgwidth/2,
						     'y' => $y + $subimgheight/2,
						     width => $subimgwidth,
						     height => $subimbheight,
						     );     
	    
	    $subimgitem->signal_connect( 'event', \&circle_event, $_->{'cpd'}, $self );     
	};
	
	$canvas->set_scroll_region(0,0,$imgwidth,$imgheight);
	
	$canvas->show;	
	$top->add($canvas);
	$top->show_all;
	
	while (Gtk->events_pending) {
	    Gtk->main_iteration;
	};
	
	main->update_statusbar("Visualizing KEGG metabolic pathway $pn. Please wait ... Done.");
	main->busy_cursor($self, 0);
    };
};


#################################################
# Create the pathway map with tinted EC numbers #
#################################################
sub colorize_map {
    my ($pm, $ecs_ref) = @_;

    my $path;
    my @allECs=@$ecs_ref;
    my @rects=();
    my @circles=();

    ###################################################################
    # create new png for pathway on the fly to be displayed in canvas #
    ###################################################################
 
    my $img_file=$data_adr."Pathway_htmls/Pathway_pngs/$pm.png";
    open(PNG, $img_file) || die "Couldn't open $img_file!\n";
    my $im=newFromPng GD::Image(PNG) || die "Couldn't create image from $img_file!\n";
    
    $im->colorDeallocate($im->colorExact(1,1,1));
    
    my $white=$im->colorAllocate(255,255,255);
    my $fill_color=$im->colorAllocate(255,255,130);
    
    my $htmlfile=$data_adr."Pathway_htmls/".$pm.".html";
    open(HTML, "$htmlfile") || die "Couldn't open $htmlfile!\n";

    # parsing HTML page for compounds and enzymes
    while (<HTML>) {
	my $actrect=undef;
	my $actcircle=undef;
	if (/<b>(.+) - Reference pathway<\/b>/) {
	    $path=$1;
	}
	elsif (/<b>(.+) - Standard metabolic pathway<\/b>/) {
	    $path=$1;
	}
	elsif (/coords=(\d+),(\d+),(\d+),(\d+)\s+.+\?enzyme\+(.+)\"\s+onMouseOver/) { 
	    $actrect->{'x1'}=$1;
	    $actrect->{'y1'}=$2;
	    $actrect->{'x2'}=$3;
	    $actrect->{'y2'}=$4;
	    $actrect->{'ec'}=$5;
	    my $x=$1+2;
	    my $y=$2+2;
	    foreach (@allECs) {
		if ($_ eq $5) {
		    $im->fill($x,$y,$fill_color);
		    $actrect->{'annotated'}=1;
		    last;
		};
	    };
	}
	elsif (/coords=(\d+),(\d+),(\d+),(\d+)\s+.+EC\&keywords=(.+)\"\s+onMouseOver/) {
	    $actrect->{'x1'}=$1;
	    $actrect->{'y1'}=$2;
	    $actrect->{'x2'}=$3;
	    $actrect->{'y2'}=$4;
	    $actrect->{'ec'}=$5;
	    my $x=$1+2;
	    my $y=$2+2;
	    foreach (@allECs) {
		if ($_ eq $5) {
		    $im->fill($x,$y,$fill_color);
		    $actrect->{'annotated'}=1;
		    last;
		};
	    };
	}
	elsif (/coords=(\d+),(\d+),(\d+),(\d+)\s+.+\?enzyme\+(.+)\">/) {
	    $actrect->{'x1'}=$1;
	    $actrect->{'y1'}=$2;
	    $actrect->{'x2'}=$3;
	    $actrect->{'y2'}=$4;
	    $actrect->{'ec'}=$5;
	    my $x=$1+2;
	    my $y=$2+2;
	    foreach (@allECs) {
		if ($_ eq $5) {
		    $im->fill($x,$y,$fill_color);
		    $actrect->{'annotated'}=1;
		    last;
		};
	    };
	}
	elsif (/coords=(\d+),(\d+),(\d+),(\d+)\s+.+EC\&keywords=(.+)\">/) {
	    $actrect->{'x1'}=$1;
	    $actrect->{'y1'}=$2;
	    $actrect->{'x2'}=$3;
	    $actrect->{'y2'}=$4;
	    $actrect->{'ec'}=$5;
	    my $x=$1+2;
	    my $y=$2+2;
	    foreach (@allECs) {
		if ($_ eq $5) {
		    $im->fill($x,$y,$fill_color);
		    $actrect->{'annotated'}=1;
		    last;
		};
	    };
	}
	elsif (/coords=(\d+),(\d+),(\d+),(\d+)\s+.+map\/(.+)\.html\"\s+onMouseOver.+/) {
	    $actrect->{'x1'}=$1;
	    $actrect->{'y1'}=$2;
	    $actrect->{'x2'}=$3;
	    $actrect->{'y2'}=$4;
	    $actrect->{'map'}=$5;
	}
	elsif (/coords=(\d+),(\d+),(\d+)\s+.+\?compound\+(.+)\"\s+onMouseOver.+/) {
	    $actcircle->{'x'}=$1;
	    $actcircle->{'y'}=$2;
	    $actcircle->{'rad'}=$3;
	    $actcircle->{'cpd'}=$4;
	}
	else {
	    next;
	};

	if (defined $actrect) {   
	    push(@rects,$actrect);
	};
	if (defined $actcircle) {
	    push(@circles, $actcircle);
	};
    };
    
    close HTML;
    close PNG;
 
    #create temporary file prefix
    my $tmpname=POSIX::tmpnam();
    $tmpname=~/(.*)\/(.*)/;
    my $tmpfh=$2;
    my $tmp_png_fh=$1."/".$pm.$tmpfh;

    my $png_data=$im->png;
    open(DISPLAY, "> $tmp_png_fh.png");
    binmode DISPLAY;
    print DISPLAY $png_data;
    close DISPLAY;    
   
    return("$tmp_png_fh.png",\@rects, \@circles);
};


#####################################################################################
# Callback at rectangular regions to visualize another pathway or show ENZYME entry #
#####################################################################################
sub rect_event {
    my( $widget, $rect, $self, $event ) = @_;
    
    my $top=$self->{ 'canvas_parent' };
    my $gwin=$top->get_parent_window;
    if ($event->{'type'} eq '2button_press') {
	if ($event->{'button'} == 1) {		
	    if (defined $rect->{'map'}) {
		$self->{'map_click'}=1;
		$self->{'act_map'}=$rect->{'map'};
		&visualize_kegg_pathway($widget, $self);
	    }
	    else {
		my $ec=$rect->{'ec'};
		if ($GENDB_SRS) {
		    main->update_statusbar("Searching ENZYME database for: $ec. Please wait ...");
		    main->busy_cursor($self, 1);
		  Utils::open_url(QuerySRS::get_entry_URL('enzyme',$ec));
		    main->update_statusbar("Searching ENZYME database for: $ec. Please wait ... Done.");
		    main->busy_cursor($self, 0);
		}
		else {
		    Utils::show_error("Unable to look up ENZYME database, no SRS server configured.");
		}
	    };
	};
    }
    elsif ($event->{'type'} eq 'button_press') {
	if ($event->{'button'} == 3) {
	    if ($rect->{'annotated'} == 1) {
		# Construct a GtkMenu ''
		my $enzyme_menu = new Gtk::Menu;    
		$enzyme_menu->border_width(1);
		
		# Construct a GtkMenuItem 'show_annotated_orf'
		my $show_orf_item = new_with_label Gtk::MenuItem("Show ORF");
		$enzyme_menu->append($show_orf_item);
		$show_orf_item->show;
		
		# Connect all signals now 
		$show_orf_item->signal_connect( 'activate', \&show_orfs_with_ecs, $self, $rect->{'ec'});
		
		$enzyme_menu->popup(undef,undef,1,$event->{'time'},undef);
	    }
	};
    }
    elsif ($event->{'type'} eq 'enter_notify') {
	my $on_link_cursor = Gtk::Gdk::Cursor->new(60);
	$gwin->set_cursor($on_link_cursor);
	Gtk->main_iteration while ( Gtk->events_pending );
    }
    elsif ($event->{'type'} eq 'leave_notify') {
	my $normal_cursor = Gtk::Gdk::Cursor->new(68);
	$gwin->set_cursor($normal_cursor);
	Gtk->main_iteration while ( Gtk->events_pending );
    };	   
};


################################################################
# Callback to open browser at double click on entered compound #
################################################################
sub circle_event {
    my( $item, $cpd, $self, $event ) = @_;
    
    my $top=$self->{ 'canvas_parent' };
    my $gwin=$top->get_parent_window;
    if ($event->{'type'} eq '2button_press') {
        if ($event->{'button'} == 1) {
	   my $url = $cpd_adr.$cpd;
	   main->update_statusbar("Searching COMPOUND database for: $cpd. Please wait ...");
	   main->busy_cursor($self, 1);
	 Utils::open_url( $url );
	   main->update_statusbar("Searching COMPOUND database for: $cpd. Please wait ... Done.");
	   main->busy_cursor($self, 0);
       };
    }
    elsif ($event->{'type'} eq 'enter_notify') {
	my $on_link_cursor = Gtk::Gdk::Cursor->new(60);
	$gwin->set_cursor($on_link_cursor);
	Gtk->main_iteration while ( Gtk->events_pending );
    }
    elsif ($event->{'type'} eq 'leave_notify') {
	my $normal_cursor = Gtk::Gdk::Cursor->new(68);
	$gwin->set_cursor($normal_cursor);
	Gtk->main_iteration while ( Gtk->events_pending );
    };
};


###########################################
# show ORFs of selected EC in geneviewer  #
###########################################
sub show_orfs_with_ecs {
    my ($widget, $self, $ec) = @_;
    
    if (!$self->{'in_external_window'}) {
	main->to_window($self, "KEGG Pathways", 3, 1);
    };
    
    # display selected orf in geneviewer
    my %searchparams=( 'orf_ec' => $ec );
    
    main->search_orf(\%searchparams);
};
