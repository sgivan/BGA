package VirtualGel;

($GENDB::GUI::VirtualGel::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use strict;
use Gtk;
use GENDB::GUI::XYPlot;
use GENDB::orf;

use vars( qw(@ISA) );
@ISA = qw(Gtk::Window GenDBWidget);


###########################################
###                                     ###
### Plotting a virtual gel for all ORFs ###
###                                     ###
###########################################

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new( 'toplevel' );
    my $vbox = new Gtk::VBox( 0, 0 );
    my $plotter = new XYPlot;
    $plotter->outlined_spots(1);
    my $mbar = &make_mbar( $self );
    $vbox->pack_start( $mbar, 0, 0, 0 );
    $vbox->pack_start( $plotter, 1, 1, 1 );

    $plotter->show_tic_text(0, 1);

    $self->{'plotter'} = $plotter;

    $self->add( $vbox );
    $self->set_usize( 500, 500 );
    $self->set_position( 'center' );
    return bless $self;
}

sub _get_contig {
    my($self, $contigs) = @_;
    my $dia = new Gtk::Dialog;
    my $scrl = new Gtk::ScrolledWindow;
    my $list = new_with_titles Gtk::CList('Contig');
    my $ok = new Gtk::Button('OK');

    $list->set_selection_mode('browse');
    $scrl->set_policy('automatic', 'automatic');
    $dia->set_title('Select Contig');
    $dia->set_default_size(400, 400);
    $dia->set_position('center');

    $dia->vbox->add($scrl);
    $scrl->add($list);
    $dia->action_area->pack_start_defaults($ok);

    $list->append('all Contigs');
    foreach my $contig (@$contigs) {
	$list->append($contig->name);
    }

    my $ret = undef;
    $ok->signal_connect('clicked', sub {
	if($list->selection) {
	    my $name = $list->get_text($list->selection, 0);
	    $ret = GENDB::contig->init_name($name);
	}
	$dia->destroy;
    });

    $dia->show_all;
    
    Gtk->main_iteration while($dia->visible);

    return $ret;
}

sub _get_tool {
    my($self, $tools) = @_;
    my $dia = new Gtk::Dialog;
    my $scrl = new Gtk::ScrolledWindow;
    my $list = new_with_titles Gtk::CList('Tool');
    my $ok = new Gtk::Button('OK');

    $list->set_selection_mode('browse');
    $scrl->set_policy('automatic', 'automatic');
    $dia->set_title('Select Tool');
    $dia->set_default_size(400, 400);
    $dia->set_position('center');

    $dia->vbox->add($scrl);
    $scrl->add($list);
    $dia->action_area->pack_start_defaults($ok);

    $list->append('No Tool');

    foreach my $tool (@$tools) {
	$list->append($tool->name);
    }

    my $ret = undef;
    $ok->signal_connect('clicked', sub {
	if($list->selection) {
	    my $name = $list->get_text($list->selection, 0);
	    $ret = GENDB::tool->init_name($name);
	}
	$dia->destroy;
    });

    $dia->show_all;
    
    Gtk->main_iteration while($dia->visible);

    return $ret;
}

sub _get_range {
    my($self, $size) = @_;

    my $dia = new Gtk::Dialog;
    my $xmax = new Gtk::Entry; $xmax->set_text($size->[0]);
    my $xmin = new Gtk::Entry; $xmin->set_text($size->[1]);
    my $ymax = new Gtk::Entry; $ymax->set_text($size->[2]);
    my $ymin = new Gtk::Entry; $ymin->set_text($size->[3]);

    my $table = new Gtk::Table(4, 4);

    my $ok = new Gtk::Button('OK');

    $table->set_border_width(10);
    $table->set_col_spacings(10);

    my $y = 0;
    $table->attach_defaults(new Gtk::Label('XMax:'), 0, 1, $y, $y+1);
    $table->attach_defaults($xmax, 1, 4, $y, $y+1);
    $y++;

    $table->attach_defaults(new Gtk::Label('XMin:'), 0, 1, $y, $y+1);
    $table->attach_defaults($xmin, 1, 4, $y, $y+1);
    $y++;

    $table->attach_defaults(new Gtk::Label('YMax:'), 0, 1, $y, $y+1);
    $table->attach_defaults($ymax, 1, 4, $y, $y+1);
    $y++;

    $table->attach_defaults(new Gtk::Label('YMin:'), 0, 1, $y, $y+1);
    $table->attach_defaults($ymin, 1, 4, $y, $y+1);
    $y++;

    $dia->vbox->add($table);
    $dia->action_area->pack_start_defaults($ok);

    my $ret = undef;

    $ok->signal_connect('clicked', sub {
	$ret = [$xmax->get_text, $xmin->get_text, $ymax->get_text, $ymin->get_text];
	$dia->destroy;
    });

    $dia->set_title('Set Range');
    $dia->set_position('center');
    $dia->show_all;
    
    Gtk->main_iteration while($dia->visible);

    return $ret;    
}

sub log10 {
    my $n = shift;
    return log($n)/log(10);
}

sub show_gel {
    my( $self ) = @_;
    my %data;

    my $contigs = GENDB::contig->fetchall;
    my $contig = undef;

    if(ref $contigs eq 'ARRAY' && scalar @$contigs) {
	if(scalar @$contigs == 1) {
	    $contig = $contigs->[0];
	} else {
	    $contig = $self->_get_contig($contigs);
	}
    }

    my @size = ( -9999999999, 999999999, -99999999999, 99999999999 );
    my $orfs = (ref $contig) ? 
      GENDB::orf->fetchbySQL("contig_id = ".$contig->id) : 
	GENDB::orf->fetchall;
    my $c = 0;
    $self->init_progress(scalar @$orfs);
    foreach my $orf (@$orfs) {
	$self->update_progress($c++);
	my $isoelp = $orf->isoelp;
	my $molweight = ($orf->molweight) ? log10($orf->molweight) : 0;

	if (defined($isoelp) && ($molweight > 0)) {

	    my $product = $orf->latest_annotation->product;
	    my $name    = $orf->latest_annotation->name || $orf->name;
	    my $iep     = $isoelp;

	    my $desc = sprintf ("%s; %s (%s)", $name, 
				$orf->latest_annotation->product, 
				$orf->molweight);
	    $desc =~ tr/\n/ /;

	    $data{$name}{'x'} = $isoelp;
	    $data{$name}{'y'} = $molweight;
	    $data{$name}{'desc'} = $desc;
	    $size[0] = $isoelp if( $isoelp > $size[0] );
	    $size[1] = $isoelp if( $isoelp < $size[1] );
	    $size[2] = $molweight if( $molweight > $size[2] );
	    $size[3] = $molweight if( $molweight < $size[3] );	
	}
    }

    $self->end_progress;
    $self->{'plotter'}->set_description( 'pH', 'log(g/mol)' );
    $self->{'plotter'}->set_scale_width(1, 8);
    $self->{'plotter'}->set_data( \%data, \@size );
    
    $self->{'plotter'}->set_size($self->_get_range(\@size));

    $self->{'plotter'}->plot;
}

sub plotter {
    my( $self ) = @_;
    return $self->{'plotter'}
}

sub scale_dialog {
    my( $self ) = @_;
    my $dia = new Gtk::Dialog;
    my $hbox = new Gtk::HBox( 1, 1 );
    my( $xe, $ye ) = $self->{'plotter'}->scale_width;
    $hbox->pack_start_defaults( new Gtk::Label( 'X width' ) );
    my $xentry = new Gtk::Entry;
    $xentry->set_text( $xe );
    $hbox->pack_start_defaults( $xentry );
    $dia->vbox->pack_start_defaults( $hbox );
    $hbox = new Gtk::HBox( 1, 1 );
    $hbox->pack_start_defaults( new Gtk::Label( 'Y width' ) );
    my $yentry = new Gtk::Entry;
    $yentry->set_text( $ye );
    $hbox->pack_start_defaults( $yentry );
    $dia->vbox->pack_start_defaults( $hbox );
    my $ok = new Gtk::Button( 'OK' );
    my $ca = new Gtk::Button( 'Cancel' );
    $dia->action_area->pack_start_defaults( $ok );
    $dia->action_area->pack_start_defaults( $ca );
 
    $ca->signal_connect( 'clicked', sub { $dia->destroy } );
    $ok->signal_connect( 'clicked', sub { 
	$self->{'plotter'}->set_scale_width( $xentry->get_text,$yentry->get_text );
	$dia->destroy } );
    $dia->set_position( 'center' );
    $dia->show_all;
}


sub make_mbar {
    my( $self ) = @_;
    my @menu_items = ( { path        => '/File',
			 type        => '<Branch>' },
		       { path        => '/File/Close',
			 accelerator => '<control>X',
			 callback    => sub{ $self->destroy } },
		       
		       { path        => '/Zoom',
			 type        => '<Branch>' },
		       { path        => '/Zoom/Zoom In',
			 accelerator => '<control>I',
			 callback    => sub{ $self->{'plotter'}->zoom( 1.1 ) } },
		       { path        => '/Zoom/Zoom Out',
			 accelerator => '<control>O',
			 callback    => sub{ $self->{'plotter'}->zoom( 1/1.1 ) } },

		       { path        => '/Spots',
			 type        => '<Branch>' },
		       { path        => '/_Spots/1 Pixel',
			 callback    => sub{ $self->{'plotter'}->set_spot_size(1) } },
		       { path        => '/_Spots/2 Pixel',
			 callback    => sub{ $self->{'plotter'}->set_spot_size(2) } },
		       { path        => '/_Spots/3 Pixel',
			 callback    => sub{ $self->{'plotter'}->set_spot_size(3) } },
		       { path        => '/_Spots/4 Pixel',
			 callback    => sub{ $self->{'plotter'}->set_spot_size(4) } },
		       { path        => '/_Spots/5 Pixel',
			 callback    => sub{ $self->{'plotter'}->set_spot_size(5) } },

		       { path        => '/Scaling',
			 type        => '<Branch>' },
		       { path        => '/Scaling/Scale width',
			 accelerator => '<control>X',
			 callback    => sub{ &scale_dialog( $self ) } },

		       { path        => '/Search',
			 type        => '<Branch>' },
		       { path        => '/Search/Search Orf',
			 callback    => sub{ &search( $self, 'Orf' ) } },
		       { path        => '/Search/Show all Orfs',
			 accelerator => '<control>A',
			 callback    => sub{ $self->{'plotter'}->show_all_plots } },
		       );
    
    my $menubar;
    my $item_factory;
    my $accel_group;

    $accel_group = new Gtk::AccelGroup();
    $item_factory = new Gtk::ItemFactory( 'Gtk::MenuBar',
                                          '<main>',
                                          $accel_group );
    $item_factory->create_items( @menu_items );
    $self->add_accel_group( $accel_group );
    return ( $item_factory->get_widget( '<main>' ) );
}  

sub search {
    my( $self, $what ) = @_;
    my $dia = new Gtk::Dialog;
    my $l1 = new Gtk::Label( "Search for $what!" );
    my $l2 = new Gtk::Label( "Input $what-name:" );
    my $entry = new Gtk::Entry;
    $dia->vbox->pack_start_defaults( $l1 );
    $dia->vbox->pack_start_defaults( $l2 );
    $dia->vbox->pack_start_defaults( $entry );

    my $ok = new Gtk::Button( 'Start' );
    $ok->signal_connect( 'clicked', sub {
	$self->{'plotter'}->mark( $what, $entry->get_text );
	$dia->destroy;
    } );
    $dia->action_area->pack_start_defaults( $ok );
    $dia->set_modal( 1 );
    $dia->set_position( 'center' );
    $dia->show_all;
}
