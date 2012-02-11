package SequenceEditor;

use Gtk;
use Gnome;
use GENDB::GUI::SequenceCanvas;
use GENDB::GUI::Utils;

use GENDB::contig;
use GENDB::orf;

use vars( qw(@ISA) );
@ISA = qw( Gtk::Window );

1;

# some fine constants to define actions
my $CHANGEBASE = 0;
my $DELETEBASE = 1;
my $INSERTBASE = 2;

#################################################
###                                           ###
###    Dialog to edit a plain DNA sequence    ###
### Should only be used BEFORE GENEPREDICTION ###
###                                           ###
#################################################

sub new {
    my $class = shift;
    my $self = $class->SUPER::new( 'toplevel' );
    bless $self, $class;

    my $mbox = new Gtk::VBox( 0, 15 );
    $mbox->set_border_width( 5 );
    my $list = new_with_titles Gtk::CList( 'ID', 'Select Contig:' );
    my $scroller = new Gtk::ScrolledWindow;
    my $canvas = new SequenceCanvas;
    my $hbox = new Gtk::HBox( 1, 1 );
    my $vbox = new Gtk::VBox( 0, 1 );
    my $frame = new Gtk::Frame( 'Correction Data' );

    $scroller->set_policy( 'automatic', 'automatic' );

    my $bbox = new Gtk::HBox( 1, 1 );
    $bbox->set_border_width( 5 );

    my $apply_toorfs = new Gtk::CheckButton('Update ORFs');
    $bbox->pack_start( $apply_toorfs, 0, 0, 0 );
    $apply_toorfs->signal_connect('toggled', sub {
	$self->{'_apply_orfs'} = $apply_toorfs->active;
    });

    my $b = new Gtk::Button( 'Apply correction' );
    $b->set_sensitive(0);
    $b->signal_connect( 'clicked', \&apply, $self );
    $bbox->pack_start( $b, 0, 0, 0 );
    $self->{'apply_button'} = $b;

    my $b = new Gtk::Button( 'Dismiss' );
    $b->signal_connect( 'clicked', sub{ $self->destroy }, $self );
    $bbox->pack_start( $b, 0, 0, 0 );


    my $change = new Gtk::RadioButton( 'Change Base' );
    my $delete = new Gtk::RadioButton( 'Delete Base', $change );
    my $insert = new Gtk::RadioButton( 'Insert Base', $delete );
    $change->signal_connect( 'released', sub{ $self->{'action'} = $CHANGEBASE; 
					      $self->{'e_what'}->set_editable( 1 );
					      $self->{'e_length'}->set_editable( 0 );
					  } );
    $delete->signal_connect( 'released', sub{ $self->{'action'} = $DELETEBASE;
					      $self->{'e_what'}->set_editable( 0 );
					      $self->{'e_length'}->set_editable( 1 );
					  } );
    $insert->signal_connect( 'released', sub{ $self->{'action'} = $INSERTBASE; 
					      $self->{'e_what'}->set_editable( 1 );
					      $self->{'e_length'}->set_editable( 0 );
					  } );

    my $rbox = new Gtk::HBox( 1, 1 );
    $rbox->set_border_width( 5 );
    $rbox->pack_start( $change, 0, 0, 0 );
    $rbox->pack_start( $delete, 0, 0, 0 );
    $rbox->pack_start( $insert, 0, 0, 0 );

    my $lbox = new Gtk::VBox( 1, 10 );
    $lbox->pack_start_defaults( new Gtk::Label( 'Offset:' ) );
    $lbox->pack_start_defaults( new Gtk::Label( 'What:' ) );
    $lbox->pack_start_defaults( new Gtk::Label( 'Length:' ) ) ;

    my $ebox = new Gtk::VBox( 1, 10 );
    $self->{'e_offset'} = new Gtk::Entry;
    
    $self->{'e_offset'}->set_text( 0 );
    $self->{'e_offset'}->set_sensitive(0);
    $self->{'e_offset'}->signal_connect( 'changed', sub{ 
	my $offset = int($_[0]->get_text);
	if( $offset > $self->{'act_contig'}->length ) {
	    $offset = $self->{'act_contig'}->length;
	    $_[0]->set_text( $offset );
	}
	$self->{'canvas'}->scroll_to_pos($offset-1);
	$self->{'canvas'}->mark( $offset, $self->{'e_length'}->get_text + $offset );
	} );

    $self->{'e_what'} = new Gtk::Entry;
    $self->{'e_what'}->set_sensitive(0);
    $self->{'e_what'}->signal_connect( 'changed', sub{ 
	my $txt = $_[0]->get_text;
	if( $txt =~ /^(a|t|c|g)*$/i ) {
	    $self->{'old_what' } = $txt;
	    $self->{'e_length'}->set_text( length( $txt ) );
	} else {
	    $self->{'e_what'}->set_text( $self->{ 'old_what' } );
	}
	my $offset = $self->{'e_offset'}->get_text;
	$self->{'canvas'}->mark( $offset, $self->{'e_length'}->get_text + $offset );
    } );
    
    $self->{'e_length'} = new Gtk::Entry;
    $self->{'e_length'}->set_sensitive(0);
    $self->{'e_length'}->set_text( 0 );
    $self->{'e_length'}->set_editable( 0 );
    $self->{'e_length'}->signal_connect( 'changed', sub{ 
	my $offset = $self->{'e_offset'}->get_text;
	my $seq = $self->{'canvas'}->mark( $offset, $self->{'e_length'}->get_text + $offset );
    } );

    $ebox->pack_start( $self->{'e_offset'}, 1, 1, 1 );
    $ebox->pack_start( $self->{'e_what'}, 1, 1, 1 );
    $ebox->pack_start( $self->{'e_length'}, 1, 1, 1 );
    
    my $edit = new Gtk::HBox( 0, 10 );
    $edit->pack_start( $lbox, 0, 0, 1 );
    $edit->pack_start( $ebox, 1, 1, 1 );
   
    $vbox->pack_start( $rbox, 0, 0, 0 );
    $vbox->pack_start( new Gtk::HSeparator, 0, 0, 0 );
    $vbox->pack_start( $edit, 1, 1, 1 );
    $vbox->pack_start( new Gtk::HSeparator, 0, 0, 0 );
    $vbox->pack_end( $bbox, 0, 0, 0 );
    $frame->add( $vbox );

    my $contigs = GENDB::contig->fetchallby_name;
    $list->set_column_visibility( 0, 0 );
    $list->column_titles_passive;
#    $list->set_selection_mode('browse');
    $scroller->add( $list );
    
    $self->{'list'} = $list;
    $self->{'canvas'} = $canvas;
    $self->{'action'} = 0;
    $self->{'start_mark'} = -1;

    $hbox->pack_start( $scroller, 1, 1, 1 );
    $hbox->pack_end( $frame, 1, 1, 1 );

    $mbox->pack_start( $hbox, 0, 0, 1 );
    $mbox->pack_start( new Gtk::HSeparator, 0, 0, 1 );
    $mbox->pack_start( $canvas, 1, 1, 1 );
    $self->add( $mbox );
    $self->set_title( 'Sequence-Editor' );
    $self->set_usize( 700, 555 );

    $self->{'canvas'}->canvas->signal_connect( 'button_press_event', sub{
	if( $_[1]->{'button'} == 1 ) {
	    my $spos = $self->{'canvas'}->world_to_sequence( $_[1]->{'x'} );
	    $self->{'e_offset'}->set_text( $spos );
	    $self->{'start_mark'} = $spos;
	    my $seq = $self->{'canvas'}->mark( $self->{'start_mark'}, $spos );
	    $self->{'e_what'}->set_text( $seq );
	}
    } );

    $self->{'canvas'}->canvas->signal_connect( 'motion_notify_event', sub{
	if( $self->{'start_mark'} >= 0 ) {
	    my $spos = $self->{'canvas'}->world_to_sequence( $_[1]->{'x'} );
	    my $epos = $spos - $self->{'start_mark'};
	    return if( $spos == $self->{'stop_mark'} );
	    $self->{'stop_mark'} = $spos;
	    if( $epos > 0 ) {
		$self->{'canvas'}->mark( $self->{'start_mark'}, $spos );
	    }
	}
    } );
    
    $self->{'canvas'}->canvas->signal_connect( 'button_release_event', sub{
	my $seq = $self->{'canvas'}->get_marked_seq;
	$self->{'e_length'}->set_text( length $seq );
	$self->{'e_what'}->set_text( $seq ) if( $self->{'action'} != $INSERTBASE );
	$self->{'start_mark'} = -1;
    } );					       

    $self->set_position( 'center' );

    $list->signal_connect( 'select_row', \&set_contig, $self );
    foreach( sort keys(%$contigs) ) {
	$list->append( $contigs->{$_}->id, $_ );
    }

    return $self;
}

sub show {
    my($self) = @_;
    $self->show_all;
    #$self->{'list'}->select_row(0, 0);
}

sub apply {
    my( $w, $self ) = @_;

    if( defined( $w ) ) {
	$self->{'offset'} = $self->{'e_offset'}->get_text;
	$self->{'what'} = $self->{'e_what'}->get_text;
	$self->{'length'} = $self->{'e_length'}->get_text;    
	$self->{'length'} = length( $self->{'what'} ) if( $self->{'action'} != $DELETEBASE );
    }
  Utils::show_yesno( "Do you really want to change the sequence?\n Old sequence will be lost!\n", 1, 
		       sub{ change_sequence($self); }, 
		       sub{} );
}

sub set_contig {
    my( $list, $self, $col, $row, $event ) = @_;

    # set all Gtk::Entry widgets and apply button sensitive
    $self->{'e_offset'}->set_sensitive(1);
    $self->{'e_what'}->set_sensitive(1);
    $self->{'e_length'}->set_sensitive(1);
    $self->{'apply_button'}->set_sensitive(1);

    my $contig_id = $list->get_text($col, 0);
    my $cur_contig = GENDB::contig->init_id( $contig_id );
    $self->{'act_contig'} = $cur_contig;
    $self->{'canvas'}->set_contig( $self->{'act_contig'} );
    
    my $orf_ref = $cur_contig->fetchorfs();
    my @orfs = keys(%{$orf_ref});
    if ($#orfs > 0) {
	Utils::show_information( "The selected contig contains ORFs! These may be invalidated by changing the sequence!\n", $self);
    };
    return 1;
}

# this sub does the main work...
sub change_sequence {
    my ($self) = @_;

    # what to do :
    # - apply changes to sequence of contig
    # - DO NOT run any tools
    

    # IC IC missing sanity check

    my $offset = $self->{offset};
    my $act_contig = $self->{act_contig};

    my $length = 0;

    # execute the sequence correction itself

    my $sequence = $act_contig->sequence;

    if ($self->{action} == $CHANGEBASE) {
	# replace content
	substr($sequence, $offset, length ($self->{what})) = $self->{what};
	$length = 0;
    }
    elsif ($self->{action} == $DELETEBASE) {
	# delete content
	substr ($sequence, $offset, $self->{length}) = "";
	$length = 0 - $self->{length};
    }
    else {
	# insert content
	substr ($sequence, $offset, 0) = $self->{what};
	$length = length($self->{what});
    }

    if($self->{'_apply_orfs'}) {
	my $orfs = GENDB::orf->fetchbySQL("stop >= $offset && contig_id = ".$act_contig->id);
	my @damaged;

	foreach my $orf (@$orfs) {
	    my $start = $orf->start;
	    my $stop  = $orf->stop;
	    my $frame = $orf->frame;
	    my $name  = $orf->name;
	
	    push @damaged, $orf if(!($start > $offset) && ($stop > $offset));
	    
	    $start += $length if($start > $offset);
	    $stop  += $length if($stop > $offset);
	
	    # now correct the frame....
	    
	    if ($frame > 0) {
		$frame = $start % 3;
		$frame = 3 if (!$frame);
	    } else {
		$frame = -($start % 3);
		$frame = -3 if (!$frame);
	    }
	    $orf->start($start);
	    $orf->stop($stop);
	    $orf->frame($frame);
	}

	$self->open_deprecated_dialog(\@damaged);
    }

    $act_contig->delete_from_cache;
    $act_contig->sequence($sequence);
    $act_contig->length(length($sequence));    
    
    main->update_contigs;
    $self->hide;
	
}


sub open_deprecated_dialog {
    my($self, $orflist) = @_;
    my $dia = new Gtk::Dialog;
    $dia->set_position('center');
    $dia->set_modal(1);
    my $scr = new Gtk::ScrolledWindow;
    $scr->set_policy('automatic', 'automatic');
    my $list = new_with_titles Gtk::CList("ID", "Deprecated Orf");
    $list->set_column_visibility(0, 0);
    $list->set_selection_mode('multiple');

    $list->signal_connect('select_row', sub {
	my($list, $row) = @_;
	my $id = $list->get_text($row, 0);
	main->show_orf($id);
    });

    $scr->add($list);
    
    $dia->vbox->add($scr);

    my %buttons = ( 'Close' => sub { $dia->destroy; $self->destroy },
		    'Delete Orfs' => sub {
			my @sel = $list->selection;
			while(@sel) {
			    my $id = $list->get_text($_, 0);
			    my $orf = GENDB::orf->init_id($id);
			    $orf->drop_facts;
			    $orf->delete;
			    $list->remove($_);
			    @sel = $list->selection;
			}
		    },
		    'Set Ignored' => sub {
			my @sel = $list->selection;
			while(@sel) {
			    my $id = $list->get_text($_, 0);
			    my $orf = GENDB::orf->init_id($id);
			    $orf->status($ORF_STATE_IGNORED);
			    $list->remove($_);
			    @sel = $list->selection;
			}
		    });

    my $bb = new Gtk::HButtonBox;

    foreach(keys %buttons) {
	my $b = new Gtk::Button($_);
	$b->signal_connect('clicked', $buttons{$_});
	$bb->pack_start_defaults($b);
    }

    $dia->action_area->add($bb);

    foreach(@{$orflist}) {
	$list->append($_->id, $_->name);
    }
    $dia->set_title('Deprecated Orfs');
    $dia->set_default_size(450, 350);
    $dia->show_all;
}
