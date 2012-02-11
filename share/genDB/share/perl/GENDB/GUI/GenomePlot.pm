package GENDB::GUI::GenomePlot;

# package to draw circular view of contigs

# $Id: GenomePlot.pm,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $

# $Log: GenomePlot.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:36  givans
#
#
# Revision 1.2  2001/06/13 12:43:38  blinke
# using name from latest annotation instead of orfname
#
# Revision 1.1  2001/06/13 12:35:36  blinke
# Initial revision
#

use strict;

use Gtk;
use GENDB::contig;
use GENDB::orf;

use vars qw (@ISA);

@ISA = qw (Gtk::Window);
1;

sub new {
    my ($class) = @_;

    my $self = $class->SUPER::new('toplevel');

    $self->set_title("Genome Plot");
    my $box = Gtk::HBox->new(0,0);
    bless $self, $class;

    my $darea = Gtk::DrawingArea->new();
    $darea->size (600, 600);
    $box->pack_start($darea, 1, 1, 0);
    $darea->signal_connect ('configure_event', \&redraw_contig, $self);
    $darea->signal_connect ('expose_event', \&draw_drawingarea, $self);
    $darea->set_events( [] );
    $self->{darea}=$darea;

    my $buttons = Gtk::VButtonBox->new();
    my $show_labels = Gtk::CheckButton->new("Show ORF Labels");
    $show_labels->set_active(1);
    $self->{labels}=1;
    $show_labels->signal_connect('toggled', \&show_labels, $self);
    $buttons->add($show_labels);
    my $show_tics = Gtk::CheckButton->new("Show tic marks");
    $show_tics->set_active(0);
    $self->{tics}=0;
    $show_tics->signal_connect('toggled', \&show_tics, $self);
    $buttons->add($show_tics);
    for (my $i = 0; $i < scalar @ORF_STATES; $i++) {
	my $state_button = Gtk::CheckButton->new("'".$ORF_STATES[$i]."' orfs");
	$state_button->set_active(1);
	$state_button->signal_connect('toggled', \&change_state, $self, $i);
	$buttons->add($state_button);
	$self->{states}->[$i]=1;
	push @{$self->{state_widgets}}, $state_button;
    }
    $buttons->set_spacing_default(0);
    $buttons->set_layout('start');
    $box->pack_end($buttons,0,0,0);
    $self->add($box);
    $self->show_all;
    return $self;
}

sub set_contig {
    my ($self, $contig) = @_;

    $self->{contig}=$contig;
    $self->set_title("Gene Plot of ".$contig->name);
    redraw_contig($self->{darea}, $self);
}

sub draw_drawingarea {

    my ($darea, $self) = @_;
		    
    if ($self->{pixmap}) {
	$darea->window->draw_pixmap($darea->style->fg_gc( 'normal' ),
				    $self->{pixmap},0,0,0,0,
				    $self->{xsize},$self->{ysize});
    }
    return 1;
}


sub show_labels {
    my ($button,$self) = @_;
    $self->{labels} = ($self->{labels}) ? 0 : 1;
    foreach my $widget (@{$self->{state_widgets}}) {
	$widget->set_sensitive($self->{labels});
    }
    redraw_contig($self->{darea}, $self);
    return 1;
}

sub show_tics {
    my ($button,$self) = @_;
    $self->{tics} = ($self->{tics}) ? 0 : 1;
    redraw_contig($self->{darea}, $self);
    return 1;
};

sub change_state {
    my ($button, $self, $state_index)=@_;
	
    $self->{states}->[$state_index] = ($self->{states}->[$state_index])? 0 : 1;
    redraw_contig($self->{darea}, $self);
    return 1;
}

sub redraw_contig {
    my ($darea, $self) = @_;

    if ($self->{contig}) {
	my ($dummy,$oxsize, $oysize) = @{$darea->allocation};
	
	my $xsize = ($oxsize > $oysize) ? $oxsize : $oysize;
        my $ysize = $xsize;
	
	$self->{xsize} = $xsize;
	$self->{ysize} = $ysize;
	#$darea->set_usize($xsize, $ysize);
	my $inner_width = int ($xsize / 4);
	my $outer_width = int ($xsize / 1.5);
	my $middle_width = int (($outer_width + $inner_width) /2);
	my $orf_width = int (($outer_width - $inner_width) / 7);
	my $tic_length = $orf_width / 2;
	my $white_gc = new Gtk::Gdk::GC ($self->window);
	my $black_gc = new Gtk::Gdk::GC ($self->window);
	my $red_gc = new Gtk::Gdk::GC ($self->window);
	my $blue_gc = new Gtk::Gdk::GC ($self->window);
	my $green_gc = new Gtk::Gdk::GC ($self->window);
	
	my $white_color = $darea->window->get_colormap->color_alloc( { red => 65000, green => 65000, blue => 65000 } );
	$white_gc->set_foreground( $white_color );
	my $black_color = $darea->window->get_colormap->color_alloc( { red => 0, green => 0, blue => 0 });
	
	$black_gc->set_foreground( $black_color );
	
	my $pixmap = new Gtk::Gdk::Pixmap (
					   $darea->window,$xsize, $ysize, -1);
	$self->{pixmap}=$pixmap;
	
	# fill white
	$pixmap->draw_rectangle($darea->style->white_gc,1,0,0,$xsize,$ysize);
	
	# draw black circles
	
	$pixmap->draw_arc($black_gc, 0, ($xsize - $inner_width)/ 2, 
			  ($ysize - $inner_width)/ 2,
			  $inner_width, $inner_width, 0, 360*64);
	$pixmap->draw_arc($black_gc, 0, ($xsize - $outer_width)/ 2,
			  ($ysize - $outer_width)/ 2,
			  $outer_width, $outer_width, 0, 360*64);
	$pixmap->draw_arc($black_gc, 0, ($xsize - $middle_width)/ 2,
			  ($ysize - $middle_width)/ 2,
			  $middle_width, $middle_width, 0, 360*64);
	
	my $orfs = $self->{contig}->fetchorfs;
	my $length = $self->{contig}->length;
	my $arc_gc = new Gtk::Gdk::GC ($self->window);
	$arc_gc->set_line_attributes(int ($orf_width * 0.4),'solid','not_last',
				     'miter');
	$arc_gc->set_foreground( $black_color );			 
	
	my $label_font = load Gtk::Gdk::Font "-adobe-courier-*-*-*-*-*-100-*-*-*-*-*-*";
	foreach my $orf (values %$orfs) {
	    # skip orf if state is disabled
	    next if (!$self->{states}->[$orf->status]);
      
	    my $start_angle = $orf->start / $length * 360 * 64 + 90 * 64;
	    my $stop_angle = ($orf->stop - $orf->start)/ $length * 360 * 64;
	    my $diameter = $middle_width + $orf->frame * $orf_width;
	    my $xpos = ($xsize - $diameter)/2;
	    my $ypos = ($ysize - $diameter)/2;
	    $pixmap->draw_arc($arc_gc, 0, $xpos, $ypos,
			      $diameter, $diameter,
			      $start_angle, $stop_angle);
	    if ($self->{labels}) {
		my $angle = ($orf->start + abs (($orf->stop - $orf->start))/2) / $length * 2 * 3.146;
		$pixmap->draw_line ($black_gc,
				    $xsize/2 - int ($diameter/2 * sin ($angle)),
				    $ysize/2 - int ($diameter/2 * cos ($angle)),
				    $xsize/2 - int (($outer_width/2 + 50) * sin ($angle)),
				    $ysize/2 - int (($outer_width/2 + 50) * cos ($angle)));
		my $labelxpos = int ($xsize /2 - sin ($angle) * ($outer_width /2 +60));
		my $labelypos = int ($ysize /2 - cos ($angle) * ($outer_width /2 +60));
		my $orfname;
		if ($orf->status == $ORF_STATE_IGNORED) {
		    $orfname='--';
		} 
		else {
		    my $annotation = $orf->latest_annotation;
		    if ($annotation->name != "") {
			$orfname=$annotation->name;
		    } 
		    else {
			$orfname=$orf->name;
		    }
		};
		draw_string_adjust ($angle, $pixmap, $label_font, $black_gc, $labelxpos, $labelypos, $orfname);
	    }
	}
	
	if ($self->{tics}) {
	    my $length = $self->{contig}->length;
	    my $tic_step = int (10 ** int (log ($length) / log (10))/2);
	    
	    my $position = 0;
	    my $last_big = 0;
	    
	    my $xpos = $xsize/ 2;
	    my $ypos = $ysize/ 2;
	    my $tic_gc = new Gtk::Gdk::GC ($self->window);
#	    $tic_gc->set_line_attributes($tic_width,'solid',
	#				 'not_last','miter');
	    $tic_gc->set_foreground($black_color);
	    
	    my $tic_font = load Gtk::Gdk::Font "-adobe-courier-*-*-*-*-*-100-*-*-*-*-*-*";
	    while ($position < $length) {
		my $angle = $position / $length * 2 * 3.146;
		$pixmap->draw_line ($tic_gc,
				    $xpos - int ($outer_width/2 * sin ($angle)),
				    $ypos - int ($outer_width/2 * cos ($angle)),
				    $xpos - int (($outer_width/2 + 10) * sin ($angle)),
				    $ypos - int (($outer_width/2 + 10) * cos ($angle)));
				    
		my $textxpos = int ($xsize /2 - sin ($angle) * ($outer_width /2 +20));
		my $textypos = int ($ysize /2 - cos ($angle) * ($outer_width /2 +20));
		draw_string_adjust ($angle, $pixmap, $tic_font, $black_gc, $textxpos, $textypos, $position);
		$position += $tic_step; 
	    }
	}
    }
    draw_drawingarea ($self->{darea}, $self);
    return 0;
}

# draw string left justified (the normal case)
sub draw_string_left {
    my ($pixmap, $font, $gc, $xpos, $ypos, $string)= @_;

    $pixmap->draw_string($font, $gc, $xpos,
			 $ypos, $string);
}

# draw string centered
sub draw_string_centered {
    my ($pixmap, $font, $gc, $xpos, $ypos, $string, $bottom_align) = @_;
    
    if ($bottom_align) {
	$pixmap->draw_string ($font, $gc, 
			      $xpos - int($font->string_width($string)/2),
			      $ypos, $string);
    }
    else {
	$pixmap->draw_string ($font, $gc, 
			      $xpos - int($font->string_width($string)/2),
			      $ypos - $font->string_height($string),
			      $string);
    }
}

# draw string right justified
sub draw_string_right {
    my ($pixmap, $font, $gc, $xpos, $ypos, $string) = @_;
    
    $pixmap->draw_string ($font, $gc, 
			  $xpos- $font->string_width($string),
			  $ypos, $string);
}

# auto-adjust string according to their position at a circle
# strings at "top" and "bottom" are centered,
# strings at the "left" are right justified,
# strings at the "right" are left justified
# angle is the degree according to the circle, 0
# indication to topmost point, counte clockwise oriented..
sub draw_string_adjust {
    my ($o_angle, @parameters) = @_;

    # normalize angle
    my $angle = ($o_angle * 180 / 3.148 + 360) % 360;
    if (($angle >= 315) || ($angle < 45)) {
	draw_string_centered (@parameters, 1);
    }
    elsif (($angle >= 135) && ($angle < 225)) {
	# "top" and "bottom" area
	draw_string_centered (@parameters, 0);
    }
    elsif (($angle >= 45) && ($angle < 135)) {
	# 'left' area
	draw_string_right (@parameters);
    }
    else {
	# "right" area
	draw_string_left (@parameters);
    }
}
