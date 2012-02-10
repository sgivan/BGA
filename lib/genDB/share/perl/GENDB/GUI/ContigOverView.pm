package ContigOverView;

($GENDB::GUI::ContigOverView::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use GENDB::GENDB_CONFIG;
use GENDB::contig;
use strict;
use vars qw(@ISA);

@ISA = qw(Gtk::ScrolledWindow);

#################################################
###                                           ###
### graphical view of all contigs in database ###
###                                           ###
#################################################

sub new {
    my $class = shift;
    my $self= $class->SUPER::new;

    my $canvas = new Gnome::Canvas;
    my $canvasgrp = new Gnome::CanvasItem($canvas->root, 'Gnome::CanvasGroup');
    $self->{'canvas'} = $canvas;
    $self->{'canvasgrp'} = $canvasgrp;

    &create_canvas( $self );
    
    $self->set_policy( 'automatic', 'never' );
    $self->get_hadjustment->step_increment( 10 );
    $self->add( $canvas );

    bless $self, $class;
    return $self;
}

sub create_canvas {
    my( $self ) = @_;
    my %contigs = %{ GENDB::contig->fetchallby_name };
    my %citems;
    my $l = 5;
    my $pos = 1;
    my $root = $self->{'canvasgrp'};
    $self->{ 'contigs' } = \%contigs;

    foreach my $name ( sort( keys( %contigs ) ) ) {
	$citems{$name}{'length'} = $contigs{$name}->length/1000;
	
	$citems{$name}{'item'} = new Gnome::CanvasItem( $root,
						      "Gnome::CanvasGroup",
						      "x", $l,
						      "y", 10,
						      );

	$citems{$name}{'rect'} = new Gnome::CanvasItem( $citems{$name}{'item'},
							"Gnome::CanvasRect",
							"x1", 0,
							"y1", 0,
							"x2", $citems{$name}{'length'},
							"y2", 10,
							"fill_color", "red",
							"outline_color", "black",
							"width_pixels", 1
							);
	$citems{$name}{'text'} = new Gnome::CanvasItem( $citems{$name}{'item'},
							"Gnome::CanvasText",
							"text", $name,
							"x", $citems{$name}{'length'}/2,
							"y", $pos*15+5,
							"anchor", "center",
							"font", $DEFAULT_FONT,
							"fill_color", "#777777",
							);		

	$citems{$name}{'item'}->signal_connect( 'event', \&selected, $name, $self );
	$citems{$name}{'x'} = $l;

	$l += $citems{$name}{'length'}+5;
	$pos *= -1; 
    }
    $self->{ 'current' } = undef;
    $self->{'canvas'}->set_scroll_region( 0, 0, $l, 40 );
    $self->{ 'items' } = \%citems;
}

sub update {
    my($self) = @_;
    $self->{'canvasgrp'}->destroy;
    $self->{'canvasgrp'} = new Gnome::CanvasItem($self->{'canvas'}->root, 'Gnome::CanvasGroup');
    $self->create_canvas;
}

sub selected {
    my( $item, $name, $self, $event ) = @_;
    if( $event->{ 'type' } eq 'button_press' ) {
	&set_contig( $self, $name, 1 );
	my $func = $self->{ 'contig_changed' };
	if( defined( $func )) {
	    &$func( $self->{ 'contigs'}->{ $name }, $self->{ 'contig_changed_data' } );
	}
    }
}

sub signal_connect {
    my( $self, $signal, $func, @data ) = @_;
    $self->{ $signal } = $func;
    $self->{ $signal."_data" } = @data;
}

sub set_contig {
    my( $self, $contig, $scroll ) = @_;
    my $current = $self->{ 'current' };
    if( !defined( $current ) ) {
	$current = $contig;
	$self->{ 'current' } = $contig;
	$self->{ 'items' }->{ $current }{'rect'}->set( "fill_color", "green" );
	$self->{ 'items' }->{ $current }{'text'}->set( "fill_color", "black" );
	$self->{ 'canvas' }->scroll_to( $self->{ 'items' }->{ $current }{'x'} - 50, 0 ) if(!$scroll);
    } elsif( !($self->{ 'current' } eq $contig )) {
	$self->{ 'items' }->{ $current }{'rect'}->set( "fill_color", "red" );
	$self->{ 'items' }->{ $current }{'text'}->set( "fill_color", "#777777" );
	$current = $contig;
	$self->{ 'current' } = $contig;
	$self->{ 'items' }->{ $current }{'rect'}->set( "fill_color", "green" );
	$self->{ 'items' }->{ $current }{'text'}->set( "fill_color", "black" );
	$self->{ 'canvas' }->scroll_to( $self->{ 'items' }->{ $current }{'x'} - 50, 0 ) if(!$scroll);
    }
}


1;
