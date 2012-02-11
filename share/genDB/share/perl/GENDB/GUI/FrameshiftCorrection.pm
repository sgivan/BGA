package FrameshiftCorrection;

($GENDB::GUI::FrameshiftCorrection::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use Gtk;
use Gnome;
use GENDB::GUI::SequenceCanvas;
use GENDB::GUI::Utils;

use GENDB::contig;
use GENDB::orf;
use GENDB::annotation;
use GENDB::annotator;
use GENDB::Tools::Glimmer2;

use vars( qw(@ISA) );
@ISA = qw( Gtk::Window );

1;

#################
##
## TODO:
##  add status messages
##
##################

# some fine constants to define actions
my $CHANGEBASE = 0;
my $DELETEBASE = 1;
my $INSERTBASE = 2;

###################################
###                             ###
### Dialog to correct framshift ###
###                             ###
###################################

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
    my $b = new Gtk::Button( 'Apply correction' );
    $b->signal_connect( 'clicked', \&apply, $self );
    $bbox->pack_start( $b, 0, 0, 0 );

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
    $list->set_selection_mode('browse');
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
    $self->set_title( 'Frameshift Correction' );
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
    $self->{'list'}->select_row(0, 0);
}

sub apply {
    my( $w, $self ) = @_;
    if( defined( $w ) ) {
	$self->{'offset'} = $self->{'e_offset'}->get_text;
	$self->{'what'} = $self->{'e_what'}->get_text;
	$self->{'length'} = $self->{'e_length'}->get_text;    
	$self->{'length'} = length( $self->{'what'} ) if( $self->{'action'} != $DELETEBASE );
    }
  Utils::show_filesel( "The frameshift affected several ORFs.\n Glimmer2 will be run to validate them and create new ones if necessary.\nPlease select a model file for Glimmer2!\n", 1, 
		       sub{ $self->{ 'modelfile' } = $_[0]; 
			    correctframeshift($self); }, 
		       sub{} );
}

sub set_contig {
    my( $list, $self, $col, $row, $event ) = @_;
    my $contig_id = $list->get_text($col, 0);
    $self->{'act_contig'} = GENDB::contig->init_id( $contig_id );
    $self->{'canvas'}->set_contig( $self->{'act_contig'} );
}

# this sub does the main work...
sub correctframeshift {

    my ($self) = @_;

    # what to do :
    # - get a list of all orfs being indirectly involved in frameshift
    #   (by moving the position)
    # - get a list of all orfs being directly involved in frameshift
    #   ( -> the frameshift is inside an orf)
    # - correct the frameshift
    # - correct the position of all involved orfs
    # - if directly involved orfs exist, ask about deleting their facts
    # - run glimmer to validate old orfs and create new ones

    # IC IC missing sanity check

    my $offset = $self->{offset};
    my $act_contig = $self->{act_contig};

    my $orfs_to_move = [];
    my $orfs_affected = [];

    # fetch all orfs being affected by the frameshift
    
    # orfs to shift (start > offset, stop <= contig length)
    $orfs_to_move = $act_contig->fetchOrfsinRange($offset,$act_contig->length);
    $orfs_affected = $act_contig->fetchOrfsatPosition ($offset);

    my $length = 0;

    # execute the frameshift correction itself

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

    $act_contig->delete_from_cache;
    $act_contig->sequence($sequence);
    $act_contig->length(length($sequence));

    # update orfs

    if (scalar (@$orfs_to_move) && $length) {
	foreach $orf (@$orfs_to_move) {
	    my $start = $orf->start + $length;
	    my $stop = $orf->stop + $length;
	    my $frame = $orf->frame;

	    # now correct the frame....

	    if ($frame > 0) {
		$frame = $start % 3;
		$frame = 3 if (!$frame);
	    }
	    else {
		$frame = -($start % 3);
		$frame = -3 if (!$frame);
	    }

	    # update orf
	    $orf->start($start);
	    $orf->stop($stop);
	    $orf->frame($frame);
	}
    }
    
    if (scalar (@$orfs_affected) || scalar (@$orfs_to_move)) {

	my $glimmer = GENDB::Tools::Glimmer2->new();

	if( $self->{'modelfile'} ne '' ) {
	    my $modelfile = $self->{'modelfile'};
	    stat($modelfile); 
	    while( !-r _ ) {
		&apply( undef, $self );
		$modelfile = $self->{'modelfile'};
		stat($modelfile);
	    }
	    $glimmer->model_file($modelfile);
	}
	my $msg;
	$glimmer->statusmessage(\$msg);
	Gtk->watch_add($msg, 0, sub { 
	    Gtk->main_iteration while(Gtk->events_pending);
	    main->update_statusbar($msg);
	    return 1 } );
	$glimmer->add_sequence($act_contig->name, $act_contig->sequence);

	$glimmer->run_glimmer();

	# get all orfs being affected by the frameshift
	# (stop position >= frameshift position)
	my @generated_orfs = grep {$_->{'to'} >= $offset} @{$glimmer->orfs($act_contig->name)};

	# sort them
	@generated_orfs = sort {$a->{'from'} <=> $b->{'from'}} @generated_orfs;

	# do the same for ORFs from GENDB
	
	# concat both lists of ORFs
	if(scalar @$orfs_affected) {
	    @orfs_in_gendb = @$orfs_affected;
	    splice (@orfs_in_gendb, $#orfs_in_gendb, 0, @$orfs_to_move);
	} else {
	    @orfs_in_gendb = @$orfs_to_move;
	}
	@orfs_in_gendb = sort {$a->start <=> $b->start} @orfs_in_gendb;
	
	
        # this is a mean hack
	# we need to know the highest id allready stored in db
	# (id = "<sequencename>_000x")
	my $next_orf_id =0;
	foreach (values %{$act_contig->fetchorfs}) {
	    my ($junk,$orf_id) = split "_", $_->name();
	    $next_orf_id = $orf_id if ($orf_id > $next_orf_id);
	}
	$next_orf_id++;
	
	my $annotator = GENDB::annotator->init_name("glimmer");
	my @deprecated_orfs;
	# cross check the lists of ORFs
	
        # lets do a cross check of both lists
	# new ORFs (ORF not in db) shall be created,
	# old ORFs (ORF in db, but no in @generated_orfs)
	# shall be marked "attention needed"
	for ($i=0; $i< scalar (@generated_orfs); $i++) {
	    
	    if (defined ($orfs_in_gendb[0])) {
		while ($orfs_in_gendb[0]->start < $generated_orfs[$i]->{'from'}) {
		    # do not touch annotated and finished orfs
		    if (($orfs_in_gendb[0]->status != $ORF_STATE_ATTENTION_NEEDED) ||
			($orfs_in_gendb[0]->status != $ORF_STATE_IGNORED) ||
			($orfs_in_gendb[0]->status != $ORF_STATE_ANNOTATED) ||
			($orfs_in_gendb[0]->status != $ORF_STATE_FINISHED)) {
			# these ORFs has been deprecated, so mark them
			$orfs_in_gendb[0]->status($ORF_STATE_ATTENTION_NEEDED);
			my $annotation=GENDB::annotation->create('',$orfs_in_gendb[0]->id);
			if ($annotation < 0) {
			    die "can't create annotation object for $annotation\n";
			}
			# set annotator to glimmer
			push(@deprecated_orfs, $orfs_in_gendb[0]);
			$annotation->annotator_id($annotator->id);
			$annotation->description("ORF was deprecated by another glimmer2-run (validation after frameshift at offset $offset)");
			$annotation->date(time());
		    }	
		    
		    shift @orfs_in_gendb;
		}
		
		# both orfs got the same start position,	   
		if ($orfs_in_gendb[0]->start == $generated_orfs[$i]->{'from'}) {
		    if ($orfs_in_gendb[0]->stop == $generated_orfs[$i]->{'to'}) {
			# if start and stop position are the same,
			# this orf is already in database
			shift @orfs_in_gendb;
			next;
		    }
		}
	    }
	    my $orf_data = $generated_orfs[$i];
	    
	    # create a new orf
	    my $orfname=sprintf ("%s_%004d",$act_contig->name,$next_orf_id);
	    $next_orf_id++;
	    my $orf=GENDB::orf->create($act_contig->id,
				       $orf_data->{'from'},
				       $orf_data->{'to'},
				       $orfname);
	    if ($orf < 0) {
		die "can't create orf object for $orfname\n";
	    }
	    
	    # fill in information
	    $orf->status(0); # status is putative
	    $orf->frame($orf_data->{'frame'});
	    $orf->startcodon ($orf_data->{'startcodon'});
	    
	    my $orf_aaseq = $orf->aasequence();
	    $orf->isoelp(GENDB::Common::calc_pI($orf_aaseq));
	    
	    # there's a name clash !
	    # calling $orf->molweight uses GENDB::Common::molweight
	    # damnit importing of symbols !
	    # we should fix this as soon as possible
	    # IC IC IC IC IC 
	    my $molweight = GENDB::Common::molweight($orf_aaseq);
	    GENDB::orf::molweight($orf, $molweight);
	    
	    my $orf_seq= $orf->sequence();
	    
	    # count Gs and Cs...
	    my $gs = ($orf_seq =~ tr/g/g/);
	    my $gcs = ($orf_seq =~ tr/c/c/) + $gs;
	    
	    # count As and Gs...
	    my $ags = ($orf_seq =~ tr/a/a/) + $gs;
	    $orf->gc(int ($gcs / length ($orf_seq) * 100));
	    $orf->ag(int ($ags / length ($orf_seq) * 100));
	    
	    my $annotation=GENDB::annotation->create('',$orf->id);
	    if ($annotation < 0) {
		die "can't create annotation object for $annotation\n";
	    }
	    # set annotator to glimmer
	    
	    $annotation->annotator_id($annotator->id);
	    $comment=$orf_data->{'comment'};
	    if ($comment) {
		$comment.=", created after correcting frameshift at offset $offset";
	    }
	    else {
		$comment = "created after correcting frameshift at offset $offset";
	    }
	    $annotation->comment($comment);
	    
	    $annotation->description('ORF created by glimmer2');
	    $annotation->date(time());
	    
	    # reset toollevel and order tools
	    $orf->toollevel(0);
	    for ($job_id = $orf->order_next_job; $job_id != -1;
		 $job_id = $orf->order_next_job) {
		Job->create($GENDB::Config::GENDB_CONFIG, $job_id);
	    }
	}
	main->update_contigs;
	$self->hide;
	if($#deprecated_orfs >= 0) {
	    $self->open_deprecated_dialog(\@deprecated_orfs);
	} else {
	    $self->destroy;
	}
    }
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
