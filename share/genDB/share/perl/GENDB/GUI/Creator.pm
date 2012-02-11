package InfoDialog;

#########################################
###                                   ###
### Information about selected region ###
###                                   ###
#########################################
sub new {
    my( $self ) = @_;
    my %self;
    my $window = new Gtk::VBox( 1, 1 );
    my $table = new Gtk::Table( 10, 6, 1 );

    my $ok_button = new Gtk::Label( 'Framesize:' );
    my $up_button = new Gtk::Button;
    $up_button->add( new Gtk::Arrow( 'right', 'etched_in' ) );
    my $down_button = new Gtk::Button;
    $down_button->add( new Gtk::Arrow( 'left', 'etched_in' ) );
    my $adj = new Gtk::Adjustment( 5000, 100,  10000, 100, 1000, 1000 );
    my $spin = new Gtk::SpinButton( $adj  , 1, 0 );
    my $label = new Gtk::Label( "Frame Overview\n" );
    $label->set_justify( 'left' );
    my $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'automatic' );
    $scroller->add_with_viewport( $label );

    $table->attach_defaults( $down_button, 0, 1, 0, 1 );
    $table->attach_defaults( $up_button, 1, 2, 0, 1 );
    $table->attach_defaults( $ok_button, 2, 4, 0, 1 );
    $table->attach_defaults( $spin, 4, 6, 0, 1 );
    $table->attach_defaults( $scroller, 0, 6, 1, 10 );
    $window->add( $table );

    $spin->set_editable( 0 );

    $self{ 'window' } = $window;
    $self{ 'up' }     = $up_button;
    $self{ 'down' }   = $down_button;
    $self{ 'range' }  = $spin;
    $self{ 'label' }  = $label;
    $self{ 'cpos' }   = 0;
    
    bless \%self;
    return \%self;
}

sub up {
    my( $self ) = @_;
    return $self->{ 'up' };
}

sub down {
    my( $self ) = @_;
    return $self->{ 'down' };
}

sub range {
    my( $self ) = @_;
    my $ret = $self->{ 'range' }->get_value_as_int;
    if( !$ret ) { $ret = 5000; }
    return $ret;
}

sub set_text {
    my( $self, $text ) = @_;
    $self->{ 'label' }->set_text( $text );
}

sub widget {
    my( $self ) = @_;
    return $self->{ 'window' };
}

sub show {
    my( $self ) = @_;
    $self->{ 'window' }->show_all;
}

sub set_range {
    my( $self, $range ) = @_;
    $self->{ 'range' }->set_value( $range );
}

#-----------------------------------------------------------------------------
package Creator;

use strict;
use GENDB::GUI::GenDBWidget;
use GENDB::contig;
use GENDB::orf;
use vars(qw(@ISA));

@ISA = qw(GenDBWidget);

my %contigs;

########################################################
###                                                  ###
### the main computation module for Statistic Widget ###
###                                                  ###
########################################################

sub new {
    my($class) = @_;
    my $self = $class->SUPER::new;
    bless $self, $class;

    $self->{ 'name' } = 'name';
    $self->{ 'crange' } = 5000; 
    %contigs = %{ GENDB::contig->fetchallby_id; };
    my $info = new InfoDialog;
    $info->up->signal_connect( 'clicked', \&info, $self, 1 );
    $info->down->signal_connect( 'clicked', \&info, $self, -1 );
    $self->{ 'info' } = $info; 

    return $self;
}

sub get_data {
    my( $self, $range, $typ ) = @_;
    if( !$self->{ $range } ) {
	&make( $self, $range );
    }
    return @{ $self->{ $range }->{ $typ } };
}

sub widget {
    my( $self ) = @_;
    return $self->{ 'info' }->widget;
}

sub up_func {
    my( $self, $func ) = @_;
    $self->{ 'up_func' } = $func;    
    $self->{ 'info' }->up->signal_connect( 'clicked', $self->{ 'up_func' }, $self );
}

sub down_func {
    my( $self, $func ) = @_;
    $self->{ 'down_func' } = $func;
    $self->{ 'info' }->down->signal_connect( 'clicked', $self->{ 'down_func' }, $self );
}

sub current_frame {
    my( $self ) = @_;
    my $pos = $self->{ 'cpos' } / $self->{ $self->{ 'crange' } }->{ 'length' };
    return $pos;
}

sub info {
    my( $button, $self, $jump ) = @_;
    my $npos = $self->{ 'cpos' } + $jump;
    &frame_info( $self, 0, $npos );
}

sub frame_info {
    my( $self, $range, $pos ) = @_;
    my $info = $self->{ 'info' };
    if( $range ) {
	$info->set_range( $range ) ;
    } else {
	$range = $info->range;
    }
    $self->{ 'crange' } = $range;

    $range = $info->range;
    $self->{ 'crange' } = $range;

    if( !$self->{ $range } ) {
	&make( $self, $range );
    }
    my $ipos= $pos;
    if( $ipos < 1 && $ipos > 0 ) {
	my $len =  $#{ $self->{ $range }->{ 'Length' } };
	$ipos = int( $len * $pos );
	$ipos++;
    }
    if( !( $ipos < 0 || $ipos > $self->{ $range }->{ 'length' } ) ) {
	my $ltext = &create_text( $self, $ipos, $range );
	$info->set_text( $ltext );
	$self->{ 'cpos' } = $ipos;
    }
}

sub create_text {
    my( $self, $ipos, $range ) = @_;
    my $text = "Frame: $ipos\n";
    my $contig = $contigs{ ( $self->{ $range }->{ 'contig' }->[$ipos] ) };
    $text .= "Contig(".$self->{ $range }->{ 'contig' }->[$ipos]."): ".
	$contig->name."\n";
    my $clen = $self->{ $range }->{ 'anfang' }->[$ipos];
    $text .= "BASE: ".$clen." - ".
	( $clen + $range )."\n\n";

    my %orfs = %{ $contig->fetchorfs }; 
    $text .= "Orf Number:\t".$self->{ $range }->{ 'Number' }->[$ipos]."\n".
	"Orf Length:\t".$self->{ $range }->{ 'Length' }->[$ipos]."\n".
	    "GC Content:\t".$self->{ $range }->{ 'gc' }->[$ipos]."\n\n";
    $text .= "Orfs: \n------------------\n";
    foreach my $orf ( sort( values( %orfs ) ) ) {
	if( $orf->start < ( $clen + $range ) && 
	    $orf->stop  >   $clen ) {
	    $text .= "\t".$orf->id.": ".$orf->name."\n".
		$orf->start." - ".$orf->stop."\n".
		    "L: ".$orf->length.", GC: ".$orf->gc."\n\n";
	}
    }

    &contig_changed( $contig->name, $self );
   
    return $text;
}

sub signal_connect {
    my( $self, $signal, $func, @data ) = @_;
    $self->{ $signal } = $func;
    $self->{ $signal."_data" } = @data;
}

sub contig_changed {
    my( $contig, $self ) = @_;
    my $func = $self->{ 'contig_changed' };
    &$func( $contig, $self->{ 'contig_changed_data' } );
}

sub make {
    my( $self, $range ) = @_;
    my $ges_len = 0;
    my @vals;
    my @length;
    my @gc;
    my @return_list_values;
    my @return_list_gc;
    my @return_list_length;
    my @return_list_anfang;
    my @return_list_contig;
    my $zaehler = 0;
    my $contig_list = GENDB::contig->fetchall;

    my $length = $#{ $contig_list };
    $self->init_progress($length-1);

    my $count = 0;
	
    foreach my $cont (@$contig_list) {
	$self->update_progress($count++);
	my $orflist = $cont->fetchorfs;
	my $cnam = $cont->name;
	my $cid  = $cont->id;
	my $cnext = $cont->rneighbor_id;
	my $clen = $cont->length;

	$ges_len += $clen;
	#print "$cid: $cnam -> $cnext : $clen\n";

	foreach my $orf (sort( values( %$orflist ) ) ) {
	    my $orf_length = $orf->stop - $orf->start;
	    my $orf_name   = $orf->name;
	    my $orf_gc     = $orf->gc;

	    my $start_int = int $orf->start / $range;
	    my $stop_int  = int $orf->stop / $range;

	    for( my $i = $start_int; $i <= $stop_int; $i++ ) {
		$vals[$i]++;
		$length[$i] += $orf_length;
		$gc[$i] += $orf_gc;
	    }
	}
	my $anfang = 0;
	for( my $l = 0; $l <= $#vals; $l++ ) {
	    $return_list_values[$zaehler] = $vals[$l];
	    $return_list_contig[$zaehler] = $cont->id;
	    $return_list_anfang[$zaehler] = $anfang;
	    $anfang += $range;
	    if( $anfang > $cont->length ) {
		$anfang = $cont->length;
	    }
	    if( $vals[$l] ) {
		$return_list_gc[$zaehler] = $gc[$l] / $vals[$l];
		$return_list_length[$zaehler] = $length[$l] / $vals[$l];
	    } else {
		$return_list_gc[$zaehler] = 0;
		$return_list_length[$zaehler] = 0;
	    }
	    $zaehler++;
	}
	
	@vals = undef;
	@length = undef;
	@gc = undef;
    }
    $self->end_progress;
    $self->{ $range }->{ 'anfang' } = \@return_list_anfang;
    $self->{ $range }->{ 'Number' } = \@return_list_values;
    $self->{ $range }->{ 'Length' } = \@return_list_length;
    $self->{ $range }->{ 'gc' }     = \@return_list_gc;
    $self->{ $range }->{ 'contig' } = \@return_list_contig;
    $self->{ $range }->{ 'length' } = $#return_list_values;
}

#------------------------------------------------------------------------
package CreatorDialog;

########################################
###                                  ###
### Dialog to set Creator properties ###
###                                  ###
########################################

sub new {
    my( $self, $title ) = @_;
    my %self;
    my $window = new Gtk::Dialog;
    $window->title( $title );
    my $hbox = new Gtk::HBox( 1, 1 );
    my $rb1 = new Gtk::RadioButton( 'Length' );
    my $rb2 = new Gtk::RadioButton( 'Number', $rb1 );
    my $rb3 = new Gtk::RadioButton( 'gc', $rb2 );
    $hbox->pack_start_defaults( $rb1 );
    $hbox->pack_start_defaults( $rb2 );
    $hbox->pack_start_defaults( $rb3 );
    $self{ 'types' } = [ $rb1, $rb2, $rb3 ];
    $window->vbox->pack_start_defaults( $hbox );

    $hbox = new Gtk::HBox( 1, 1 );
    $hbox->pack_start_defaults( new Gtk::Label( 'Name:' ) );
    my $name = new Gtk::Entry;
    $name->set_text( 'default' );
    $hbox->pack_start_defaults( $name );
    $self{ 'name' } = $name;
    $window->vbox->pack_start_defaults( $hbox );
    
    $hbox = new Gtk::HBox( 1, 1 );
    $hbox->pack_start_defaults( new Gtk::Label( 'Window Size:' ) );
    my $adj = new Gtk::Adjustment( 5000, 100,  10000, 100, 1000, 1000 );
    my $spin = new Gtk::SpinButton( $adj  , 1, 0 );
    $hbox->pack_start_defaults( $spin );
    $window->vbox->pack_start_defaults( $hbox );
    $self{ 'fenster' } = $spin;

    $self{ 'window' } = $window;

    bless \%self;
    return \%self;
}

sub window_signal_connect {
    my( $self, $sig, $func, @data ) = @_;
    $self->{ 'window' }->signal_connect( $sig, $func, @data );
}

sub set_gdata {
    my( $self, $gdata ) = @_;
    $self->{ 'name' }->set_text( $gdata->name );
    $self->{ 'fenster' }->set_value( $gdata->frame );
    foreach ( @{ $self->{ 'types' } } ) {
	if( $_->label eq $gdata->typ ) {
	    $_->set_active( 1 );
	    last;
	}
    }
}

sub get_values {
    my( $self ) = @_;
    my @vals = ( $self->{ 'name' }->get_text, $self->{ 'fenster' }->get_value_as_int );
    foreach ( @{ $self->{ 'types' } } ) {
	if( $_->active ) {
	    push( @vals, $_->label );
	    last;
	}
    }
    return @vals;
}

sub vbox {
    my( $self ) = @_;
    return $self->{ 'window' }->vbox;
}

sub action_area {
    my( $self ) = @_;
    return $self->{ 'window' }->action_area;
}

sub show {
    my( $self ) = @_;
    $self->{ 'window' }->show_all;
}

sub position {
    my( $self, $pos ) = @_;
    $self->{ 'window' }->position( $pos );
}

sub hide {
   my( $self ) = @_;
   $self->{ 'window' }->hide;
} 

1;

