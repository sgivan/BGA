package CGPlot;

($GENDB::GUI::CGPlot::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use GENDB::GENDB_CONFIG;
use GENDB::GUI::Utils;
use GENDB::contig;
use vars qw(@ISA);

@ISA = qw( Gtk::VBox );

#######################################
###                                 ###
### Plot the cg-usage in ContigView ###
###                                 ###
#######################################

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new( 0, 0 );

    my $scr = new Gtk::ScrolledWindow;
    my $can = new Gnome::Canvas;
    $self->{'can'} = $can;
    my $bb = new Gtk::HBox( 0, 0 );
    my $adj = new Gtk::Adjustment( 30, 10, 500, 1, 10, 500 );
    $self->{'adj'} = $adj;
    my $fe = new Gtk::SpinButton( $adj, 1, 0 );
    my $grp = new Gnome::CanvasItem( $can->root, "Gnome::CanvasGroup" );
    $self->{'grp'} = $grp;
    my $orf = new Gnome::CanvasItem( $can->root, "Gnome::CanvasGroup" );
    $self->{'orf'} = $orf;
    my $dat =  new Gtk::Label;
    $self->{'label'} = $dat;

    new Gnome::CanvasItem( $can->root, 'Gnome::CanvasLine',
			   'points', [0,0,0,100] );
    new Gnome::CanvasItem( $can->root, 'Gnome::CanvasLine',
			   'points', [-3,0,3,0] );
    new Gnome::CanvasItem( $can->root, 'Gnome::CanvasText', 'text', '100%',
			   'font', $DEFAULT_FONT, 
			   'x', 20, 'y', 0 );
    new Gnome::CanvasItem( $can->root, 'Gnome::CanvasLine',
			   'points', [-3,100,3,100] );
    new Gnome::CanvasItem( $can->root, 'Gnome::CanvasText', 'text', '0%',
			   'font', $DEFAULT_FONT, 
			   'x', 20, 'y', 100 );


    $bb->pack_start_defaults( $dat );
    $bb->pack_start( new Gtk::Label( 'Window size:' ), 0, 0, 3 );
    $bb->pack_start_defaults( $fe );
    $scr->set_policy( 'never', 'automatic' );
    $scr->get_vadjustment->step_increment( 10 );
    $scr->add( $can );
    $self->pack_start_defaults( $scr );
    $self->pack_end( $bb, 0, 0, 0 );

    $self->{'zoom'} = 10;
    $self->{'start'} = 0;

    $adj->signal_connect( 'value_changed', sub {
	&make_graph($self, $_[0]->get_value );
    });
    
    return bless $self;
}

sub set_zoom {
    my( $self, $zoom ) = @_;
    $self->{'zoom'} = $zoom;
    &make_graph( $self, $self->{'adj'}->get_value );
}

sub set_contig {
    my( $self, $contig ) = @_;
    $self->{'contig'} =  GENDB::contig->init_name($contig);
    $self->{'seq'} = $self->{'contig'}->sequence;
    $self->{'start'} = 0;
    $self->{'hilite-orf'} = undef;
    &make_graph( $self, $self->{'adj'}->get_value );
}

sub hilite_orf {
    my( $self, $orf ) = @_;
    $self->{'hilite-orf'} = $orf;
}

sub scroll {
    my( $self, $pos ) = @_;
    return if not defined $self->{'contig'};
    $self->{'start'} = $pos;
    &make_graph( $self, $self->{'adj'}->get_value );
}

sub make_graph {
    my( $self, $frm ) = @_;
    return if not defined $self->{'seq'};

    my $start = $self->{'start'};
    $start = 0 if( $start < 0 );
    $self->{'grp'}->destroy;
    $self->{'grp'} = new Gnome::CanvasItem( $self->{'can'}->root, "Gnome::CanvasGroup" );
    $self->{'orf'}->destroy;
    $self->{'orf'} = new Gnome::CanvasItem( $self->{'can'}->root, "Gnome::CanvasGroup" );
    
    my( undef, undef, $visible_size ) = @{$self->{'can'}->allocation};
    my $end = ($visible_size * $self->{'zoom'});

    $start -= $start%$frm;
    $end -= $end%$frm;
   
    if( defined( $self->{'hilite-orf'} ) ) {
	my $orf = $self->{'hilite-orf'};
	my $ostart = ($orf->start - $start) / $self->{'zoom'};
	my $oend = ($orf->stop - $start) / $self->{'zoom'};
	new Gnome::CanvasItem( $self->{'orf'}, 'Gnome::CanvasLine',
			       'points', [$ostart, 10, $ostart, 90],
			       'fill_color', &Utils::get_color_for_orf($orf, 'selected') )->show;
	new Gnome::CanvasItem( $self->{'orf'}, 'Gnome::CanvasLine',
			       'points', [$oend, 10, $oend, 90],
			       'fill_color', &Utils::get_color_for_orf($orf, 'selected') )->show;
    }

    my $seq = substr( $self->{'seq'}, $start, $end );
    return if not defined $seq;
    my $len = (length $seq);
    my $xds = $frm / $self->{'zoom'};

    my $pos = 0;
    my $x = 0;
    my @pts;
    my $all = 0;
    my $cnt = 0;
    my $max = 0;
    my $min = 100;
    my $ln = 0;

    while( $pos < length $seq ) {
	$_ = substr( $seq, $pos, $frm );
	my $y = tr/GgCc/GgCc/;
	$y = $y / $frm * 100;
	$all += $y;
	$pos += $frm;
	$max = $y if( $y > $max );
	$min = $y if( $y < $min );
	$cnt++;
	push( @pts, $x, (100-$y) );
	$x += $xds;
    }
    return if not $cnt;
    $self->{'x'} = $x;
    my $mean = ($all / $cnt);

    my $tmpx = 0;
    my @meanpts;
    my @maxpts;
    my @minpts;


    while( $tmpx < $x+10 ) {
	push( @meanpts, $tmpx, 100-$mean, $tmpx + 500, 100-$mean );
	push( @maxpts, $tmpx, 100-$max, $tmpx+500, 100-$max );
	push( @minpts, $tmpx, 100-$min, $tmpx+500, 100-$min );
	$tmpx += 500;
    }
    new Gnome::CanvasItem( $self->{'grp'}, 'Gnome::CanvasLine',
			   'points', \@meanpts,
			   'fill_color', 'DarkGray' );
    new Gnome::CanvasItem( $self->{'grp'}, 'Gnome::CanvasLine',
			   'points', \@maxpts,
			   'fill_color', 'DarkGray' );
    new Gnome::CanvasItem( $self->{'grp'}, 'Gnome::CanvasLine',
			   'points', \@minpts,
			   'fill_color', 'DarkGray' );

    
    new Gnome::CanvasItem( $self->{'grp'}, 'Gnome::CanvasLine',
			   'points', \@pts );

    $self->{'can'}->set_scroll_region( 0, 0, $x+10, 100 );
    my $txt = sprintf( "max: %.4g, min: %.4g, mean: %.4g", $max, $min, $mean );
    $self->{'label'}->set_text( $txt );
}

1;
    
