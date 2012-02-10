package FactView;

($GENDB::GUI::FactView::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use vars( qw(@ISA) );
use strict;
use GENDB::GUI::AnnotationEditor;
use GENDB::contig;
use GENDB::orf;
use GENDB::tool;
use GENDB::Tools::UserConfig;
use GENDB::fact;
use GENDB::GUI::GenDBWidget;

use GENDB::GENDB_CONFIG;

@ISA = qw(Gtk::Dialog);

my $last_search = 'NOTHING';

###################################################
###                                             ###
### Dialog showing all facts for a specific ORF ###
###                                             ###
###################################################

sub new {
    my( $class, $orf, $pr) = @_;
    my $self = $class->SUPER::new;
    bless $self, $class;

    my $vbox = new GenDBWidget;
    $vbox->set_progress($pr);
    $self->{'widget'} = $vbox;

    my $canvas = &make_canvas( $orf, $self );


    my $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'automatic' );
    $scroller->add( $canvas );
    $scroller->get_vadjustment->step_increment(10);
    $scroller->get_hadjustment->step_increment(10);

    $vbox->pack_start_defaults( $scroller );
    $self->set_title( "Facts for ORF ".$orf->name );
    $self->set_usize( 875, 400 );
    $self->signal_connect( 'destroy', sub{ $self->destroy } );

    for( my $i = 1; $i < 6; $i++ ) {
	my $ebox = new Gtk::EventBox;
	my $label = new Gtk::Label( "  Level $i hit " );
	$ebox->add( $label );
	$ebox->show;
	$label->show;
    
	my $style = new Gtk::Style;
	$style->bg( 'normal', 
		  Gtk::Gdk::Color->parse_color( @{GENDB::Tools::UserConfig->get_parameter('level_colors')}[$i-1] ) );
	$ebox->set_style($style);

	$self->action_area->pack_start( $ebox, 0, 0, 10 );
    }

    my $close = new Gtk::Button( "Previous ORF" );
    $close->signal_connect( 'clicked', \&prev_orf, $self );
    $self->action_area->pack_start( $close, 1, 1, 1 );
    $close = new Gtk::Button( "Next ORF" );
    $close->signal_connect( 'clicked', \&next_orf, $self );
    $self->action_area->pack_start( $close, 1, 1, 1 );
    $close = new Gtk::Button( "Close" );
    $close->signal_connect( 'clicked', sub{ $self->destroy } );
    $self->action_area->pack_start( $close, 1, 1, 1 );

    $self->vbox->add($vbox);
    $self->{ 'orf' } = $orf;
    $self->{ 'scroller' } = $scroller;

    $self->set_position( 'center' );

    return $self;
}

sub gendb_widget {
    my($self) = @_;
    return $self->{'widget'};
}

sub set_search_string {
    my($string) = @_;
    $last_search = $string;
}

sub prev_orf {
    my( undef, $self ) = @_;
    main->busy_cursor($self, 1);
    my $orf = $self->{ 'orf' };
    my $id = $orf->contig_id;
    my $start = $orf->start;
    my $orfs = GENDB::orf->fetchbySQL("contig_id = $id AND start < $start ORDER BY start DESC LIMIT 1");
    if( $orfs && $orfs->[0] ) {
	$self->{ 'orf' } = $orfs->[0];
	$self->{'scroller'}->children->destroy;
	my $canvas = &make_canvas( $orfs->[0], $self );
	$self->{'scroller'}->add( $canvas );
	$canvas->show_all;
	$self->set_title( "Facts for ORF ".$orfs->[0]->name );
	main->show_orf( $orfs->[0]->id );
    }
    main->busy_cursor($self, 0);
}

sub next_orf {
    my( undef, $self ) = @_;
    main->busy_cursor($self, 1);
    my $orf = $self->{ 'orf' };
    my $id = $orf->contig_id;
    my $start = $orf->start;
    my $orfs = GENDB::orf->fetchbySQL("contig_id = $id AND start > $start ORDER BY start ASC LIMIT 1");
    if( $orfs && $orfs->[0] ) {
	$self->{ 'orf' } = $orfs->[0];
	$self->{'scroller'}->children->destroy;
	my $canvas = &make_canvas( $orfs->[0], $self );
	$self->{'scroller'}->add( $canvas );
	$canvas->show_all;
	$self->set_title( "Facts for ORF ".$orfs->[0]->name );
	main->show_orf( $orfs->[0]->id );
    }
    main->busy_cursor($self, 0);
}

sub make_canvas {
    my( $orf, $self ) = @_;
    my $c = new Gnome::Canvas;
    my @positions=(5, 305, 355, 405, 655);
    my @titles = ("Fact overview", "Score", "Bits", "Tool description", "Hit description" );

    # draw header
    for( my $i = 0; $i <= $#titles; $i++ ) {
	new Gnome::CanvasItem( $c->root,
			       "Gnome::CanvasText",
			       "text", $titles[$i],
			       "x", $positions[$i],
			       "y", 10,
			       "font", $DEFAULT_FONT,
			       "anchor", "west",
			       "fill_color", "black"
			       );
    }

    my $orf_id = $orf->id;
    my $facts = sortfacts ($orf);
    my $ypos = 40;
    my $count = 0;

    my $row = 0;

    my @toollist = split( / /, GENDB::Tools::UserConfig->get_parameter( "toollist" ) );

    $self->{'widget'}->init_progress($#{$facts} + $#toollist);

    foreach my $tool_id ( @toollist ) {
	my $tool = GENDB::tool->init_id( $tool_id );
	$self->{'widget'}->update_progress($count++);
	next if( $tool == -1 );
	my $id = $tool->id;
	my $max_fact = undef;
	my $tool_facts = GENDB::fact->fetchbySQL( "orf_id = $orf_id AND tool_id = $id" );
	foreach( @$tool_facts ) {
	    if( defined( $max_fact ) ) {
		if( $_->score < $max_fact->score ) {
		    $max_fact = $_;
		} 
	    } else {
		$max_fact = $_;
	    }
	}
	next if( !defined( $max_fact ) );
	my $cgroup = new Gnome::CanvasItem( $c->root,
					    "Gnome::CanvasGroup",
					    "x", 0,
					    "y", $ypos );

	$cgroup->signal_connect( 'event', sub{ if( $_[1]->{ 'type' } eq 'button_press' && 
						   $_[1]->{ 'button' } == 3 ) {
	    &popup( $max_fact, $self, $_[1] );
	} } );	

	my $usedtool = GENDB::tool->init_id($max_fact->tool_id);
	my $desc = $max_fact->description;
	my $mark = $desc =~ /$last_search/i;
	
	# fact canvas
	&draw_fact( $cgroup, $positions[0], 0, 290, $max_fact );

	# score
	&add_text( $cgroup, $max_fact->score, $positions[1], 0, $mark );

	# e value
	&add_text( $cgroup, $max_fact->bits, $positions[2], 0, $mark );

	# used tool
	&add_text( $cgroup, $usedtool->description, $positions[3], 0, $mark );
	
	#description
	&add_text( $cgroup, $max_fact->description, $positions[4], 0, $mark );
	
	$ypos += 20;
    }
    $ypos += 10;
    new Gnome::CanvasItem( $c->root, "Gnome::CanvasLine",
			   'points', [0, $ypos, 500, $ypos],
			   );
    $ypos += 30;

    my $max_level = GENDB::Tools::UserConfig->get_parameter( "factlevel" );
    $max_level =~ s/Level//;
    $max_level = 5 if( $max_level eq "" );

    foreach my $fact (@{$facts}) {
	# create widget for each column
	
	$self->{'widget'}->update_progress($count++);
	# example_fact is used to access information
	# common to facts sharing level, tool and dbref
	# (-> multiple facts of the same tool run)
	my $level = $fact->level;
	last if( $level > $max_level );

	my $cgroup = new Gnome::CanvasItem( $c->root,
					    "Gnome::CanvasGroup",
					    "x", 0,
					    "y", $ypos );

	$cgroup->signal_connect( 'event', sub{ if( $_[1]->{ 'type' } eq 'button_press' && 
						   $_[1]->{ 'button' } == 3 ) {
	    &popup( $fact, $self, $_[1] );
	} } );	

	my $usedtool = GENDB::tool->init_id($fact->tool_id);
	my $desc = $fact->description;
	my $mark = $desc =~ /$last_search/i;

	# fact canvas
	&draw_fact( $cgroup, $positions[0], 0, 290, $fact );

	# score
	&add_text( $cgroup, $fact->score, $positions[1], 0, $mark );

	# e value
	&add_text( $cgroup, $fact->bits, $positions[2], 0, $mark );

	# used tool
	&add_text( $cgroup, $usedtool->description, $positions[3], 0, $mark );
	
	#description
	&add_text( $cgroup, $fact->description, $positions[4], 0, $mark );
	
	$ypos += 20;
    }

    $self->{'widget'}->end_progress();
    $c->set_scroll_region( 0, 0, 2000, $ypos );
    return $c;
}

sub draw_fact {
    my( $c, $xpos, $ypos, $width, $fact ) = @_;
    
    new Gnome::CanvasItem( $c,
			   "Gnome::CanvasLine",
			   "points", [$xpos, $ypos, $xpos + $width, $ypos],
			   "fill_color", "black",
			   "width_units", 3.0
			   );
    my $orflen;

    if (!GENDB::tool->init_id($fact->tool_id)->input_type) {
	$orflen = GENDB::orf->init_id($fact->orf_id)->length();
    }
    else {
	$orflen = int(GENDB::orf->init_id($fact->orf_id)->length() / 3);
    }

    my $item = new Gnome::CanvasItem( $c,
				      "Gnome::CanvasRect",
				      "x1",$xpos + ($fact->orffrom/$orflen)*$width,
				      "y1",$ypos-5,
				      "x2",$xpos + ($fact->orfto/$orflen)*$width,
				      "y2",$ypos+5,
				      "fill_color", getColorForFact($fact),
				      "outline_color", "black",
				      "width_pixels", 1  
				      );
}

sub popup {
    my( $fact, $self, $event ) = @_;
    
    my $menu = new Gtk::Menu;
    my $tool = GENDB::tool->init_id($fact->tool_id);
    my $mi = new Gtk::MenuItem( 'Show Alignment' );
    if (!$tool->alignment_state) {
	$mi->set_sensitive(0);
    }
    else {
	$mi-> signal_connect( 'activate', \&openAlignmentView, $fact );
    }
    $menu->append( $mi );
    $mi = new Gtk::MenuItem( 'Show DB entry' );
    # check whether this tool supplies a SRS link
    if (($tool != -1) && (!($tool->dburl() eq ""))) {
	# activate menu entry
	$mi->signal_connect( 'activate', sub {
	  Utils::open_url( $fact->SRSrecordURL );
	});
    }
    else {
	# deactive menu entry 
	$mi->set_sensitive(0);
    }
    $menu->append( $mi );
    $menu->append( new Gtk::MenuItem );
    $mi = new Gtk::MenuItem( 'Annotate ORF' );
    $mi->signal_connect( 'activate', \&annotate, $fact, $self );
    $menu->append( $mi );
    $menu->append( new Gtk::MenuItem );
    $mi = new Gtk::MenuItem( 'Search all ORFs' );
    $mi->signal_connect( 'activate', \&search, $fact, $self );
    $menu->append( $mi );
    $menu->show_all;
    $menu->popup( undef, undef, $event->{'time'}, $event->{'button'}, undef );
}

sub search {
    my(undef, $fact, $self) = @_;
    my $desc = $fact->description;
    $desc =~ s/\(/\.\*/g;
    $desc =~ s/\)/\.\*/g;
    $desc =~ s/\[/\.\*/g;
    $desc =~ s/\]/\.\*/g;
    $last_search = $desc;
    main->search_orf({'fact' => $desc});
    $self->{'scroller'}->children->destroy;
    my $canvas = &make_canvas($self->{'orf'}, $self);
    $self->{'scroller'}->add( $canvas );
    $canvas->show_all;
}

sub annotate {
    my( undef, $fact, $self ) = @_;
    my $edit = new AnnotationEditor;    
    $edit->set_usize( 800, 400 );
    $edit->show_all;
    $edit->signal_connect( 'delete_event', sub{ $edit->destroy } );
    $edit->set_orf( $self->{ 'orf' } );
    $edit->set_fact( $fact );
}

sub openAlignmentView {
    my ( undef, $fact ) = @_;
    while( Gtk->events_pending ) {
	Gtk->main_iteration;
	main->update_statusbar("Visualizing Alignment of ".$fact->dbref.". Please wait ...");
    }
    my $dbview = new Gtk::Dialog;
    $dbview->set_title("Database Alignment of ".$fact->dbref);
    $dbview->signal_connect( 'destroy', sub{ $dbview->destroy } );
    $dbview->set_usize(800, 600);
    my $frame = new Gtk::ScrolledWindow;
    $frame->set_policy( 'automatic', 'automatic' );
    
    my $tool = GENDB::tool->init_id ($fact->tool_id);
    my $orf = GENDB::orf->init_id($fact->orf_id);

    my $label = new Gtk::Label( "Overview of fact ".
				$fact->description." for Orf ".$orf->name );

    # get the tool result
    my $job_result = $tool->run_job($fact);

    if ($job_result == -1) {
	
	$dbview->destroy();
	# oops....SRS is broken......
	Utils::show_error ("Unable to retrieve information from SRS !");
	main->update_statusbar("Visualizing Alignment of ".$fact->dbref.". Please wait ... Done!");
	return;
    }

    my $textview = new Gtk::Text;
    $textview->insert(Gtk::Gdk::Font->load($SEQ_FONT),
					   undef, undef, $job_result."\n");


    my $close = new Gtk::Button( "Close" );
    $close->signal_connect( 'clicked', sub{ $dbview->destroy } );

    $frame->add( $textview );
    
    $dbview->vbox->pack_start( $label, 0, 0, 0 );
    $dbview->vbox->pack_start( $frame, 1, 1, 1 );

    my $bb = new Gtk::HButtonBox;
    $bb->pack_start_defaults( $close );
    $dbview->action_area->add( $bb );
    while( Gtk->events_pending ) {
	Gtk->main_iteration;
	main->update_statusbar("Visualizing Alignment of ".$fact->dbref.". Please wait ... Done!");
    }
    $dbview->set_position( 'center' );
    $dbview->show_all;
}

sub add_text {
    my( $c, $text, $x, $y, $mark ) = @_;
    
    new Gnome::CanvasItem( $c,
			   "Gnome::CanvasText",
			   "text", $text,
			   "x", $x,
			   "y", $y,
			   "font", $DEFAULT_FONT,
			   "anchor", "west",
			   "fill_color", ($mark) ? "red" : "black"
			   );
}

sub sortfacts {
    my ($orf) = @_;
    my $orf_id = $orf->id;

    my @facts = sort compare values (%{$orf->fetchfacts});

    return \@facts;
}

sub compare {
    my $result;
    return ($a->level <=> $b->level) if( $a->level != $b->level );
    my $as = $a->score;
    my $bs = $b->score;
    return ($as <=> $bs);
};

sub show {
    my( $self ) = @_;
    $self->show_all;
}

sub getColorForFact {

    my ($fact) = @_;

    my $fact_level = $fact->level;
    return @{GENDB::Tools::UserConfig->get_parameter('level_colors')}[$fact_level - 1];
}

1;
