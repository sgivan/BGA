package Statistic;

($GENDB::GUI::Statistic::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use strict;
use GENDB::GUI::GenDBWidget;
use GENDB::GUI::Creator;
use GENDB::GUI::GData;
use GENDB::GUI::GraphWidget;
use Gtk;
use vars qw(@ISA);

@ISA = qw(GenDBWidget);

my $new_color;
my @gdata;
my $colord = undef;
my $dia_open = 0;
my $zoom = 0;
my $mode = 1;
my $info_pos = undef;
my $gwindow;

################################
###                          ###
### drawing a mean GC usage, ###
###  mean orf-length,        ###
###  mean orf-count graph    ###
###                          ###
################################
sub new {
    my $class = shift;
    my $self = $class->SUPER::new;    
    bless $self, $class;

    my $hpaned = new Gtk::HPaned;

    $gwindow = new GraphWidget;
    $gwindow->mouse_signal_connect( 'button_press_event', \&set_info );
    $gwindow->mouse_signal_connect( 'button_release_event', \&info, $self );

    my $action = new Gtk::VBox( 0, 0 );

    my $creator = new Creator;
    $self->add_child($creator);
    $creator->up_func( sub{ $gwindow->set_mpos( $creator->current_frame ); } );
    $creator->down_func( sub{ $gwindow->set_mpos( $creator->current_frame ); } );

    my $zoombox = new Gtk::HBox( 0, 0 );

    my $b =  new Gtk::Button( "+" );
    $b->signal_connect( 'clicked', sub{ $gwindow->zoom( 1 ); } ); 
    $zoombox->pack_start( $b, 1, 1, 1 );
    
    $b =  new Gtk::Button( "0" );
    $b->signal_connect( 'clicked', sub{ $gwindow->reset; } ); 
    $zoombox->pack_start( $b, 1, 1, 1 );

    $b =  new Gtk::Button( "-" );
    $b->signal_connect( 'clicked', sub{ $gwindow->zoom( -1 ); } ); 
    $zoombox->pack_start( $b, 1, 1, 1 );
    
    my $frame = new Gtk::Frame( 'Zoom' );
    $frame->set_border_width( 7 );
    $frame->add( $zoombox );

    my $view = new Gtk::Frame( 'View Style' );
    my $vbox = new Gtk::VBox( 0, 0 );
    my $rb1 = new Gtk::RadioButton( 'relative' );
    my $rb2 = new Gtk::RadioButton( 'absolute', $rb1 );
    $rb1->signal_connect( 'clicked', \&toggle_rel );

    $vbox->pack_start( $rb1, 0, 0, 0 );
    $vbox->pack_start( $rb2, 0, 0, 0 );
    $view->add( $vbox );

    my $newbutton = new Gtk::Button( " new Graph " );
    $newbutton->signal_connect( 'clicked',  \&new_dialog, $self );

    $action->pack_start( $newbutton, 0, 1, 1 );
    $action->pack_end( $creator->widget, 0, 0, 0 );
    $action->pack_end( $frame, 0, 0, 0 );
    $action->pack_end( $view, 0, 0, 0 );

    $hpaned->add1( $action );
    $hpaned->add2( $gwindow->widget );
    $hpaned->set_position( 200 );

    $self->{ 'window' } = $gwindow;
    $self->{ 'action' } = $action;
    $self->{ 'creator' } = $creator;

    $self->add($hpaned);
    return $self;
}

sub set_contig {}

sub signal_connect {
    my( $self, $signal, $func, @data ) = @_;
    $self->{ 'creator' }->signal_connect( $signal, $func, @data );
}

sub toggle_rel {
    $mode = ( $mode + 1 ) % 2;
    $gwindow->set_mode( 1, $mode );
}

sub set_info {
    my( $darea, $win, $event ) = @_;
    $info_pos = $event->{ 'x' };
}

sub info {
    my( $darea, $window, $self, $event ) = @_;
    if( $info_pos == $event->{ 'x' } ) {
	if( $event->{ 'button' } == 1 && $gwindow->info_position ) {
	    $self->{ 'creator' }->frame_info( 0, $gwindow->info_position );
	}
    }
}

sub color { 
    my( $button, $bdraw, $color ) = @_;
    if( !$colord ) {
	$colord = new Gtk::ColorSelectionDialog( 'Color' );
	$colord->position( 'center' );
	$colord->colorsel->set_color( $color->red/65500, $color->green/65500, $color->blue/65500 );
	$colord->cancel_button->signal_connect( 'clicked', sub { $colord->hide; $colord = undef; } );
	$colord->ok_button->signal_connect( 'clicked', \&change_color, $bdraw );
	$colord->signal_connect( 'destroy', sub { $colord->hide; $colord = undef; } );
	$colord->show;
    }
}

sub change_color {
    my( $button, $bdraw ) = @_;
    
    my @color = $colord->colorsel->get_color();
    my $gdk_color;
    $gdk_color->{ 'red' } = $color[0] * 65535.0;
    $gdk_color->{ 'green' } = $color[1] * 65535.0;
    $gdk_color->{ 'blue' } = $color[2] * 65535.0;
    $new_color = $bdraw->window->get_colormap->color_alloc( $gdk_color );
    $bdraw->window->set_background( $new_color );
    $bdraw->window->clear;
    $colord->hide; 
    $colord = undef;
}

sub props {
    my( $button, $id, $self, $ev ) = @_;
    if( !$colord && $ev->{ 'button' } == 3 && !$dia_open ) {
	$dia_open = 1;
	my $gdata = $gwindow->gdata( $id );
	my $window = new CreatorDialog( 'properties of '.$gdata->name );
	$window->window_signal_connect( 'destroy', sub { $dia_open = 0; } );
	$window->set_gdata( $gdata );
	my $hbox = new Gtk::HBox( 1, 1 );
	$hbox->pack_start_defaults( new Gtk::Label( 'Color:' ) );
	my $button = new Gtk::Button;
	my $bdraw = new Gtk::DrawingArea;
	$bdraw->size( 20, 20 );
	$button->add( $bdraw );
	$button->signal_connect( 'clicked', \&color, $bdraw, $gdata->rgb_color );
	$hbox->pack_start_defaults( $button );
	$window->vbox->pack_end_defaults( $hbox );
    
	$hbox = new Gtk::HBox( 1, 1 );
	$hbox->pack_start_defaults( new Gtk::Label( 'Mutiplikator:' ) );
	my $adj = new Gtk::Adjustment( $gdata->multiplikator, 1,  10000, 1, 100, 1000   );
	my $spin = new Gtk::SpinButton( $adj  , 1, 0 );
	$hbox->pack_start_defaults( $spin );
	$window->vbox->pack_start_defaults( $hbox );
	
	my $ok_button = new Gtk::Button( 'OK' );
	$ok_button->signal_connect( 'clicked', \&change_id, $window, $spin, $id, $self );
	my $del_button = new Gtk::Button( 'delete' );
	$del_button->signal_connect( 'clicked', \&delete_id, $window, $id );
	my $rem_button = new Gtk::Button( 'Cancel' );
	$rem_button->signal_connect( 'clicked', sub{ $window->hide; $dia_open = 0; } );

	$window->action_area->pack_start_defaults( $ok_button );
	$window->action_area->pack_start_defaults( $del_button );
	$window->action_area->pack_start_defaults( $rem_button );
	$window->position( 'center' ); $window->show;
	$new_color = $bdraw->window->get_colormap->color_alloc( $gdata->rgb_color );
	$bdraw->window->set_background( $new_color );
	$bdraw->window->clear;
    }
}

sub delete_id {
    my( $button, $window, $id ) = @_;
    $window->hide; $dia_open = 0;
    $gwindow->remove_by_id( $id );
}

sub change_id {
    my( $button, $window, $spin, $id, $self ) = @_;
    $window->hide; $dia_open = 0;
    my( $name, $fenster, $typ ) = $window->get_values;
    if( $gwindow->info_position ) {
	$self->{ 'creator' }->frame_info( $fenster, $gwindow->info_position );
    }
    my $gdata = $gwindow->gdata( $id );
    my @l = $self->{ 'creator' }->get_data( $fenster, $typ );
    $gdata->set_data( $spin->get_value_as_int, \@l, $fenster, $typ );
    my $color = $gwindow->window->get_colormap->color_alloc( { red => 0, green => 0, blue => 0 } );
    if( $new_color ) {
	$color = $new_color;
    }
    $gdata->set_color( $color );
    $gdata->set_name( $name );
    $gwindow->change_id( $id, $gdata );
    $gwindow->repaint;
}

sub make_gd {
    my( $button, $window, $spin, $self ) = @_;
    my $creator = $self->{ 'creator' };
    $window->hide; $dia_open = 0;
    my( $name, $fenster, $typ ) = $window->get_values;
    my $gdata = new GData( $gwindow->window, $name );
    $gdata->set_name( $name );
    my @l = $creator->get_data( $fenster, $typ );
    $creator->frame_info( $fenster, $gwindow->info_position );
    $gdata->set_data( $spin->get_value_as_int, \@l, $fenster, $typ );
    my $color = $gwindow->window->get_colormap->color_alloc( { red => 0, green => 0, blue =>  } );
    if( $new_color ) {
	$color = $new_color;
    }
    $gdata->set_color( $color );
    my $id = $gwindow->add_gdata( $gdata );
    $gdata->button->signal_connect( 'button_press_event', \&props, $id, $self );
    $gwindow->repaint;
    $gwindow->show;
}

sub new_dialog {
    my( $mi, $self ) = @_;
    if( !$dia_open ) {
	$dia_open = 1;
	my $color = $gwindow->window->get_colormap->color_alloc( { red => 0, green => 0, blue => 65000 } );
	my $window = new CreatorDialog( 'new data' );
	$window->window_signal_connect( 'destroy', sub { $dia_open = 0; } );
	my $hbox = new Gtk::HBox( 1, 1 );
	$hbox->pack_start_defaults( new Gtk::Label( 'Color:' ) );
	my $button = new Gtk::Button;
	my $bdraw = new Gtk::DrawingArea;
	$bdraw->size( 20, 20 );
	$button->add( $bdraw );
	$button->signal_connect( 'clicked', \&color, $bdraw, $color );
	$hbox->pack_start_defaults( $button );
	$window->vbox->pack_end_defaults( $hbox );
    
	$hbox = new Gtk::HBox( 1, 1 );
	$hbox->pack_start_defaults( new Gtk::Label( 'Mutiplikator:' ) );
	my $adj = new Gtk::Adjustment( 1, 1,  10000, 1, 100, 1000   );
	my $spin = new Gtk::SpinButton( $adj  , 1, 0 );
	$hbox->pack_start_defaults( $spin );
	$window->vbox->pack_start_defaults( $hbox );

	my $ok_button = new Gtk::Button( 'OK' );
	$ok_button->signal_connect( 'clicked', \&make_gd, $window, $spin, $self );
	my $rem_button = new Gtk::Button( 'Cancel' );
	$rem_button->signal_connect( 'clicked', sub{ $window->hide; $dia_open = 0; } );

	$window->action_area->pack_start_defaults( $ok_button );
	$window->action_area->pack_start_defaults( $rem_button );
	$window->position( 'center' ); $window->show;
	
	$new_color = $bdraw->window->get_colormap->color_alloc( $color );
	$bdraw->window->set_background( $new_color );
	$bdraw->window->clear;
    }
}
1;
