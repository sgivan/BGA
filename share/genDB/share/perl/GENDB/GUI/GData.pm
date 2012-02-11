package GData;

use Gtk;
use strict;

########################################
###                                  ###
### Data module for Statistic-widget ###
###                                  ###
########################################

sub new {
    my( $self, $window, $name ) = @_;
    my %self;
    my $r = int( rand( 65000 ) );
    my $g = int( rand( 65000 ) );
    my $b = int( rand( 65000 ) );
    my $color = $window->get_colormap->color_alloc( { red => $r, green => $g, blue => $b } );
    my $gc = new Gtk::Gdk::GC ( $window );
    $gc->set_foreground( $color );
    $self{ 'color' } = $color;
    $self{ 'gc' } = $gc;

    my $tb = new Gtk::ToggleButton;
    my $vbox = new Gtk::VBox( 1, 1 );
    my $buffer = new Gtk::Gdk::Pixmap( $window, 50, 10, -1 );
    my $nlabel = new Gtk::Label( $name );
    $buffer->draw_rectangle(
        $self{ 'gc' },
        1,
        0,
	0,
        50,
        12
    );

    $vbox->pack_start_defaults( new Gtk::Pixmap( $buffer, undef ) );
    $vbox->pack_start_defaults( $nlabel  );
    $tb->add( $vbox );
    $tb->set_active( 1 );
    $tb->signal_connect( 'clicked', \&toggle, \%self );

    $self{ 'id' } = undef;
    $self{ 'show' } = 1;
    $self{ 'button' } = $tb;
    $self{ 'pixmap' } = $buffer;
    $self{ 'nlabel' } = $nlabel;
    $self{ 'start' }  = 0;
    $self{ 'end'}     = 1;

    bless \%self;
    return \%self;
}

sub set_color {
    my( $self, $color ) = @_;
    $self->{ 'color' } = $color;
    $self->{ 'gc' }->set_foreground( $color );
    $self->{ 'pixmap' }->draw_rectangle(
        $self->{ 'gc' },
        1,
        0,
	0,
        50,
        12
    );
    $self->{ 'button' }->show;
}

sub set_name {
    my( $self, $name ) = @_;
    $self->{ 'nlabel' }->set_text( $name );
    $self->{ 'name' } = $name;
}

sub button {
    my( $self ) = @_;
    return $self->{ 'button' };
}

sub toggle {
    my( $button, $self ) = @_;
    $self->{ 'show' }++;
    $self->{ 'show' } %= 2;
}

sub set_data {
    my( $self, $multi, $data, $frame, $typ ) = @_;
    my $max = 0;
    for( 0..$#{ $data } ) {
	$data->[$_] = $data->[$_] * $multi;
    }
    for( 0..$#{ $data } ) {
	if( $data->[$_] > $max ) {
	    $max = $data->[$_];
	}
    }
    my $old_len = $#{ $self->{ 'data' } };
    if( $old_len <= 0 ) { $old_len = 1; }
    $self->{ 'max' } = $max;
    $self->{ 'len' } = $#{ $data };
    $self->{ 'data' } = $data;
    $self->{ 'multi' } = $multi;
    $self->{ 'frame' } = $frame;
    $self->{ 'typ' } = $typ;
    &set_zoom( $self, ($self->{ 'start' } / $old_len), ($self->{ 'end' } / $old_len) );
}

sub set_zoom {
    my( $self, $start, $end ) = @_;
    my $len = $#{ $self->{ 'data' } };
    $start = int( $start * $len );
    $end   = int( $end * $len );
    $self->{ 'start' } = $start;
    $self->{ 'end' } = $end;
    $len = $end - $start;
    if( !$len ) { $len = 1; }
    $self->{ 'len' } = $len;
}

sub data {
    my( $self ) = @_;
    return @{ $self->{ 'data' } }[ $self->{ 'start' } .. $self->{ 'end' } ];
}

sub typ {
    my( $self ) = @_;
    return $self->{ 'typ' };
}

sub name { 
    my( $self ) = @_;
    return $self->{ 'name' };
}

sub frame {
    my( $self ) = @_;
    return $self->{ 'frame' };
}

sub multiplikator {
    my( $self ) = @_;
    return $self->{ 'multi' };
}

sub color {
    my( $self ) = @_;
    return $self->{ 'gc' };
}

sub rgb_color {
    my( $self ) = @_;
    return $self->{ 'color' };
}

sub active {
    my( $self ) = @_;
    return $self->{ 'show' };
}

sub max {
    my( $self ) = @_;
    return $self->{ 'max' };
}

sub length {    
    my( $self ) = @_;
    return $self->{ 'len' };
}

sub all_length {
    my( $self ) = @_;
    return $#{ $self->{ 'data' } };
}

sub print {
    my( $self ) = @_;
    print $self->id.": ".$self->max.", ".$self->length."\n";
}

sub id {
    my( $self, $id ) = @_;
    if( $id ) {
	$self->{ 'id' } = $id;
    }
    return $self->{ 'id' };
}

1;



