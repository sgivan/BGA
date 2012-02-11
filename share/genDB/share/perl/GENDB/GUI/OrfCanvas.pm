package OrfCanvas;
# $Id: OrfCanvas.pm,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $

($GENDB::GUI::OrfCanvas::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use vars( qw(@ISA) );
use GENDB::GUI::GenDBWidget;
use GENDB::GENDB_CONFIG;
use GENDB::orf;
use GENDB::GUI::AnnotationEditor;
use GENDB::GUI::FactView;
use GENDB::GUI::OrfEditor;
use GENDB::Tools::fasta_exporter;
use GENDB::GUI::Utils;
use GENDB::Tools::CodonUsage;
use POSIX;

@ISA = qw(GenDBWidget);

my $visible_size = 1300;
my $update_done = 0;
####################################################
###                                              ###
### TODO:                                        ###
### - add more comments                          ###
### - move signalp to /vol/biotools and          ###
###   add a gv cleanup script                    ###
### - check cursor behaviour while waiting       ###
####################################################

#######################################
###                                 ###
### graphical contig representation ###
###                                 ###
#######################################

sub new {
	my $class = shift;
	my $cview = shift;
	my $self = $class->SUPER::new( 0, 0 );
	bless $self, $class;

	my $can = new Gnome::Canvas();

	my $zoom = new Gtk::Adjustment( 10, 1, 100, 1, 10, 0 ); 
	my $sb = new Gtk::HScrollbar( new Gtk::Adjustment( 0, 1, 100, 10, 100, 0 ) );
	my $sc = new Gtk::HScale( $zoom );

	my $scroller = new Gtk::ScrolledWindow;
	my $tt = new Gtk::Tooltips;
	$scroller->set_policy( 'never', 'automatic' );
	$scroller->get_vadjustment->step_increment( 10 );
	$scroller->add( $can );

	$scroller->signal_connect_after('event', sub {
	    my($s, $e) = @_;
	    return if($e->{'type'} ne "expose");
	    my( undef, undef, $vs ) = @{$can->allocation};
	    if($self->{'vs'} != $vs) {
		$self->update;
	    }
	});

	$sc->set_digits( 0 );
	$tt->set_tip( $sc, 'Zoom', 'Zoom' );

	$sc->signal_connect( 'button_release_event', sub {
	    &zoom( $zoom, $self );
	});

	$self->pack_start( $scroller, 1, 1, 1 );
	$self->pack_end( $sc, 0, 0, 0 );
	$self->pack_end( $sb, 0, 0, 0 );

	$self->{ 'grp' } = new Gnome::CanvasItem( $can->root, 'Gnome::CanvasGroup', 'x', 0, 'y', 0 );
	$self->{ 'can' } = $can;
	$self->{ 'sb' } = $sb;
	$self->{ 'zoom' } = $zoom;
	$self->{'zval'} = 10;
	$self->{'cview'} = $cview;
	$self->{'members'} = {};

	return $self;
}

sub update {
    my( $self ) = @_;
    my( undef, undef, $vs ) = @{$self->{'can'}->allocation};
    $self->{'can'}->set_scroll_region( 0, -75, $vs, 175 );
    $visible_size = $vs;

    $self->{'lines'}->destroy if( defined( $self->{'lines'} ) );
    $self->{'lines'} = new Gnome::CanvasItem( $self->{'can'}->root, 'Gnome::CanvasGroup' );
    for( my $i = -3; $i <= 3; $i++ ) {
	new Gnome::CanvasItem( $self->{'lines'}, "Gnome::CanvasLine",
			       'points', [0, $i * 30+50, $vs+100, $i * 30+50],
			       'fill_color', 'black' );
    }
    my $val = 0;
    $val = $self->{'sb'}->get_adjustment->get_value;
    &scroll( $self, $val, 0 );
}

sub group_orfs {
    my( $self, $members ) = @_;
    foreach( keys( %{$self->{'members'}} ) ) {
	$self->{'members'}->{$_} = 0;
    }
    foreach( @$members ) {
	$self->{'members'}->{$_} = 1;
    }
}

sub set_contig {
	my( $self, $contig ) = @_;
	my $len = $contig->length;
	my $adj = new Gtk::Adjustment( 0, 1, $len, 100, 1000, $self->{'zoom'}->get_value );
	$adj->signal_connect( 'value_changed', sub { &scroll($self, shift->get_value); } );
	$self->{ 'sb' }->set_adjustment( $adj );
	$self->{ 'clen' } = $len;
	$self->{'contig'} = $contig;
	$self->{ 'id' } = $contig->id;
	$self->{'can'}->set_scroll_region( -50, -75, $len, 175 );
	$self->{'lines'}->destroy if( defined( $self->{'lines'} ) );
	$self->{'lines'} = new Gnome::CanvasItem( $self->{'can'}->root, 'Gnome::CanvasGroup' );
	for( my $i = -3; $i <= 3; $i++ ) {
	    new Gnome::CanvasItem( $self->{'lines'}, "Gnome::CanvasLine",
				   'points', [0, $i * 30+50, $visible_size+100, $i * 30+50],
	                           'fill_color', 'black' );
	}
	&scroll( $self, 0, 1 );
	$self->{ 'sb' }->slider_update;
}

sub scroll {
    return if( $update_done );
    my( $self, $start, $supdate ) = @_;
    
    my( undef, undef, $vs ) = @{$self->{'can'}->allocation};
    if($self->{'vs'} != $vs) {
	$self->{'lines'}->destroy if( defined( $self->{'lines'} ) );
	$self->{'lines'} = new Gnome::CanvasItem( $self->{'can'}->root, 'Gnome::CanvasGroup' );
	for( my $i = -3; $i <= 3; $i++ ) {
	    new Gnome::CanvasItem( $self->{'lines'}, "Gnome::CanvasLine",
				   'points', [0, $i * 30+50, $vs+100, $i * 30+50],
				   'fill_color', 'black' );
	}
    }
    $self->{'can'}->set_scroll_region( 0, -75, $vs, 175 ) if( $self->{'vs'} != $vs);
    $self->{'vs'} = $vs;
    $visible_size = $vs;
    $start = int( $start );
    $start = -24 if( $start <= 0 );
    my $zoom = $self->{ 'zoom' }->get_value;
    my $id = $self->{ 'id' };
    
    $self->{'grp'}->destroy;
    $self->{'grp'} = new Gnome::CanvasItem( $self->{'can'}->root, 'Gnome::CanvasGroup',
					    'x', 0, 'y', 0 );
    my $end = $start + ($visible_size * $zoom);
	
    if( $id ) {
	if( $end > $self->{'contig'}->length ) {
	    $end = $self->{'contig'}->length+25;
	    $start = $end - ($visible_size * $zoom);
	}
	
	if( $start <= 0 ) {
	    $start = -24;
	    $end = $start + ($visible_size * $zoom);
	}
    }
	
    my $i = 500 - ( $start % 500 ); 
    my $s = $start - ( $start % 500 ) + 500;
    while( $i < $visible_size * $zoom ) {
	new Gnome::CanvasItem( $self->{'grp'}, "Gnome::CanvasLine",
			       'points', [$i/$zoom, 45, $i/$zoom, 55],
			       'fill_color', 'black',
			       'width_pixels', 1 );
	if( ($s % 5000) == 0 ) {
	    new Gnome::CanvasItem( $self->{'grp'}, "Gnome::CanvasLine",
				   'points', [$i/$zoom, 43, $i/$zoom, 57],
				   'fill_color', 'black',
				   'width_pixels', 2 );
	    new Gnome::CanvasItem( $self->{'grp'}, "Gnome::CanvasText",
				   'x', $i/$zoom,
				   'y', 40, 
				   'text', $s,
				   'font', $SMALL_FONT,
				   'anchor', 'center',	
				   'fill_color', 'black' );
	}
	$s += 500;
	$i += 500;
    }

    if($id) {
	my $orfs = GENDB::orf->fetchbySQL("contig_id = $id AND".
					  "(start <= $end AND stop >= $start)");
	my $iorfs = GENDB::Tools::UserConfig->get_parameter('ignored_orfs');
	foreach( @$orfs ) {
	    next if(!$iorfs && $_->status == 2);
	    &show_orf( $_, $self->{'grp'}, $zoom, $start, 
		       $self, $self->{'members'}->{$_->name} );
	}
    }
	    
    if( $supdate ) {
	$update_done = 1;
	$self->{'sb'}->get_adjustment->set_value( $start );
	$self->{'sb'}->slider_update;
	$update_done = 0;
    }
    if( defined( $self->{ 'sync' } ) ) {
	$self->{ 'sync' }->scroll( $start );
    }
}

sub set_sync {
    my ( $self, $widget ) = @_;
    $self->{ 'sync' } = $widget;
}

sub show_orf {
    my( $orf, $c, $zoom, $start, $self, $group ) = @_;
    my $x = ($orf->start - $start) / $zoom;

    my $trans = 90;
    my $length = $orf->length / $zoom;
    my $frame = $orf->frame;
    my $grp = new Gnome::CanvasItem( $c, 'Gnome::CanvasGroup', 
				     'x', $x, 'y', (-1*$frame) * 30 );
    my $y1 = 0 + ($trans/2);
    my $y2 = 10 + ($trans/2);

    if($frame == 0) {
	$y1 = 2.5 + ($trans/2);
	$y2 = 7.5 + ($trans/2);
    }

    my $rect = new Gnome::CanvasItem( $grp, 'Gnome::CanvasRect',
			"x1", 0,
  		        "x2", $length,
			"y1", $y1,
			"y2", $y2,
			"fill_color", &getColorForOrf( $orf, $self ),
			"outline_color", "black",
			"width_pixels", 1
				      );
    if( $group ) {
	my $rect2 = new Gnome::CanvasItem( $grp, 'Gnome::CanvasRect',
					   "x1", -1,
					   "y1", -1 + ($trans/2),
					   "x2", $length+2,
					   "y2", 10 + ($trans/2)+2,
					   "outline_color", "red",
					   "width_pixels", 2
					   );
    }
    
    my $text = new Gnome::CanvasItem( $grp,
				      "Gnome::CanvasText",
				      "text", $orf->name,
				      "x", 0,
				      "y", -10 + ($trans/2),
				      "anchor", "west",
				      "font", $DEFAULT_FONT,
				      "fill_color", "black",
				      );	
    my $gene = $orf->latest_annotation_name;
    my $text2;
    if( $gene ne '' && $gene != -1 ) {
	$text2 = new Gnome::CanvasItem( $grp,
					"Gnome::CanvasText",
					"text", $gene,
					"x", 0,
					"y", +20 + ($trans/2),
					"anchor", "west",
					"font", $DEFAULT_FONT,
					"fill_color", "black",
					);		
	$text2->hide;
    }
    $text->hide;
    $rect->signal_connect( 'event', \&do_event, $orf, $text, $text2, $self );
}

sub hilite {
    my( $self, $orf ) = @_;
    $self->{ 'hilited_orf' } = $orf->name;
    my $z = $self->{'zoom'}->get_value;
    my $start = $orf->start-150;
    if(GENDB::Tools::UserConfig->get_parameter("center_orf")) {
	$start = $orf->start-($self->{'vs'}*$z)/2+$orf->length/2;
    }
    &scroll( $self, $start, 1 );
}

sub compute_facts {
    my(undef, $orf, $self) = @_;
    $orf->drop_facts;
    $orf->toollevel(0);
    for ($job_id = $orf->order_next_job; $job_id != -1;
	 $job_id = $orf->order_next_job) {
	Job->create($GENDB::Config::GENDB_CONFIG, $job_id);
    }
}

####################################################################
### open a popup menu on click of right mouse button at each ORF ###
####################################################################
sub open_popup {
    my( $orf, $self, $event ) = @_;

    my $menu = new Gtk::Menu;
    my $separator = new Gtk::MenuItem;
    $separator->set_sensitive(0);
    my $mi = new Gtk::MenuItem( 'Show Facts' ); 
    $mi-> signal_connect( 'activate', \&show_facts, $orf, $self );
    $menu->append( $mi );

    $mi = new Gtk::MenuItem( 'Recompute Facts' );
    $mi->signal_connect( 'activate', \&compute_facts, $orf, $self );
    $menu->append( $mi );
    $menu->append(new Gtk::MenuItem());
    $mi = new Gtk::MenuItem( 'Show sequence' );
    $mi->signal_connect( 'activate', \&show_sequence, $orf, $self );
    $menu->append( $mi );
    $mi = new Gtk::MenuItem( 'Show codon usage' );
    $mi->signal_connect( 'activate', \&show_codon_usage, $orf, $self );
    $menu->append( $mi );
    $menu->append( $separator );
    if(defined $GENDB_HTH) {
	$mi = new Gtk::MenuItem( 'Run hth' );
	$mi->signal_connect( 'activate', \&run_hth, $orf, $self );
	$menu->append( $mi );
    }
    if(defined $GENDB_SAPS) {
	$mi = new Gtk::MenuItem( 'Run SAPS' );
	$mi->signal_connect( 'activate', \&run_saps, $orf, $self );
	$menu->append( $mi );
    }
    if(defined $GENDB_SIGNALP) {
	$mi = new Gtk::MenuItem( 'Run SignalP' );
	$mi->signal_connect( 'activate', \&run_signalp, $orf, $self );
	$menu->append( $mi );    
    }
    if(defined $GENDB_TMHMM) {
	$mi = new Gtk::MenuItem( 'Run TMHMM' );
	$mi->signal_connect( 'activate', \&run_tmhmm, $orf, $self );
	$menu->append( $mi );
    }
    $separator = new Gtk::MenuItem;
    $menu->append( $separator );
    $mi = new Gtk::MenuItem( 'Export as FASTA' );
    $mi->signal_connect( 'activate', \& Tools::fasta_exporter::fasta_export_dialog, $orf, $self );
    $menu->append( $mi );
    $separator = new Gtk::MenuItem;
    $menu->append( $separator );
    $mi = new Gtk::MenuItem( 'ORF Editor' );
    $mi-> signal_connect( 'activate', \& OrfEditor::orf_editor, $orf->name );
    $menu->append( $mi );
    $mi = new Gtk::MenuItem( 'ORF Annotator' );
    $mi-> signal_connect( 'activate', \&orf_annotate, $orf, $self );
    $menu->append( $mi );
    $separator = new Gtk::MenuItem;
    $menu->append( $separator );
    $mi = new Gtk::MenuItem( 'Change ORFName' );
    $mi-> signal_connect( 'activate', \&change_name, $orf, $self );
    $menu->append( $mi );
    $menu->show_all;
    $menu->popup( undef, undef, $event->{'time'}, $event->{'button'}, undef );   
}

##########################
### Change name of OFR ###
##########################
sub change_name {
    my($item , $orf, $self) = @_;
    my $dialog = new Gtk::Dialog;
    my $table  = new Gtk::Table(4, 4);
    my $label1 = new Gtk::Label("Change name of ORF");
    my $label2 = new Gtk::Label("from");
    my $label3 = new Gtk::Label("to");
    my $label4 = new Gtk::Label();
    my $edit1  = new Gtk::Entry;
    my $edit2  = new Gtk::Entry;

    my $bbox   = new Gtk::HButtonBox;
    my $okb    = new Gtk::Button('Change');
    my $close  = new Gtk::Button('Close');

    $edit1->set_text($orf->name);

    $table->set_col_spacings(5);
    $table->set_row_spacings(5);
    $table->set_border_width(5);
    $bbox->set_layout('end');
    $dialog->set_position('center');
    $dialog->set_title('Change ORFname');

    $table->attach_defaults($label1, 0, 3, 0, 1);
    $table->attach_defaults($label2, 0, 1, 1, 2);
    $table->attach_defaults($edit1,  1, 3, 1, 2);
    $table->attach_defaults($label3, 0, 1, 2, 3);
    $table->attach_defaults($edit2,  1, 3, 2, 3);
    $table->attach_defaults($label4, 0, 3, 3, 4);

    $bbox->pack_start_defaults($okb);
    $bbox->pack_start_defaults($close);

    $dialog->vbox->add($table);
    $dialog->action_area->add($bbox);

    $dialog->show_all;

    $edit1->signal_connect('changed', sub {$label4->set('');});
    $edit2->signal_connect('changed', sub {$label4->set('');});
    $close->signal_connect_object('clicked', $dialog, 'destroy');
    $okb->signal_connect('clicked', sub {
	my $old_name = $edit1->get_text;
	my $new_name = $edit2->get_text;

	my $orf = GENDB::orf->init_name($old_name);
	my $check = GENDB::orf->init_name($new_name);

	if(ref $orf && !ref $check) {
	    $orf->name($new_name);
	    $label4->set('Name changed!');
	} else {
	    $label4->set('Could not change name!');
	}
    });
}

sub show_facts {
    my( $item, $orf, $self ) = @_;
    if( $orf->no_fact == 0 ) {
	Utils::show_information( "No Facts for ".$orf->name );
    } else {
	while( Gtk->events_pending ) {
	    Gtk->main_iteration;
	    main->update_statusbar("Visualizing Facts of ORF ".$orf->name.". Please wait ...");
	}
	main->busy_cursor($self, 1);
	my $win = new FactView( $orf, $self->{'progressbar'} );
	$self->add_child($win->gendb_widget);
	$win->show;
	main->update_statusbar("Visualizing Facts of ORF ".$orf->name.". Please wait ... Done!");
	main->busy_cursor($self, 0);
    }
}

##################################################################################
### Prediction of signal peptides and signal anchors by a  hidden Markov model ###
##################################################################################
sub run_signalp {
    my( $item, $orf, $self ) = @_;

    main->update_statusbar("Running SignalP ...");
    my $cursor = Gtk::Gdk::Cursor->new(150);
    my $win = $self->{'cview'}->get_parent_window;
    $win->set_cursor($cursor);
    Gtk->main_iteration while ( Gtk->events_pending );
    my $orfname=$orf->name;
    my $info = new Gtk::Dialog;
    $info->set_usize( 400, 300 );
    $info->set_title( "Result of SignalP run for ".$orfname );
    
    #create temporary file prefix
    my $tmpname=POSIX::tmpnam();
    $tmpname=~/(.*)\/(.*)$/;
    my $tmpdir=$1;
    my $tmpfile=$2;

    my $tmpfas=$tmpname.".fas";
    my $tmpout=$tmpname.".out";
    open(AASEQ, "> $tmpfas");
    print AASEQ ">$orfname\n";
    print AASEQ $orf->aasequence;
    close AASEQ;   
    
    my $graphics=GENDB::Tools::UserConfig->get_parameter("signalp graphics mode");
    my $type=GENDB::Tools::UserConfig->get_parameter("signalp type");
    my $format=GENDB::Tools::UserConfig->get_parameter("signalp format");
    my $trunc=GENDB::Tools::UserConfig->get_parameter("signalp trunc");
    
    system("$GENDB_SIGNALP $graphics -t $type -f $format -trunc $trunc -d $tmpdir -outfile $tmpfile -c $tmpfas > $tmpout ");

    # get SignalP result #
    my $result="";
    open(RESULT, $tmpout);
    while (<RESULT>) {
	$result.=$_;
    };

    # cleanup signalp result files and $tmpfas
    unlink ($tmpfas, $tmpout, "$tmpname.gnu");
    
    $frame = new Gtk::Frame( 'SignalP result:' );
    $text = new Gtk::Text;
    $text->set_word_wrap (1); 
    $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'automatic' );
    $scroller->add( $text );
    my $color = Gtk::Gdk::Color->parse_color( 'black' );
    $text->insert(Gtk::Gdk::Font->load($SEQ_FONT), $color, undef, $result );
    $frame->add( $scroller );
    $info->vbox->pack_start_defaults( $frame );

    $info->signal_connect( 'destroy', sub{$info->destroy} );
    my $ok = new Gtk::Button( "Close" );
    $ok->signal_connect( 'clicked', sub{$info->destroy} );
    $info->action_area->pack_start_defaults( $ok );
    $info->position( 'mouse' );
    $info->show_all;
    $win->set_cursor(Gtk::Gdk::Cursor->new(68));
    $cursor=undef;
    main->update_statusbar("Finished running SignalP!");
};

######################################################################################
### Run SAPS (Statistical Analysis of Protein Sequences) and show result in window ###
######################################################################################
sub run_saps {
    my( $item, $orf, $self ) = @_;

    main->update_statusbar("Running SAPS ...");
    my $cursor = Gtk::Gdk::Cursor->new(150);
    my $win = $self->{'cview'}->get_parent_window;
    $win->set_cursor($cursor);
    Gtk->main_iteration while ( Gtk->events_pending );
    my $orfname=$orf->name;
    my $info = new Gtk::Dialog;
    $info->set_usize( 400, 300 );
    $info->set_title( "Result of SAPS run for ".$orfname );
    
    #create temporary file prefix
    my $tmpname=POSIX::tmpnam();
    $tmpname=~/(.*)\/(.*)$/;
    my $tmpdir=$1;
    my $tmpfile=$2;

    my $tmpfas=$tmpname.".fas";
    my $tmpout=$tmpname.".out";
    open(AASEQ, "> $tmpfas");
    print AASEQ ">$orfname\n";
    print AASEQ $orf->aasequence;
    close AASEQ;   
    
    system("$GENDB_SAPS -b $tmpfas > $tmpout");
    unlink $tmpfas;

    # get SignalP result #
    my $result="";
    open(RESULT, $tmpout);
    while (<RESULT>) {
	$result.=$_;
    };
    unlink $tmpout;

    $frame = new Gtk::Frame( 'SAPS result:' );
    $text = new Gtk::Text;
    $text->set_word_wrap (1); 
    $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'automatic' );
    $scroller->add( $text );
    my $color = Gtk::Gdk::Color->parse_color( 'black' );
    $text->insert(Gtk::Gdk::Font->load($SEQ_FONT), $color, undef, $result );
    $frame->add( $scroller );
    $info->vbox->pack_start_defaults( $frame );

    $info->signal_connect( 'destroy', sub{$info->destroy} );
    my $ok = new Gtk::Button( "Close" );
    $ok->signal_connect( 'clicked', sub{$info->destroy} );
    $info->action_area->pack_start_defaults( $ok );
    $info->position( 'mouse' );
    $info->show_all;
    $win->set_cursor(Gtk::Gdk::Cursor->new(68));
    $cursor=undef;
    main->update_statusbar("Finished running SAPS!");
};

##########################################################################################
### Run hth (helix-turn-helix analysis of Protein Sequences) and show result in window ###
##########################################################################################
sub run_hth {
    my( $item, $orf, $self ) = @_;

    main->update_statusbar("Running hth ...");
    my $cursor = Gtk::Gdk::Cursor->new(150);
    my $win = $self->{'cview'}->get_parent_window;
    $win->set_cursor($cursor);
    Gtk->main_iteration while ( Gtk->events_pending );
    my $orfname=$orf->name;
    my $info = new Gtk::Dialog;
    $info->set_usize( 400, 300 );
    $info->set_title( "Result of hth run for ".$orfname );
    
    #create temporary file prefix
    my $tmpname=POSIX::tmpnam();
    $tmpname=~/(.*)\/(.*)$/;
    my $tmpdir=$1;
    my $tmpfile=$2;

    my $tmpfas=$tmpname.".fas";
    my $tmpout=$tmpname.".out";
    open(AASEQ, "> $tmpfas");
    # write plain AA sequence to file
    print AASEQ $orf->aasequence;
    close AASEQ;   
    
    system("$GENDB_HTH $tmpfas > $tmpout");
    unlink $tmpfas;

    # get hth result #
    my $result="";
    open(RESULT, $tmpout);
    while (<RESULT>) {
	if (/.+code\./) {
	    $result="";
	}
	else {
	    $result.=$_;
	};
    };
    unlink $tmpout;

    $frame = new Gtk::Frame( 'hth result:' );
    $text = new Gtk::Text;
    $text->set_word_wrap (1); 
    $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'automatic' );
    $scroller->add( $text );
    my $color = Gtk::Gdk::Color->parse_color( 'black' );
    $text->insert(Gtk::Gdk::Font->load($SEQ_FONT), $color, undef, $result );
    $frame->add( $scroller );
    $info->vbox->pack_start_defaults( $frame );

    $info->signal_connect( 'destroy', sub{$info->destroy} );
    my $ok = new Gtk::Button( "Close" );
    $ok->signal_connect( 'clicked', sub{$info->destroy} );
    $info->action_area->pack_start_defaults( $ok );
    $info->position( 'mouse' );
    $info->show_all;
    $win->set_cursor(Gtk::Gdk::Cursor->new(68));
    $cursor=undef;
    main->update_statusbar("Finished running hth!");
};

###########################################################################################
# Run TMHMM (Prediction of transmembrane helices in proteins) and show result in window ###
###########################################################################################
sub run_tmhmm {
    my( $item, $orf, $self ) = @_;

    main->update_statusbar("Running TMHMM ...");
    my $cursor = Gtk::Gdk::Cursor->new(150);
    my $win = $self->{'cview'}->get_parent_window;
    $win->set_cursor($cursor);
    Gtk->main_iteration while ( Gtk->events_pending );
    my $orfname=$orf->name;
    my $info = new Gtk::Dialog;
    $info->set_usize( 400, 300 );
    $info->set_title( "Result of TMHMM run for ".$orfname );
    
    #create temporary file prefix
    my $tmpname=POSIX::tmpnam();
    $tmpname=~/(.*)\/(.*)$/;
    mkdir($tmpname, '511');

    my $tmpdir=$1;
    my $tmpfile=$2;

    my $tmpfas=$tmpname.".fas";
    my $tmpout=$tmpname.".out";
    my $tmpeps = $tmpname . "/$orfname.eps";
    open(AASEQ, "> $tmpfas");
    # write plain AA sequence to file
    print AASEQ ">$orfname\n";
    print AASEQ $orf->aasequence;
    close AASEQ;   
    print "\n\n$GENDB_TMHMM --workdir=$tmpname $tmpfas > $tmpout\n\n";
    system("$GENDB_TMHMM --workdir=$tmpname $tmpfas > $tmpout");

    unlink $tmpfas;

    # get hth result #
    my $result="";
    open(RESULT, $tmpout);
    while (<RESULT>) {
	if (/.+code\./) {
	    $result="";
	}
	else {
	    $result.=$_;
	};
    };
    unlink $tmpout;

    # use a cleanup gv script here!!!!!
    system("$GENDB_GV $tmpeps $tmpname&");
#    system("display $tmpeps $tmpname &");# use imagemagick to display eps

    $frame = new Gtk::Frame( 'TMHMM result:' );
    $text = new Gtk::Text;
    $text->set_word_wrap (1); 
    $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'automatic' );
    $scroller->add( $text );
    my $color = Gtk::Gdk::Color->parse_color( 'black' );
    $text->insert(Gtk::Gdk::Font->load($SEQ_FONT), $color, undef, $result );
    $frame->add( $scroller );
    $info->vbox->pack_start_defaults( $frame );

    $info->signal_connect( 'destroy', sub{$info->destroy} );
    my $ok = new Gtk::Button( "Close" );
    $ok->signal_connect( 'clicked', sub{$info->destroy} );
    $info->action_area->pack_start_defaults( $ok );
    $info->position( 'mouse' );
    $info->show_all;
    $win->set_cursor(Gtk::Gdk::Cursor->new(68));
    $cursor=undef;
    main->update_statusbar("Finished running TMHMM!");
};

#######################################################
### Calculate codon usage and show result in window ###
#######################################################
sub show_codon_usage {
    my( $item, $orf, $self ) = @_;

    main->update_statusbar("Calculating codon usage ...");
    my $cursor = Gtk::Gdk::Cursor->new(150);
    my $win = $self->{'cview'}->get_parent_window;
    $win->set_cursor($cursor);
    Gtk->main_iteration while ( Gtk->events_pending );
    my $orfname=$orf->name;
    my $info = new Gtk::Dialog;
    $info->set_usize( 400, 300 );
    $info->set_title( "Codon usage for ".$orfname );
    
    #create temporary file prefix
    my $tmpname=POSIX::tmpnam();
    $tmpname=~/(.*)\/(.*)$/;
    my $tmpdir=$1;
    my $tmpfile=$2;

    my $tmpout=$tmpname.".out";

    my $res = GENDB::Tools::CodonUsage->calc_usage( $orf->sequence, $tmpout );

    # get codon usage result #
    my $result="";
    open(RESULT, $tmpout);
    while (<RESULT>) {
	$result.=$_;
    };
    unlink $tmpout;

    $frame = new Gtk::Frame( 'Codon usage:' );
    $text = new Gtk::Text;
    $text->set_word_wrap (1); 
    $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'automatic' );
    $scroller->add( $text );
    my $color = Gtk::Gdk::Color->parse_color( 'black' );
    $text->insert(Gtk::Gdk::Font->load($SEQ_FONT), $color, undef, $result );
    $frame->add( $scroller );
    $info->vbox->pack_start_defaults( $frame );

    $info->signal_connect( 'destroy', sub{$info->destroy} );
    my $ok = new Gtk::Button( "Close" );
    $ok->signal_connect( 'clicked', sub{$info->destroy} );
    $info->action_area->pack_start_defaults( $ok );
    $info->position( 'mouse' );
    $info->show_all;
    $win->set_cursor(Gtk::Gdk::Cursor->new(68));
    $cursor=undef;
    main->update_statusbar("Finished calculation of codon usage!");
};


sub orf_annotate {
    my( $item, $orf, $self ) = @_;
    my $edit = new AnnotationEditor;
    $edit->set_usize(950, 550);
    $edit->show_all;
    $edit->signal_connect( 'delete_event', sub{ $edit->destroy; } );
    $edit->set_orf( $orf );
}

sub show_sequence {
    my( $item, $orf, $self ) = @_;
    my $font = Gtk::Gdk::Font->load($SEQ_FONT);
    my $info = new Gtk::Dialog;
    $info->set_usize( 675, 300 );
    $info->set_title( "Sequences of ".$orf->name );
    $info->vbox->set_border_width(3);

    my $hbox = new Gtk::HBox(1, 3);
    $stopc = new Gtk::Label('StopCodon: '.$orf->stopcodon);
    $hbox->pack_start_defaults($stopc);
    my $lengthc = new Gtk::Label('Length: '.$orf->length);
    $hbox->pack_start_defaults($lengthc);
    $info->vbox->pack_start($hbox, 0, 0, 3);

    # DNA SEQUENCE #
    my $frame = new Gtk::Frame( 'DNA Sequence' );
    my $stext = new Gtk::Text;
    $stext->set_word_wrap (1); 
    my $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'automatic' );
    $scroller->add( $stext );
    my $seq = $orf->sequence;
    $seq =~ tr/ATGC/atgc/;
    my @l = split( //, $seq );
    my $count = 0;
    foreach my $s ( @l ) {
	my $color = Gtk::Gdk::Color->parse_color( 'black' );
	my $bcol = undef;
	if( $s eq 'a' || $s eq 'A' ) {
	    $color =  Gtk::Gdk::Color->parse_color( 'red' );
	} elsif ( $s eq 't' || $s eq 'T'  ) {
	    $color =  Gtk::Gdk::Color->parse_color( 'green' );
	} elsif ( $s eq 'g'  || $s eq 'G' ) {
	    $color =  Gtk::Gdk::Color->parse_color( 'blue' );
	} elsif ( $s eq 'c'  || $s eq 'C' ) {
	    $color =  Gtk::Gdk::Color->parse_color( 'black' );
	} else {
	    $color =  Gtk::Gdk::Color->parse_color( 'orange' );
	    $bcol =  Gtk::Gdk::Color->parse_color( 'black' );
	}
	$count++;
	$stext->insert( $font, $color, $bcol, $s );
	if($count % 10 == 0) {
	    $stext->insert( $font, $color, undef, "   " );
	}
	if($count == 60) {
	    $stext->insert( $font, $color, undef, "\n" );
	    $count = 0;
	}  
    }
    $frame->add( $scroller );
    $info->vbox->pack_start_defaults( $frame );

    # AA SEQUENCE #
    $frame = new Gtk::Frame( 'AA Sequence' );
    my $text = new Gtk::Text;
    $text->set_word_wrap (1); 
    $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'automatic' );
    $scroller->add( $text );
    my $color = Gtk::Gdk::Color->parse_color( 'black' );
    my $seq = $orf->aasequence;
    my $num = length($seq)/10 + 1;
    my @l = unpack( "a10" x $num, $seq );
    my $count = 0;
    foreach(@l) {
	$count++;
	$text->insert( $font, $color, $bcol, "$_   " );
	if($count == 6) {
	    $text->insert( $font, $color, undef, "\n" );
	    $count = 0;
	}
    }
    $frame->add( $scroller );
    $info->vbox->pack_start_defaults( $frame );

    $info->signal_connect( 'destroy', sub{$info->destroy} );
    my $ok = new Gtk::Button( "Close" );
    $ok->signal_connect( 'clicked', sub{$info->destroy} );
    $info->action_area->pack_start_defaults( $ok );
    $info->position( 'mouse' );
    $info->show_all;

    $text->signal_connect('button_press_event', sub{ shift->copy_clipboard });
}

sub do_event {
    my( $item, $orf, $text, $text2, $self, $event ) = @_;
    if( $event->{ 'type' } eq 'button_press' ) {
	if( $event->{ 'button' } == 1 ) {
	    $self->{ 'hilited_orf' } = $orf->name;
	    $self->{ 'cview' }->show_contig_orf( $self->{ 'contig' }, $orf );
	} elsif($event->{ 'button' } == 3 && $orf->frame) {
	    &open_popup($orf, $self, $event);
	}
    } elsif( $event->{ 'type' } eq 'enter_notify' ) {
	$text->show;
	$text2->show if(defined $text2);
    } elsif( $event->{ 'type' } eq 'leave_notify' ) {
	$text->hide;
	$text2->hide if(defined $text2);
    }	
}

sub zoom {
	my( $adj, $self ) = @_;
	my $nzoom = $adj->get_value;
	my $len = $self->{'clen'} - int($self->{'clen'} / $nzoom) + 1;
	$self->{'sb'}->get_adjustment->step_increment($nzoom);
	$self->{'sb'}->get_adjustment->page_increment($nzoom*10);
	$self->{'sb'}->get_adjustment->page_size( $visible_size * $nzoom/2 );
	$self->{'sb'}->slider_update;
	$self->{'zval'} = $nzoom;
	if( defined( $self->{ 'sync' } ) ) {
	    $self->{ 'sync' }->set_zoom( $nzoom );
	}
   
	my $cpos = $self->{'sb'}->get_adjustment->get_value;
	&scroll( $self, $cpos, 1 );
}	

sub getColorForOrf {

    my ($orf, $self) = @_;
    if ( $self->{ 'hilited_orf' } eq $orf->name ) {
	return &Utils::get_color_for_orf( $orf, 'selected' );
    }
    return &Utils::get_color_for_orf( $orf, 'normal' );
}

1;
