package SequenceCanvas;

($GENDB::GUI::SequenceCanvas::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use vars( qw(@ISA) );

use GENDB::GENDB_CONFIG;

use GENDB::GUI::Utils;
use GENDB::Common;
use GENDB::orf;
use GENDB::contig;
use GENDB::Config;
@ISA = qw( Gtk::VBox );

my $font = $SEQ_FONT;
my $small_font = $SMALL_FONT;
my $font_width = 9;
my $scale = 25;

########################################
###                                  ###
### Module to draw Sequence and ORFs ###
###                                  ###
########################################

sub new {
	my $class = shift;
	my $self = $class->SUPER::new( 0, 0 );
	bless $self;

	my $canvas = &make_canvas( $self );
	my $scroller = new Gtk::ScrolledWindow;
	my $adj = new Gtk::Adjustment( 0, 0, 100, 1, 10, 1 );
	my $scroll = new Gtk::HScrollbar( $adj );

	$scroll->signal_connect_after('event', sub {
	    my($s, $e) = @_;
	    return if($e->{'type'} ne "expose");
	    my( undef, undef, $vs ) = @{$canvas->allocation};
	    if($self->{'vs'} != $vs) {
		$self->update;
	    }
	});

	$scroller->set_policy( 'never', 'automatic' );
	$scroller->get_vadjustment->step_increment( 10 );
	$scroller->add( $canvas );

	$self->pack_start( $scroller, 1, 1, 1 );
	$self->pack_end( $scroll, 0, 0, 0 );

	$self->{'is_visible'} = 1;
	$self->{ 'canvas' } = $canvas;
	$self->{ 'scrollbar' } = $scroll;
	$self->{ 'scrolled_window' } = $scroller;
	$self->{ 'vlength' } = 500;

	$font_width = Gtk::Gdk::Font->load($font)->string_width("W") + 1;

	return $self;
}

sub mark_item {
    my( $self ) = @_;
    return $self->{'mark'};
}

sub canvas {
    my( $self ) = @_;
    return $self->{ 'canvas' };
}

sub update {
    my( $self ) = @_;
    return if($self->{'no_update'});
    my $val = 0;
    $val = $self->{'adj'}->get_value if( $self->{ 'adj' } );
    &scroll( undef, $self, $val );
}

sub hideme {
    my( $self ) = @_;
    $self->hide;
    $self->{'is_visible'} = 0;
}

sub showme {
    my( $self ) = @_;
    $self->show;
    $self->{'is_visible'} = 1;
}

sub get_contig_name {
    my( $self ) = @_;
    return "" if( !defined( $self->{'contig'} ) );
    return $self->{'contig'}->name;
}

sub is_visible {
    my( $self ) = @_;
    return $self->{'is_visible'};
}

sub make_canvas {
	my( $self ) = @_;
	my $c = new Gnome::Canvas;
	$c->set_scroll_region( 0, -25, 1300, 275 );

	new Gnome::CanvasItem( $c->root,
		'Gnome::CanvasLine',
		'points', [0, 125, 1300, 125],
		'fill_color', 'black',
		'width_pixels', 1 );

	$self->{'mark'} =  new Gnome::CanvasItem( $c->root,
		'Gnome::CanvasRect',
		'x1', 0,
		'x2', 0,
		'y1', 0,
                'y2', 0,
		'fill_color', 'orange' );
	
	$self->{ 'seq' } = new Gnome::CanvasItem( $c->root,
		'Gnome::CanvasText',
		'x', 0,
		'y', 94,
		'text', '',
		'font', $font,
		'anchor', 'west',
		'fill_color', 'black' );
	$self->{ 'rseq' } = new Gnome::CanvasItem( $c->root,
		'Gnome::CanvasText',
		'x', 0,
		'y', 156,
		'text', '',
		'font', $font,
		'anchor', 'west',
		'fill_color', 'black' );
		
	$self->{ 'fr1' } = new Gnome::CanvasItem( $c->root,
		'Gnome::CanvasText',
		'x', 0,
		'y', 0,
		'text', '',
		'font', $font,
		'anchor', 'west',
		'fill_color', 'black' );
	$self->{ 'fr2' } = new Gnome::CanvasItem( $c->root,
		'Gnome::CanvasText',
		'x', 0,
		'y', 32,
		'text', '',
		'font', $font,
		'anchor', 'west',
		'fill_color', 'black' );
	$self->{ 'fr3' } = new Gnome::CanvasItem( $c->root,
		'Gnome::CanvasText',
		'x', 0,
		'y', 63,
		'text', '',
		'font', $font,
		'anchor', 'west',
		'fill_color', 'black' );
	
	$self->{ 'fr-1' } = new Gnome::CanvasItem( $c->root,
		'Gnome::CanvasText',
		'x', 0,
		'y', 249,
		'text', '',
		'font', $font,
		'anchor', 'west',
		'fill_color', 'black' );
	$self->{ 'fr-2' } = new Gnome::CanvasItem( $c->root,
		'Gnome::CanvasText',
		'x', 0,
		'y', 218,
		'text', '',
		'font', $font,
		'anchor', 'west',
		'fill_color', 'black' );
	$self->{ 'fr-3' } = new Gnome::CanvasItem( $c->root,
		'Gnome::CanvasText',
		'x', 0,
		'y', 187,
		'text', '',
		'font', $font,
		'anchor', 'west',
		'fill_color', 'black' );
		
	for( my $i = 0; $i < 6; $i++ ) {
		my $x = $scale*$font_width*$i;
		$self->{ 'scale' }->[$i] = new Gnome::CanvasItem( $c->root,
			'Gnome::CanvasLine',
			'points', [$x, 120, $x, 130],
			'fill_color', 'black',
			'width_pixels', 1 );
		$self->{ 'text' }->[$i] = new Gnome::CanvasItem( $c->root,
			 'Gnome::CanvasText',
			 'x', $x,
			 'y', 140, 
			'text', $i * 25,	
			 'font', $small_font,
                         'anchor', 'center',	
			 'fill_color', 'black' );
	}

	$self->{ 'orfs' } =  new Gnome::CanvasItem( $c->root, 
			"Gnome::CanvasGroup",
			   "x", 0,
			   'y', 0 );

	$self->{ 'stop' } = new Gnome::CanvasItem( $c->root, 
			"Gnome::CanvasGroup",
			   "x", 0,
			   'y', 0 );		   
	return $c
}

sub aa_seq {
	my( $seq, $fr, $rev ) = @_;
	my $aaseq = " ";
	my $len = length( $seq );
	for( my $l = $fr; $l < $len; $l++ ) {
		if( (($l+2) % 3) == 1 ) {
		    my $substr = substr( $seq, $l-abs($fr), 3 );
		    if( $rev ) {
			my $revstr = reverse( $substr );
			my $aa = dna2aa( $revstr );
			$aaseq .= ( $aa eq '' ) ? "?" : $aa;
		    } else {
			my $aa = dna2aa( $substr );
			$aaseq .= ( $aa eq '' ) ? "?" : $aa;
		    }
		} else { $aaseq .= " "; }
	}
	return $aaseq;
}

sub hilite {
    my( $self, $orf, $end, $hilite ) = @_;
    return if(!$self->{'is_visible'});
    $self->{'no_update'} = 1;
    $self->{ 'hilited_orf' } = $orf->name if(!$hilite);
    my $scrollpos = $orf->start-10;
    if(!$self->{'vlength'}) {
	my $fw = $font_width - 1;
	my (undef, undef, $vlength ) = @{$self->{'canvas'}->allocation};
	$self->{'canv_length'} = $vlength;
	$self->{'vlength'} = int( $vlength / $fw );
    }
    $scrollpos = $orf->stop-$self->{'vlength'}+10 if($orf->frame < 0);

    if($end) {
	if($orf->frame < 0) {
	    $scrollpos = $orf->start-10;
	} else {
	    $scrollpos = $orf->stop-$self->{'vlength'}+10;
	}
    }
    
    &scroll( undef, $self, $scrollpos );
    my $y2 = $orf->frame () * - 31 + 125;
	
    if ($orf->frame () le 0) {
	$y2 += 31;
    } else {
	$y2 -= 31;
    }
    $self->{ 'canvas' }->scroll_to( 0, $y2 );
    $self->{'no_update'} = 0;
}

sub scroll_to_pos {
    my( $self, $pos ) = @_;
     &scroll( undef, $self, $pos );
}

sub scroll_to_orf {
    my( $self, $orf ) = @_;
    &scroll( undef, $self, $orf->start-10 );
}

sub world_to_sequence {
    my( $self, $xw ) = @_;
    my $start = $self->{'val'};
    my $length = $self->{'vlength'};
    my (undef, undef, $vlength ) = @{$self->{'canvas'}->allocation};
    my $x = $xw / $vlength * $length;
    return int($start + $x);
}

sub mark {
    my( $self, $start, $end, $frame ) = @_;
    $frame = 0 if( !defined $frame );
    $self->{ 'mark_start' } = $start;
    $self->{ 'mark_end' } = $end;
    $self->{ 'frame' } = $frame;
    $self->draw_mark;
}

sub get_marked_seq {
    my( $self ) = @_;
    return '' if($self->{'mark_start'} == -1);
    my $start = $self->{ 'mark_start' };
    my $end = $self->{ 'mark_end' };
    my $ret = substr( $self->{'sequence'}, $start, $end - $start );
    my $frame = $self->{'frame'};

    return reverse_complement($ret) if($frame);
    return $ret;
}

sub scroll {
	my( $adj, $self, $start ) = @_;
	$start = 0 if( $start < 0 );
	my $fw = $font_width - 1;
	if( !$self ) { return };
	if( !$self->{'sequence'} ) { return 0; }
	$self->{'no_update'} = 1;
	my (undef, undef, $vlength ) = @{$self->{'canvas'}->allocation};
	$self->{'canv_length'} = $vlength;
	$self->{'vlength'} = int( $vlength / $fw );

	my $val = ($adj) ? int($adj->get_value) : $start;
	if( ($val + $self->{'vlength'}) > length($self->{ 'sequence' }) ) {
	    $val = length($self->{ 'sequence' }) - $self->{'vlength'};
	}
	my $str = substr( $self->{ 'sequence' }, $val, $self->{ 'vlength' } );
	$self->{ 'val' } = $val;
	$self->{ 'fw' } = $fw;

	$self->{ 'orfs' }->destroy;
	$self->{ 'orfs' } = new Gnome::CanvasItem( $self->{ 'canvas' }->root,
						   'Gnome::CanvasGroup',
						   'x', 0,
						   'y', 0 );
	$self->{'mark'}->hide;
	&draw_mark( $self, $self->{'orfs'} );

	my $rstr = rev( $str );
	my $frame = $val % 3;
	my $sstart = ($scale - ($val % $scale)) * $fw;
	
	$self->{ 'seq' }->set( 'text', $str );
	$self->{ 'rseq' }->set( 'text', $rstr );
	$self->{ 'fr1' }->set( 'text', &aa_seq( $str, $frame ) );
	$self->{ 'fr2' }->set( 'text', &aa_seq( $str, $frame+1 ) );
	$self->{ 'fr3' }->set( 'text', &aa_seq( $str, $frame+2 ) );
	$self->{ 'fr-1' }->set( 'text', &aa_seq( $rstr, $frame, 1 ) );
	$self->{ 'fr-2' }->set( 'text', &aa_seq( $rstr, $frame+1, 1 ) );
	$self->{ 'fr-3' }->set( 'text', &aa_seq( $rstr, $frame+2, 1 ) );

	for( my $i = 0; $i < 6; $i++ ) {
	    $self->{ 'scale' }->[$i]->set( 'points', 
					   [$sstart+$i*$scale*$fw, 120, 
					    $sstart+$i*$scale*$fw, 130] );
	    $self->{ 'text' }->[$i]->set( 'x', $sstart+$i*$scale*$fw );
	    $val = sprintf("%d", $val);
	    $self->{ 'text' }->[$i]->set( 'text', $val-( $val % $scale ) + $scale*($i+1) );
	}
	
	$self->{ 'stop' }->destroy;
	$self->{ 'stop' } = new Gnome::CanvasItem( $self->{ 'canvas' }->root,
						   'Gnome::CanvasGroup',
						   'x', 0,
						   'y', 0 );
	while ($str =~ m/(TAA|TAG|TGA)/gi) {
	    my $x = pos $str;
	    $x -= 2;
	    new Gnome::CanvasItem( $self->{ 'stop' },
				   "Gnome::CanvasLine",
				   "points", [$x * $fw, 118, $x * $fw, 132 ],
				   "fill_color", "blue",
				   "width_units", 1.0
				   );
	}
	while ($rstr =~ m/(AAT|GAT|AGT)/gi) {
	    my $x = pos $rstr;
	    $x -= 2;
	    new Gnome::CanvasItem( $self->{ 'stop' },
				   "Gnome::CanvasLine",
				   "points", [$x * $fw, 118, $x * $fw, 132 ],
				   "fill_color", "blue",
				   "width_units", 1.0
				   );
	}


	my $end = $val + $self->{ 'vlength' };
	my $id = $self->{ 'contig' }->id;
	my $orfs = GENDB::orf->fetchbySQL("contig_id = $id AND (start <= $end AND stop >= $val)");
	my $iorfs = GENDB::Tools::UserConfig->get_parameter('ignored_orfs_in_sequence');
	foreach( @{ $orfs } ) {
	    next if(!$iorfs && $_->status == 2);
	    &drawOneOrf( $_, $val, $self->{ 'orfs' }, $self );
	}
        $self->{ 'scrollbar' }->slider_update;
        if( !$adj ) {
             $self->{ 'scrollbar' }->get_adjustment->set_value( $val );
        }
	$self->{'no_update'} = 0;
}

sub draw_mark {
    my( $self, $group ) = @_;
    return if( !defined($self->{'mark_start'}) );
    my $frame = 0;
    my $val = $self->{'val'};
    my $fw = $font_width - 1;
    my $x1 = ($self->{'mark_start'} - $val ) * $fw;
    my $x2 = ($self->{'mark_end'} - $val ) * $fw;
    my $y1 = $frame * - 31 + 125;
    my $y2 = $frame * - 31 + 125;
   
    $y1 -= 31;
    $y2 -= 31;

    $x1 = -5 if($x1 < -5);
    $x2 = $self->{'canv_length'} + 5 if($x2 > ($self->{'canv_length'} + 5));

    $y2 += 62 if($self->{'frame'});

    $self->{'mark'}->set( 'x1', $x1 );
    $self->{'mark'}->set( 'x2', $x2 );
    $self->{'mark'}->set( 'y1', $y2-7 );
    $self->{'mark'}->set( 'y2', $y2+7 );
    $self->{'mark'}->show;
}

sub drawOneOrf {
    my ($orf, $val, $group, $self) = @_;

    my $top=$self->{ 'scrolled_window' };
    my $gwin=$top->get_parent_window;
    my $stop = $orf->stop;
    my $start = $orf->start;
    my $frame = $orf->frame();

    $start += 3 if($frame < 0);
    $stop -= 3 if($frame > 0);

    my $fw = $font_width - 1;
    my $x1 = ($start - 1 - $val) * $fw;
    my $x2 = ($stop - $val) * $fw;
    my $y1 = $frame * - 31 + 125;
    my $y2 = $frame * - 31 + 125;
   
    if ($frame le 0) {
	$y1 += 31;
	$y2 += 31;
    }
    else {
	$y1 -= 31;
	$y2 -= 31;
    }
    
    $x1 = -10 if( $x1 < -10 );
    $x2 = $self->{'canv_length'} + 10 if( $x2 > $self->{'canv_length'} + 10 );

    my $item = new Gnome::CanvasItem( $group,
				      "Gnome::CanvasRect",
				      "x1", $x1,
				      "x2", $x2,
				      "y1", $y2-10,
				      "y2", $y2+10,
				      "outline_color", getColorForOrf($orf, $self),
				      "width_units", 3
				      );
    $item->signal_connect('event', sub {
	my($item, $orf, $event) = @_;
	if($event->{'type'} eq 'button_press') {
	    if($event->{'button'} == 1) {
		$self->hilite($orf, 0, 1);
	    } 
	    elsif($event->{'button'} == 2) { 
		$item->lower_to_bottom;
	    } 
	    else {
		$self->hilite($orf, 1, 1);
	    }
	    $self->{'canvas'}->signal_emit_stop_by_name('button_press_event');
	}
	elsif ($event->{'type'} eq 'enter_notify') {
	    my $on_orf_cursor = Gtk::Gdk::Cursor->new(50);
	    $gwin->set_cursor($on_orf_cursor);
	    Gtk->main_iteration while ( Gtk->events_pending );
	}
	elsif ($event->{'type'} eq 'leave_notify') {
	    my $normal_cursor = Gtk::Gdk::Cursor->new(68);
	    $gwin->set_cursor($normal_cursor);
	    Gtk->main_iteration while ( Gtk->events_pending );
	};
	return 0;
    }, $orf);
}

sub reload_contig {
    my($self) = @_;
    if(defined $self->{ 'sequence' } && defined $self->{'contig'}) {
	$self->{'contig'} = GENDB::contig->init_id($self->{'contig'}->id);
	$self->set_contig($self->{'contig'});
    }
}

sub set_contig {
	my( $self, $contig ) = @_;
	$self->{ 'contig' } = $contig;
	$self->{ 'mark_start' } = undef;
	return if(!defined $contig);
	my $seq = $contig->sequence;
	$seq =~ tr/A-Z/a-z/;
	$self->{ 'sequence' } = $seq;
	my $len = length( $seq ) - $self->{ 'vlength' } / ($font_width/2) + 5;
	my $adj = new Gtk::Adjustment( 0, 0, $len, 1, 10, 1 );
	$adj->signal_connect( 'value_changed', \&scroll, $self );
	$self->{ 'adj'} = $adj;
	$self->{ 'scrollbar' }->set_adjustment( $adj );
	$self->{ 'seq' }->set( 'text', 
		substr( $seq, 0, $self->{ 'vlength' } ));
	$self->{ 'rseq' }->set( 'text', 
		rev(substr( $seq, 0, $self->{ 'vlength' } )) );
	$self->{ 'scrollbar' }->slider_update;
	scroll( undef, $self, 0 );
}

sub set_visible_size {
	my( $self, $length ) = @_;
	my $font_width = Gtk::Gdk::Font->
		load( $font )->
			string_width( "t" );
	$self->{ 'vlength' } = $length;
}

sub rev {
	$_ = shift;
	$_ =~ tr/ATCGatcg/TAGCtagc/;
	return $_;
}

sub getColorForOrf {
    my ($orf, $self) = @_;
    
    if ( $self->{ 'hilited_orf' } eq $orf->name ) {
	return &Utils::get_color_for_orf( $orf, 'selected' );
    }
    return &Utils::get_color_for_orf( $orf, 'normal' );
}

1;
