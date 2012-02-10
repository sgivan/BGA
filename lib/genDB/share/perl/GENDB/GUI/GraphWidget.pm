package GraphWidget;

($GENDB::GUI::GraphWidget::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);
my $PRINT = 1;

use GENDB::GENDB_CONFIG;
use Gtk;
use strict;

my $old_motion_x = 0;
my $old_motion_y = 0;
my @col;
my @cols;
my @geo;
my $white_color;
my $gray = undef;
my $red;
my $black;
my $r_m_pos_x = undef;
my $r_m_pos_y = undef;
my $plus = 1;

#####################################################
###                                               ###
### the main drawing module for statistics-widget ###
###                                               ###
#####################################################

sub new {
    my ($self ) = @_;
    my %self;
    my $window = new Gtk::VBox( 0, 0 );
    my $topbox = new Gtk::VBox( 0, 0 );
    my $actionarea = new Gtk::HBox( 0, 0 );
    my $darea  = new Gtk::DrawingArea;  
    my $mbar = new Gtk::MenuBar;
    
    $darea->signal_connect( 'configure_event',       \&draw,   \%self );
    $darea->signal_connect( 'expose_event',          \&expose, \%self );
    $darea->signal_connect( 'button_release_event',  \&mpos,   \%self );
    $darea->signal_connect( 'button_press_event',    \&rpos,   \%self );
    $darea->signal_connect( 'motion_notify_event',   \&move,   \%self );
    $darea->signal_connect( 'leave_notify_event',    \&move,   \%self );
    $darea->set_events( [ 'button_press_mask', 
			  'button_release_mask',
			  'pointer_motion_mask', 
			  'leave_notify_mask' ] );

    my $vbox = new Gtk::VBox( 1, 0 );
    my $dbox = new Gtk::HBox( 0, 0 );
    my $bbox = new Gtk::HBox( 1, 0 );
    my $ubox = new Gtk::HBox( 1, 0 );
    my $toolbar = new Gtk::HBox( 1, 1 );
    my $adjy = new Gtk::Adjustment( 0.0, 0.0, 100.0, 0.1, 1.0, 100 );
    my $adjx = new Gtk::Adjustment( 0.0, 0.0, 100.0, 0.1, 1.0, 100 );
    $adjx->signal_connect( 'value_changed', \&slidex, \%self );
    $adjy->signal_connect( 'value_changed', \&slidey, \%self );

    my $adj1 = new Gtk::Adjustment( 0, 0, 1, 1, 1, 1 );
    my $adj2 = new Gtk::Adjustment( 0, 0, 1, 1, 1, 1 );
    my $y_scrollbar = new Gtk::VScrollbar( $adjy );
    my $x_scrollbar = new Gtk::HScrollbar( $adjx );
    
    $x_scrollbar->set_update_policy( 'continuous' );
    $y_scrollbar->set_update_policy( 'continuous' );
    
    $vbox->pack_start( $toolbar, 1, 1, 0 );
    $dbox->pack_start( $darea, 1, 1, 1 );
    $dbox->pack_end( $y_scrollbar, 0, 0, 0 );

    my $scroller = new Gtk::Viewport( $adj1, $adj2 );
    $scroller->add( $dbox );

    $window->pack_start( $topbox, 1, 1, 1 );
    $window->pack_end( $actionarea, 0, 0, 0 );

    $topbox->pack_end( $x_scrollbar, 0, 0, 0 );
    $topbox->pack_end( $scroller, 1, 1, 2 );
    $actionarea->pack_start_defaults( $vbox );

    $window->set_usize( 800, 600 );
    $self{ 'menubar' } = $mbar;
    $self{ 'window' } = $window;
    $self{ 'vbox' } = $topbox;
    $self{ 'actionarea' } = $actionarea;
    $self{ 'drawer' } = $darea;
    $self{ 'toolbar' } = $toolbar;
    $self{ 'buttons' } = [];
    $self{ 'data' } = [];
    $self{ 'graph' } = [];
    $self{ 'buffer' } = undef;
    $self{ 'help_line' } = 1; 
    $self{ 'xzoom' } = 0;
    $self{ 'yzoom' } = 0;
    $self{ 'y_rel' } = 1;
    $self{ 'x_rel' } = 1;

    $self{ 'xadj' } = $adjx;
    $self{ 'yadj' } = $adjy;
    $self{ 'xscroller' } = $x_scrollbar;
    $self{ 'yscroller' } = $y_scrollbar;

    $self{ 'x_start' } = 0;
    $self{ 'y_start' } = 0;
    $self{ 'x_end' } = 1;
    $self{ 'y_end' } = 1;

    bless \%self;
    return \%self;
}

sub reset {
    my( $self ) = @_;
    $self->{ 'x_start' } = 0;
    $self->{ 'y_start' } = 0;
    $self->{ 'x_end' } = 1;
    $self->{ 'y_end' } = 1;
    &change_zoom( $self, 0, 1 );
    &repaint( $self );
}

sub remove_help_line {
    my( $self ) = @_;
    $self->{ 'help_line' } = 0;
}

sub slidex {
    my( $adj, $self ) = @_;
    $self->{ 'x_start' } = ( $adj->get_value / 100 );
    $self->{ 'x_end' } = ( $self->{ 'x_start' } + ( $adj->page_size / 100 ) );
    &change_zoom( $self );
    &repaint( $self );  
}

sub slidey {
    my( $adj, $self ) = @_;
    my $v = $adj->get_value;
    my $p = $adj->page_size;
    my $start = -1 * ($p + $v - 100) / 100;
    my $end = $start + ($p/100);
    $self->{ 'y_start' } = $start;
    $self->{ 'y_end' }   = $end;
    &change_zoom( $self );
    &repaint( $self );
}

sub change_zoom {
    my( $self ) = @_;
    my @data = @{ $self->{ 'data' } };
    foreach my $datum ( @data ) {
	if( defined( $datum ) ) {
	    $datum->set_zoom( $self->{ 'x_start' }, $self->{ 'x_end' } );
	}
    }

    my $xzoom = ( $self->{ 'x_end' } - $self->{ 'x_start' } ) * 100;
    my $yzoom = ( $self->{ 'y_end' } - $self->{ 'y_start' } ) * 100;

    $self->{ 'xadj' }->page_size( $xzoom );
    $self->{ 'yadj' }->page_size( $yzoom );
    $self->{ 'xadj' }->set_value( $self->{ 'x_start' } * 100 );
    $self->{ 'yadj' }->set_value( 100-($self->{ 'y_start' } * 100)-$yzoom );

    $self->{ 'xscroller' }->slider_update;
    $self->{ 'yscroller' }->slider_update;

    $self->{ 'data' } = \@data;
}

sub move {
    my( $darea, $self, $event ) = @_;
    my $event_area;
    $event_area = $event->{ 'area' };
    if( !$r_m_pos_x && $self->{ 'help_line' } ) {
	my $buffer = $self->{ 'buffer' };
	$darea->window->draw_pixmap( $darea->style->fg_gc( 'selected' ),
				     $buffer,
				     $old_motion_x,
				     0,
				     $old_motion_x,
				     0,
				     $old_motion_x,
				     $geo[3] );
	if( $event->{ 'type' } eq 'motion_notify' ) {
	    $old_motion_x = $event->{ 'x' };
	    $darea->window->draw_line( $gray, $old_motion_x, 0, $old_motion_x, $geo[3] );
	}
    } elsif( $event->{ 'state' } == 256 ) {
	my $buffer = $self->{ 'buffer' };
	$darea->window->draw_pixmap( $darea->style->fg_gc( 'selected' ),
				     $buffer,
				     $r_m_pos_x,
				     $r_m_pos_y,
				     $r_m_pos_x,
				     $r_m_pos_y,
				     $old_motion_x + 1,
				     $old_motion_y + 1 );
	if( $event->{ 'x' } > $r_m_pos_x && $event->{ 'y' } > $r_m_pos_y ) {
	    $old_motion_x = $event->{ 'x' } - $r_m_pos_x;
	    $old_motion_y = $event->{ 'y' } - $r_m_pos_y;
	    $darea->window->draw_rectangle( $gray, 0, $r_m_pos_x, $r_m_pos_y, $old_motion_x, $old_motion_y );
	}
    }
}

sub zoom {
    my( $self, $io ) = @_;

    my $x_start = $self->{ 'x_start' };
    my $x_end = $self->{ 'x_end'   };
    $x_start += $io * 0.01;
    $x_end   -= $io * 0.01;
    if( $x_start < 0 ) { $x_start = 0; }
    if( $x_end   > 1 ) { $x_end   = 1; }
    if( $x_end > $x_start ) {
	$self->{ 'x_start' } = $x_start;
	$self->{ 'x_end'   } = $x_end;
    }

    my $y_start = $self->{ 'y_start' };
    my $y_end = $self->{ 'y_end'   };
    $y_start += $io * 0.01;
    $y_end   -= $io * 0.01;
    if( $y_start < 0 ) { $y_start = 0; }
    if( $y_end   > 1 ) { $y_end   = 1; }
    if( $y_end > $y_start ) {
	$self->{ 'y_start' } = $y_start;
	$self->{ 'y_end'   } = $y_end;
    }

    &change_zoom( $self );
    &repaint( $self );
}


sub rpos {
    my( $darea, $self, $event ) = @_;
    $r_m_pos_x = $event->{ 'x' };
    $r_m_pos_y = $event->{ 'y' };
}

sub mpos {
    my( $darea, $self, $event ) = @_;
    $self->{ 'xmpos' } = undef;
    if( $event->{ 'button' } == 1 && $r_m_pos_x == $event->{ 'x' } ) {
	my $ep = $event->{ 'x' };  
	$self->{ 'xmpos' } = &rel_m_pos( $self, $ep );
	if( $self->{ 'xmpos' } < 0 || $self->{ 'xmpos' } >= 1 ) {
	    $self->{ 'xmpos' } = undef;
	}
    } elsif( $event->{ 'button' } == 1 && $r_m_pos_x != $event->{ 'x' } ) {
	my $tmp_x_start = $self->{ 'x_start' };
	my $tmp_y_start = $self->{ 'y_start' };
	my $y_end = $self->{ 'y_end' };
	my $x_zoom = $self->{ 'x_end' } - $self->{ 'x_start' };
	my $y_zoom = $self->{ 'y_end' } - $self->{ 'y_start' };
	my $mitte = ($self->{ 'y_end' } + $self->{ 'y_start' }) / 2;
	my ( $x_start, $x_end, $y_start, $y_end );

	$x_start = $tmp_x_start + (($r_m_pos_x-25) / ($geo[2]-30) * $x_zoom);
	$x_end   = $tmp_x_start + (($event->{ 'x' }-25) / ($geo[2]-30) * $x_zoom);
	$y_end   = ($tmp_y_start + (($r_m_pos_y-25) / ($geo[3]-50) * $y_zoom));
	$y_end   = $mitte + ( $mitte - $y_end );
	$y_start = ($tmp_y_start + (($event->{ 'y' }-25) / ($geo[3]-50) * $y_zoom));
	$y_start = $mitte + ( $mitte - $y_start );
	if( $x_start > 1 ) { $x_start = 1; }
	if( $x_end   > 1 ) { $x_end   = 1; }
	if( $y_start > 1 ) { $y_start = 1; }
	if( $y_end   > 1 ) { $y_end   = 1; }
	if( $x_start < 0 ) { $x_start = 0; }
	if( $x_end   < 0 ) { $x_end   = 0; }
	if( $y_start < 0 ) { $y_start = 0; }
	if( $y_end   < 0 ) { $y_end   = 0; }

	if( $x_end > $x_start && $y_end > $y_start ) {
	    $self->{ 'x_start' } = $x_start;
	    $self->{ 'x_end'   } = $x_end;
	    $self->{ 'y_start' } = $y_start;
	    $self->{ 'y_end'   } = $y_end;
	}
	
	&change_zoom( $self );
    }
    $r_m_pos_x = undef;
    $r_m_pos_y = undef;
    &repaint( $self );
}

sub get_mouse {
    my( $self, $event ) = @_;
    my $tmp_x_start = $self->{ 'x_start' };
    my $tmp_y_start = $self->{ 'y_start' };
    my $y_end = $self->{ 'y_end' };
    my $x_zoom = $self->{ 'x_end' } - $self->{ 'x_start' };
    my $y_zoom = $self->{ 'y_end' } - $self->{ 'y_start' };
    my $mitte = ($self->{ 'y_end' } + $self->{ 'y_start' }) / 2;
    my $xe = $tmp_x_start + (($event->{ 'x' }-25) / ($geo[2]-30) * $x_zoom);
    my $ys = ($tmp_y_start + (($event->{ 'y' }-25) / ($geo[3]-50) * $y_zoom));
    $mitte += $mitte - $ys;
    if( $ys > 1 ) { $ys = "."; }
    if( $xe > 1 ) { $xe = "."; }
    if( $ys < 0 ) { $ys = ":"; }
    if( $xe < 0 ) { $xe = ":"; }

    return $xe." <=> ".$mitte."  ".$self->{ 'x_start' }." - ".$self->{ 'y_start' };
}

sub set_mode {
    my( $self, $x, $y ) = @_;
    $self->{ 'y_rel' } = $y % 2;
    $self->{ 'x_rel' } = $x % 2;
    &repaint( $self );
}

sub set_mpos {
    my( $self, $new_mpos ) = @_;
    $self->{ 'xmpos' } = $new_mpos;
    &repaint( $self );
}

sub gdata {
    my( $self, $id ) = @_;
    return $self->{ 'data' }->[$id];
}

sub change_id {
    my( $self, $id, $data ) = @_;
    my @data = @{ $self->{ 'data' } };
    $data[$id] = $data;
    $self->{ 'data' } = \@data;
}

sub info_position {
    my( $self ) = @_;
    return $self->{ 'xmpos' };
}

sub rel_m_pos {
    my( $self, $mpos )= @_;
    my $x_zoom = $self->{ 'x_end' } - $self->{ 'x_start' };
    my $x = $geo[2] - 30;
    my $mp = $mpos - 25;
    my $pro = $mp / $x;
    $pro = $self->{ 'x_start' } + ( $pro * $x_zoom );
    return $pro;
}

sub remove_selected {
    my( $self ) = @_;
    my @bs = @{ $self->{ 'data' } };
    for( my $b = 0; $b <= $#bs; $b++ ) {
	if( $bs[$b] && $bs[$b]->active ) {
	    $self->{ 'toolbar' }->remove( $bs[$b]->button );
	    $bs[$b] = undef;
	}
    }
    $self->{ 'toolbar' }->show;
    $self->{ 'data' } = \@bs;
    &repaint( $self );
}

sub remove_by_id {
    my( $self, $id ) = @_;
    $id++;
    my @bs = @{ $self->{ 'data' } };

    for( my $b = 0; $b <= $#bs; $b++ ) {
	if( $bs[$b] && $bs[$b]->id == $id ) {
	    $self->{ 'toolbar' }->remove( $bs[$b]->button );
	    $bs[$b] = undef;
	    last;
	}
    }
    $self->{ 'toolbar' }->show;
    $self->{ 'data' } = \@bs;
    &repaint( $self );
}

sub window {
    my( $self ) = @_;
    return $self->{ 'drawer' }->window;
}

sub widget {
    my( $self ) = @_;
    return $self->{ 'window' };
}

sub menubar {
    my( $self ) = @_;
    return $self->{ 'menubar' };
}

sub mouse_signal_connect {
    my( $self, $signal, $func, @data ) = @_;
    $self->{ 'drawer' }->signal_connect( $signal, $func, $self, @data );
}

sub show {
    my( $self ) = @_;
    $self->{ 'window' }->show_all;
}

sub add_gdata {
    my( $self, $gdata ) = @_;
    my @data = @{ $self->{ 'data' } };
    my $id = -1;
    for( $id = 0; $id <= $#data+1; $id++ ) {
	if( !$data[$id] ) {
	    $gdata->id( $id+1 );
	    $data[$id] = $gdata;
	    last;
	}
    }    
    $data[$id]->button->signal_connect( 'clicked', \&signal_repaint, $self );
    $data[$id]->set_zoom( $self->{ 'x_start' }, $self->{ 'x_end' } );
    my $tt = new Gtk::Tooltips;
    $tt->set_tip( $data[$id]->button, "left Click: toggle view\nright Click: Properties" );
    $self->{ 'toolbar' }->pack_start( $data[$id]->button, 1, 0, 0 );
    $self->{ 'data' } = \@data;
    &repaint( $self );
    return $id;
}

sub signal_repaint {
    my( $handler, $self ) = @_;
    &repaint( $self );
}

sub repaint {
    my( $self ) = @_;
    &draw( $self->{ 'drawer' }, $self, 0 );
}

sub create_colors {
    my( $self ) = @_;
    my $darea = $self->{ 'drawer' };
    my $red_color = $darea->window->get_colormap->color_alloc( { red => 65000,  green => 0, blue => 0 } );
    $white_color = $darea->window->get_colormap->color_alloc( { red => 65000, green => 65000, blue => 65000 } );
    my $black_color = $darea->window->get_colormap->color_alloc( { red => 0, green => 0, blue => 0 } );
    my $color = $darea->window->get_colormap->color_alloc( { red => 40000, green => 40000, blue => 40000 } );

    $gray = new Gtk::Gdk::GC ( $darea->window );
    $gray->set_foreground( $color );
    $red = new Gtk::Gdk::GC ( $darea->window );
    $red->set_foreground( $red_color );
    $black = new Gtk::Gdk::GC ( $darea->window );
    $black->set_foreground( $black_color );
}

sub expose {
    my ( $darea, $self, $event ) = @_;

    my $event_area;
    
    $event_area = $event->{ 'area' };

    my $buffer = $self->{ 'buffer' };

    $darea->window->draw_pixmap(
        $darea->style->fg_gc( 'normal' ),
        $buffer,
        $event_area->[0],
        $event_area->[1],
        $event_area->[0],
        $event_area->[1],
        $event_area->[2],
        $event_area->[3]
    );
}

sub draw_y_axis {
    my( $buffer, $x0, $y0, $start_y, $end_y, $max_y, $pr, $x_size, $y_size ) = @_;
    my $pry = '';
    if( $pr ) { $pry = '%'; }
    my $y_ax_start = $start_y * $max_y;
      
    my $zoom_y = $end_y - $start_y;
    $max_y *= $zoom_y;
    
    my $y_scale = 10;
    while( $y_scale < $max_y ) {
	$y_scale *= 10;
    }
    $y_scale /= 10;
    my $y_scale_1 = $y_scale / 10;
    my $step_s_y = ( $y_scale / $max_y ) * ( $y_size - 50 );
    my $step_s_y_1 = ( $y_scale_1 / $max_y ) * ( $y_size - 50 );
    my $new_y = $y0;
    my $font = load Gtk::Gdk::Font $SMALL_FONT;
    
    my $label;
    
    $buffer->draw_line( $black, $x0, $y0+5, $x0, 5 );

    my $z = 0;
    while( $new_y > 0 ) {
	$buffer->draw_line( $black, $x0, $new_y, $x0 - 5, $new_y );
	$new_y = $y0 - ( $z * $step_s_y_1 );
	$z++;
    }

    $z = 0; $new_y = $y0; my $count = 0;
    $y_ax_start = int( $y_ax_start );
    while( ($y_ax_start - $count) % $y_scale != 0 ) { $count++; }
    my $count2 = int( $count / $y_scale_1 );

    while( $new_y > 0 ) { 
	$label = ($y_ax_start - $count) + $y_scale * $z;
	$buffer->draw_text( $font, $black, $x0-20, $y0 - ( $z * $step_s_y ) + ($count2 * $step_s_y_1) + 10, "$label".$pry."                    ", 10 );
	$new_y = $y0 - ( $z * $step_s_y ) + ($count2 * $step_s_y_1);
	$buffer->draw_line( $black, $x0, $new_y, $x0 - 10, $new_y );
	$z++;
    }
}

sub draw_x_axis {
    my( $buffer, $x0, $y0, $start_x, $end_x, $max_x, $pr, $x_size, $y_size ) = @_;
    my $font = load Gtk::Gdk::Font $SMALL_FONT;
    my $label;
    my $x_ax_start = $start_x * $max_x;
    
    my $zoom_x = $end_x - $start_x;
    $max_x *= $zoom_x;

    my $x_scale = 10;
    while( $x_scale < $max_x ) {
	$x_scale *= 10;
    }
    $x_scale /= 10;
    my $x_scale_1 = $x_scale / 10;
    my $step_s_x = ( $x_scale / $max_x ) * ( $x_size - 0 );
    my $step_s_x_1 = ( $x_scale_1 / $max_x ) * ( $x_size - 0 );
    my $new_x = $x0;
    my $z = 1;

    while( $new_x < $x_size + 50 ) {
	$buffer->draw_line( $black, $new_x, $y0, $new_x, $y0 + 5 );
	$new_x = $x0 + ( $z * $step_s_x_1 );
	$z++;
    }

    my $prx = '';
    if( $pr ) { $prx = '%'; }
    $z = 0;
    my $count = 0;

    $x_ax_start = int( $x_ax_start );
    while( ($x_ax_start - $count) % $x_scale != 0 ) { $count++; }
    my $count2 = int( $count / $x_scale_1 );
    
    $new_x = $x0 - ($count2 * $step_s_x_1);
    while( $new_x < $x_size + 50 ) { 
	$label = ($x_ax_start - $count) + $x_scale * $z;
	$z++;
	$buffer->draw_text( $font, $black, $new_x - 10, $y0 + 20, "$label".$prx."             ", 10 );
	$buffer->draw_line( $black, $new_x, $y0, $new_x, $y0 + 10 );
	$new_x = $x0 + ( $z * $step_s_x ) - ($count2 * $step_s_x_1);
    }
    $buffer->draw_line( $black, $x0-5, $y0, $x_size+25, $y0 );
}

sub draw {
    my( $darea, $self, $event ) = @_;
    if( !$gray ) { &create_colors( $self ); }
    my @data = @{ $self->{ 'data' } };

    @geo = $darea->window->get_geometry;

    my( $x_size, $y_size ) = ( $geo[2], $geo[3] );
    my( $x0, $y0 ) = ( 25, $y_size - 25 );

    my $drawer = $darea->window;

    Gtk::Gdk->flush;
    
    my $buffer = new Gtk::Gdk::Pixmap( $darea->window, $geo[2], $geo[3], -1 );

    $buffer->draw_rectangle(
        $darea->style->white_gc,
        1,
        $geo[0],
        $geo[1],
        $geo[2],
        $geo[3]
    );

    $x_size -= 30;
    
    my( $max_x, $max_y, $x_ax_max ) = ( 0, 0, 0 );

    foreach my $draw ( @data ) {
	if( $draw && $draw->active ) {
	    if( $draw->length > $max_x ) { $max_x = $draw->length; } 
	    if( $draw->max > $max_y ) { $max_y = $draw->max; } 
	    if( $draw->all_length > $x_ax_max ) { $x_ax_max = $draw->all_length; }
	}
    }
    
    if( !$max_y ) { $max_y = 1; }
    if( !$max_x ) { $max_x = 1; }
    if( !$x_ax_max ) { $x_ax_max = 1; }

    my $x_scale = 10;
    while( $x_scale < $max_x ) {
	$x_scale *= 10;
    }
    $x_scale /= 10;
    my $x_scale_1 = $x_scale / 10;

    my $y_len = $self->{ 'y_end' } - $self->{ 'y_start' };
    my $y_start = ($geo[3] - 50) * $self->{ 'y_start' };
   
    foreach my $draw ( @data ) {
	if( $draw && $draw->active ) {
	    my @d = $draw->data;
	    my( $old_x, $old_y ) = ( $x0, 0 );
	    my $step = 1;

	    if( $draw->max ) {
		$old_y = $y0 - int( ( $d[0] / $draw->max ) * ( $y_size - 50 ) );
		if( $self->{ 'x_rel' } ) { 
		    $step = $x_size / $draw->length;
		} else {
		    $step = $x_size / $max_x;
		}
	    }

	    for( my $i = 0; $i <= $#d; $i++ ) {
		my $new_x = $x0 + ( $i * $step );
		my $wert = $d[$i];
		if( $self->{ 'y_rel' } ) {
		    $wert = int( $d[$i] / $draw->max * $max_y );
		}
		my $new_y = (int( ( $wert / $max_y ) * ( $y_size - 50 ) ) / $y_len) - ($y_start / $y_len);
		$buffer->draw_line( $draw->color, $old_x, $old_y, $new_x, $y0-$new_y);
		$old_x = $new_x;
		$old_y = $y0-$new_y;
	    }
	}
    }

    if( $self->{ 'y_rel' } ) { $max_y = 100; }
    if( $self->{ 'x_rel' } ) { $x_ax_max = 100; }

    &draw_y_axis( $buffer, $x0, $y0, $self->{ 'y_start'}, $self->{ 'y_end' }, $max_y, $self->{ 'y_rel' }, $x_size, $y_size );
    &draw_x_axis( $buffer, $x0, $y0, $self->{ 'x_start'}, $self->{ 'x_end' }, $x_ax_max, $self->{ 'x_rel' }, $x_size, $y_size );

    if( $self->{ 'xmpos' } ) {
	my $xmp = $self->{ 'xmpos' } - $self->{ 'x_start' };
	$xmp /= ( $self->{ 'x_end' } - $self->{ 'x_start' } );
	$xmp *= ( $geo[2] - 30 );
	$xmp += 25;
	$buffer->draw_line($red, $xmp, 0, $xmp, $y_size );
    }

    $darea->window->draw_pixmap(
        $darea->style->fg_gc( 'normal' ),
        $buffer,
	0, 
        0,
        0,
	0,
        $geo[2],
        $geo[3]
    );

    $self->{ 'buffer' } = $buffer;
}

1;

