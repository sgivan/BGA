package XYPlot;

($GENDB::GUI::XYPlot::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use GENDB::GENDB_CONFIG;

use strict;
use Gtk;
use Gnome;

use vars( qw(@ISA) );
@ISA = qw( Gtk::VBox );

my %plot_data;
my @spot_classes;
my @size = (-9999, 9999, -9999, 9999);
my $zoom = 1;
my $xskal = 0.00001;
my $yskal = 0.00001;

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new( 0, 0 );

    %plot_data = ();
    @spot_classes = ();
    @size = (-9999, 9999, -9999, 9999);

    my $canvas = new Gnome::Canvas;
    my $scroller = new Gtk::ScrolledWindow;
    my $status = new Gtk::Statusbar;
    my $progress = new Gtk::ProgressBar;
    my $sbox = new Gtk::HBox( 0, 0 );
    my $adj = new Gtk::Adjustment(1, 0.01, 10, 0.01, 1, 0);
    my $zoom = new Gtk::HScale($adj);
    $scroller->set_policy( 'automatic', 'automatic' );
    $scroller->get_vadjustment->step_increment( 10 );
    $scroller->get_hadjustment->step_increment( 10 );
    $scroller->add( $canvas );
    $progress->set_format_string( "%p%%" );
    $self->{'canvas'} = $canvas;
    $sbox->pack_start_defaults( $status );
    $sbox->pack_end( $progress, 0, 0, 0 );
    $self->pack_end( $sbox, 0, 0, 0 );
    $self->pack_end($zoom, 0, 0, 0);
    $self->pack_start_defaults( $scroller );
    $self->{'status'} = $status;
    $self->{'progress'} = $progress;
    $self->{'mode'} = 1;
    $self->{'sw'} = 1;
    $self->{'xabst'} = 1;
    $self->{'yabst'} = 1;
    $self->{'outline'} = 0;
    $self->{'diagonale_m'} = 1;
    $self->{'diagonale_b'} = 0;
    $self->{'tic_text_x'} = 1;
    $self->{'tic_text_y'} = 1;

    my $style = new Gtk::Style;
    $style->bg('normal', Gtk::Gdk::Color->parse_color('white'));
    $canvas->set_style($style);

    $adj->signal_connect('value_changed', sub {
	$zoom = $adj->get_value;
	$canvas->set_pixels_per_unit( $zoom );
    });

    return bless $self;
}

sub set_background_color {
    my($self, $color) = @_;

    my $style = new Gtk::Style;
    $style->bg('normal', Gtk::Gdk::Color->parse_color('white'));
    $self->{'canvas'}->set_style($style);
}

sub show_tic_text {
    my($self, $showx, $showy) = @_;
    $self->{'tic_text_x'} = $showx;
    $self->{'tic_text_y'} = $showy;
}

sub set_description {
    my( $self, $xachse, $yachse ) = @_;
    $self->{ 'xachse' } = $xachse;
    $self->{ 'yachse' } = $yachse;
}

sub show_all_plots {
    my( $self ) = @_;
    foreach( keys(%plot_data) ) {
	if( defined( $plot_data{$_}{'item'} ) ) {
	    $plot_data{$_}{'item'}->show;
	}
    }
    $self->{'mode'} = 1;
}

sub scale_width {
    my( $self ) = @_;
    return ( $self->{'xabst'}, $self->{'yabst'} );
}

sub show_diag {
    my( $self, $show ) = @_;
    $self->{'show_diag'} = $show;
    $self->create_diagonale if($show);
    $self->{'linie'}->destroy if( defined( $self->{'linie'} ) && !$show );
}

sub set_scale_width {
    my( $self, $xsc, $ysc ) = @_;
    $self->{'xabst'} = $xsc;
    $self->{'yabst'} = $ysc;
    &plot( $self );
}

sub set_spot_size {
    my( $self, $size ) = @_;
    $self->{'sw'} = $size;
    &plot( $self );
}

sub mark {
    my( $self, $what, $name ) = @_;
    if( $what eq 'Orf' || $what eq 'Spot' ) {
	foreach( keys( %plot_data ) ) {
	    if( !($_ =~ $name) && defined( $plot_data{$_}->{'item'} ) ) {
		$plot_data{$_}->{'item'}->hide;
		$plot_data{$_}->{'item'}->set( 'fill_color', 'red' );
		$plot_data{$_}->{'color'} = 'red';
	    } elsif( defined( $plot_data{$_}->{'item'} ) ) {
		$plot_data{$_}->{'item'}->set( 'fill_color', 'yellow' );
		$plot_data{$_}->{'color'} = 'yellow';
	    }
	}
    } elsif( $what eq 'Class' ) {
	foreach( keys( %plot_data ) ) {
	    if( defined( $plot_data{$_}->{'item'} ) ) {
		if( !($plot_data{$_}->{'class'} eq $name) ) {
		    $plot_data{$_}->{'item'}->hide;
		    $plot_data{$_}->{'item'}->set( 'fill_color', 'red' );
		    $plot_data{$_}->{'color'} = 'red';
		} else {
		    $plot_data{$_}->{'item'}->set( 'fill_color', 'yellow' );
		    $plot_data{$_}->{'color'} = 'yellow';
		}
	    }
	}
    } elsif( $what eq 'Description' ) {
	foreach( keys( %plot_data ) ) {
	    if( defined( $plot_data{$_}->{'item'} ) ) {
		if( !($plot_data{$_}->{'desc'} =~ /.*$name.*/ ) ) {
		    $plot_data{$_}->{'item'}->hide;
		    $plot_data{$_}->{'item'}->set( 'fill_color', 'red' );
		    $plot_data{$_}->{'color'} = 'red';
		} else {
		    $plot_data{$_}->{'item'}->set( 'fill_color', 'yellow' );
		    $plot_data{$_}->{'color'} = 'yellow';
		}
	    }
	} 
    }
    $self->{'mode'} = 1;
}

sub outlined_spots {
    my( $self, $outline ) = @_;
    $self->{'outline'} = $outline;
}

sub set_status {
    my( $self, $message ) = @_;
    $self->{'status'}->push( 1, $message );
}

sub init_progress {
    my( $self, $init_val ) = @_;
    $self->{'progress'}->set_adjustment( new Gtk::Adjustment( 0, 1, $init_val, 0, 0, 0 ) );
    $self->{'progress'}->set_show_text(1);
    $self->window->set_cursor( new Gtk::Gdk::Cursor( 150 ) );
}

sub update_progress {
    my( $self, $val ) = @_;
    Gtk->main_iteration while( Gtk->events_pending );
    $self->{'progress'}->set_value( $val );
}

sub end_progress {
    my( $self ) = @_;
    $self->{'progress'}->set_show_text(0);
    $self->{'progress'}->set_value(0);
    $self->window->set_cursor( new Gtk::Gdk::Cursor( 68 ) );
}

sub set_data {
    my( $self, $plot, $size, $class ) = @_;
    %plot_data = %{$plot};

    if(ref $size eq 'ARRAY') {
	@size = @{$size};
    } else {
	@size = ($size->{'xmax'}, $size->{'xmin'}, 
		 $size->{'ymax'}, $size->{'ymin'});
    }
    @spot_classes = @{$class} if( defined($class) );

    my $xlen = $size[0] + abs($size[1]);
    my $ylen = $size[2] + abs($size[3]);


    $xskal *= 10 while( $xskal*($xlen) < 500 );
    $yskal *= 10 while( $yskal*($ylen) < 500 );
}

sub set_size {
    my($self, $size) = @_;

    if(ref $size eq 'ARRAY') {
	@size = @{$size};
    } elsif(ref $size eq 'HASH') {
	@size = ($size->{'xmax'}, $size->{'xmin'}, 
		 $size->{'ymax'}, $size->{'ymin'});
    }
}

sub zoom {
    my( $self, $val ) = @_;
    my $canvas = $self->{'canvas'};
    $val = 1.1 if( $val == 1 );
    $val = 0.9 if( $val == -1 );
	
    $zoom *= $val;
    $zoom = 1 if( $zoom <= 0 ); 
    $canvas->set_pixels_per_unit( $zoom );
}

sub spot_selection_connect {
    my( $self, $sub_ref, @data ) = @_;
    $self->{'sel_ref'} = $sub_ref;
    $self->{'sel_data'} = \@data;
}

sub get_class_members {
    my( $self, $class ) = @_;
    $class = $self->{'last_class'} if( !defined( $class ) );
    return $spot_classes[$class];
}

sub plot {
    my( $self ) = @_;

    my $xabst = $xskal * $self->{'xabst'};
    my $yabst = $yskal * $self->{'yabst'};

    my $ix = 0;
    $ix -= $xabst while( $ix > $size[1] );
    my $iy = 0;
    $iy -= $xabst while( $iy > $size[3] );

    my $max = $size[2] * $yabst + 50;

    $self->{'cgroup'}->destroy if( defined( $self->{'cgroup'} ) );
    $self->{'cgroup'} = new Gnome::CanvasItem( $self->{'canvas'}->root, "Gnome::CanvasGroup",
					       'x', 0, 'y', 0 );

    my $xskaln = $xskal;
    my $s1 = $size[1];
    #$s1 = 0 if( $s1 > 0 );
    $xskaln = 100 if( $xskaln > 100 );

    my $yskaln = $yskal;
    my $s3 = $size[3];
    #$s3 = 0 if( $s3 > 0 );
    $yskaln = 100 if( $yskaln > 100 );

    my $yline = ($s3 > 0) ?  $s3 * $yabst - 10: 0;
    my $xline = ($s1 > 0) ?  $s1 * $xabst - 10: 0;

    for( my $i = $ix; $i < $size[0]; $i += 100/$xskaln ) {
	new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasLine",
			       'points', [$i * $xabst, $max-$yline-5, $i * $xabst, $max-$yline+2],
			       'fill_color', 'black' ) if ($i > $s1 );
	new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasText",
			       'text', sprintf("%0.2f", $i), 
			       'font', $DEFAULT_FONT,
			       'x', $i * $xabst, 'y', $max-$yline+10 ) if ($i > $s1 );
    }
    for( my $i = $ix; $i < $size[0]; $i += 10/$xskaln ) {
	new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasLine",
			       'points', [$i * $xabst, $max-$yline-2, $i * $xabst, $max-$yline+1],
			       'fill_color', 'black' ) if ($i > $s1 );
	new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasText",
			       'text', sprintf("%0.2f", $i), 
			       'font', $DEFAULT_FONT,
			       'x', $i * $xabst, 'y', $max-$yline+10 ) 
	    if ($i > $s1 && $self->{'tic_text_x'});
    }

    for( my $i = $iy; $i < $size[2]; $i += 100/$yskaln ) {
	new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasLine",
			       'points', [$xline-2, $max - $i * $yabst, $xline+5, $max - $i * $yabst],
			       'fill_color', 'black' ) if ($i > $s3 );
	new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasText",
			       'text', sprintf("%0.2f", $i), 
			       'font', $DEFAULT_FONT,
			       'x', $xline-25, 'y', $max - $i * $yabst ) if ($i > $s3 );
    }
    for( my $i = $iy; $i < $size[2]; $i += 10/$yskaln ) {
	new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasLine",
			       'points', [$xline-1, $max - $i * $yabst, $xline+2, $max - $i * $yabst],
			       'fill_color', 'black' ) if ($i > $s3 );
	new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasText",
			       'text', sprintf("%0.2f", $i), 
			       'font', $DEFAULT_FONT,
			       'x', $xline-25, 'y', $max - $i * $yabst ) 
	    if ($i > $s3 && $self->{'tic_text_y'});
    }
   
    my $miny = $size[2] + abs($s3);
    $miny *= $yabst;
    $miny += 75;


    new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasLine",
			   'points', [$xline, 0, $xline, $max - $yline],
			   'fill_color', 'black' );
    new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasLine",
			   'points', [0, $miny, 0, 0],
			   'fill_color', 'black' ) if( $iy < 0 );
    
    new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasLine",
			   'points', [$xline, $max - $yline, $size[0]*$xabst, $max - $yline],
			   'fill_color', 'black' );
    new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasLine",
			   'points', [$size[1]*$xabst, $max, 0, $max],
			   'fill_color', 'black' ) if( $ix < 0 );

    my @keys = keys( %plot_data );
    
    
    $self->{'canvas'}->set_scroll_region( $xline-75,            #min X
					  -75,                  #min Y
					  $size[0]*$xabst+75,   #max X 
					  $max - $yline + 75 ); #max Y

    $self->set_status( "plotting..." );
    $self->init_progress( $#keys );
    my $v = 0;
    foreach( @keys ) {
	if( !($v % 500) ) {
	    $self->update_progress( $v );
	}
	$v++;
        if( defined($plot_data{$_}{'x'}) && defined($plot_data{$_}{'y'}) ) {
	    my $x = $plot_data{$_}{'x'};
	    my $y = $plot_data{$_}{'y'};

	    next if($x < $size[1] || $x > $size[0] ||
		    $y < $size[3] || $y > $size[2]);
		

	    $x *= $xabst;
	    $y *= $yabst;

	    my $col = 'red';
	    my $sw = $plot_data{$_}{'diameter'} || $self->{'sw'};
	    my $outcol = 'undef';
	    $outcol = 'black' if( $self->{'outline'} );
	    my $item = new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasEllipse",
					      'x1', $x -$sw,
					      'x2', $x +$sw,
					      'y1', $max - $y -$sw,
					      'y2', $max - $y +$sw,
					      'fill_color', $col,
					      'outline_color', $outcol );

	    $item->signal_connect( 'event', \&do_event, $_, $self );
	    $plot_data{$_}{'item'} = $item;
	    $plot_data{$_}{'color'} = 'red';
	} else {
	    print STDERR "\"$_\" not complete\n";
	}
    }
    if( defined( $self->{'yachse'} ) ) {
	new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasText",
			       'x', $xline, 'y', -10, 'text', $self->{'yachse'},
			       'font', $DEFAULT_FONT,
			       'anchor', 'center',
			       'fill_color', 'black' );
    }
    if( defined( $self->{'xachse'} ) ) {
	new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasText",
			       'x', $size[0]*$xabst, 'y', $max-$yline-10, 'text', $self->{'xachse'},
			       'font', $DEFAULT_FONT,
			       'anchor', 'center',
			       'fill_color', 'black' );
    }

    $self->create_diagonale if( $self->{'show_diag'} );
    $self->end_progress;
    $self->set_status( "done!" );
}

sub set_diagonale {
    my($self, $m, $b) = @_;
    $self->{'diagonale_m'} = $m;
    $self->{'diagonale_b'} = $b;

    $self->create_diagonale;
}

sub get_diagonale {
    my($self) = @_;
    return ($self->{'diagonale_m'}, $self->{'diagonale_b'});
}

sub create_diagonale {
    my($self) = @_;

    return if(!defined $self->{'cgroup'});

    my $m = $self->{'diagonale_m'};
    my $b = $self->{'diagonale_b'};

    my $xabst = $xskal * $self->{'xabst'};
    my $yabst = $yskal * $self->{'yabst'};
    my $max = $size[2] * $yabst + 50;
    my($x1, $x2, $y1, $y2) = @size;
    $x2 = 0 if($x2 > 0);

    $y1 = $m*$x1+$b;
    $y2 = $m*$x2+$b;
    
    $x1 *= $xabst;
    $y1 *= $yabst;
    $x2 *= $xabst;
    $y2 *= $yabst;
    my $points = [$x1, $max-$y1, $x2, $max-$y2];
    $self->{'linie'}->destroy if(defined $self->{'linie'});
    $self->{'linie'} = new Gnome::CanvasItem( $self->{'cgroup'}, "Gnome::CanvasLine",
					      'points', $points,
					      'fill_color', 'blue' );
}

sub show_class_members {
    my( $self ) = @_;
    foreach( keys( %plot_data ) ) {
	if( defined( $plot_data{$_}{'item'} ) ) {
	    $plot_data{$_}{'item'}->hide if( $plot_data{$_}{'class'} != $self->{'last_class'} );
	}
    }
    $self->{'mode'} = 0;
}    

sub do_event {
    my( $item, $name, $self, $event ) = @_;
    if( $event->{ 'type' } eq 'enter_notify' ) {
	my $xpos = $plot_data{$name}{'x'};
	my $ypos = $plot_data{$name}{'y'};
	my $des = $plot_data{$name}{'desc'};
	my $class = $plot_data{$name}{'class'};
	$item->set( 'fill_color', 'green' );
	my $desc = "    $name ";
	$desc .= "($class) " if( defined( $plot_data{$name}{'class'} ) );
	$desc .= sprintf(": (%0.3f - %0.3f) ", $xpos, $ypos);
	$desc .= "- $des " if( defined( $plot_data{$name}{'desc'} ) );
	$self->{'status'}->push( 1, $desc );
    } elsif( $event->{ 'type' } eq 'leave_notify' ) {
	$self->{'status'}->push( 1, "" );
	$item->set( 'fill_color', $plot_data{$name}{'color'} );
    } elsif( $event->{ 'type' } eq 'button_release' ) {
	my $class = $plot_data{$name}{'class'};
	if( defined( $self->{'last_class'} ) ) {
	    foreach( @{$spot_classes[$self->{'last_class'}]} ) {
		if( defined( $plot_data{$_}{'item'} ) ) {
		    $plot_data{$_}{'item'}->set( 'fill_color', 'red' );
		    $plot_data{$_}{'color'} = 'red';
		}
	    }
	}
	if( $event->{'button'} == 3 ) {
	    if( $self->{'mode'} ) {
		foreach( keys( %plot_data ) ) {
		    if( defined( $plot_data{$_}{'item'} ) ) {
			$plot_data{$_}{'item'}->hide if( defined $plot_data{$_}{'class'} && $plot_data{$_}{'class'} != $class );
		    }
		}
		$self->{'mode'} = 0;
	    } else {
		&show_all_plots( $self );
	    }
		    
	}
	$self->{'last_class'} = $plot_data{$name}{'class'};
	if( defined $self->{'last_class'} ) {
	    foreach( @{$spot_classes[$self->{'last_class'}]} ) {
		if( defined( $plot_data{$_}{'item'} ) ) {
		    $plot_data{$_}{'item'}->set( 'fill_color', 'blue' );
		    $plot_data{$_}{'item'}->raise_to_top;
		    $plot_data{$_}{'color'} = 'blue';
		}
	    }
	}
	
	if(defined( $self->{'sel_ref'} ) ) {
	    &{$self->{'sel_ref'}}( $name, @{$self->{'sel_data'}} );
	}
    }
    
    return 1;
}

1;
