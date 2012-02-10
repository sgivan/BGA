package OrfCreator;

use GENDB::contig;
use GENDB::orf;
use GENDB::GUI::SequenceCanvas;
use GENDB::GUI::Utils;
use GENDB::GUI::AnnotationEditor;
use Gtk;
use Job;
use vars qw(@ISA);

@ISA = qw(Gtk::Window);

#################################
###                           ###
### Dialog to create new ORFs ###
###                           ###
#################################

sub new {
    my($class) = @_;
    my $self = $class->SUPER::new('dialog');
    bless $self, $class;
    
    my $vbox = new Gtk::VBox(0, 0);
    my $hbox = new Gtk::HBox(0, 3);
    my $combo = new Gtk::Combo;
    my @contigs;
    foreach(sort keys %{GENDB::contig->fetchallby_name}) {
	push(@contigs, $_);
    }

    my $canvas = new SequenceCanvas;
    my $name = new Gtk::Entry;
    my $offset = new Gtk::SpinButton(new Gtk::Adjustment(1, 0, 5000, 1, 10, 0),
				     1, 0);
    my $length = new Gtk::SpinButton(new Gtk::Adjustment(1, 1, 5000, 1, 10, 0),
				     1, 0);
    my $strand = new Gtk::CheckButton('Anti Strand');
    my $apply = new Gtk::Button('Apply');
    my $cancel = new Gtk::Button('Cancel');

    my $bbox = new Gtk::HButtonBox;

    $self->{'offset'} = $offset;
    $self->{'length'} = $length;
    $self->{'canvas'} = $canvas;
    $self->{'name'} = $name;

    $bbox->set_layout('end');
    $bbox->set_border_width(5);
    $vbox->set_border_width(5);
    $hbox->set_border_width(3);

    $hbox->pack_start_defaults(new Gtk::Label('Contig:'));
    $hbox->pack_start_defaults($combo);
    $hbox->pack_start_defaults(new Gtk::Label('Name:'));
    $hbox->pack_start_defaults($name);
    $hbox->pack_start_defaults($strand);
    $hbox->pack_start_defaults(new Gtk::Label('Offset:'));
    $hbox->pack_start_defaults($offset);
    $hbox->pack_start_defaults(new Gtk::Label('Length:'));
    $hbox->pack_start_defaults($length);
    $bbox->pack_start_defaults($apply);
    $bbox->pack_start_defaults($cancel);

    $vbox->pack_start(new Gtk::Label("Select ORF INCLUDING the stop codon!"), 0, 0, 3);
    $vbox->pack_start($hbox, 0, 0, 3);
    $vbox->pack_start(new Gtk::HSeparator, 0, 0, 3);
    $vbox->pack_start_defaults($canvas);
    $vbox->pack_start(new Gtk::HSeparator, 0, 0, 3);
    $vbox->pack_end($bbox, 0, 0, 3);

    $self->add($vbox);
    $self->set_default_size(400, 500);
    $self->{'start_mark'} = -1;
    $self->{'strand'} = 0;

    $combo->entry->signal_connect('changed', sub {
	my $contig = GENDB::contig->init_name($combo->entry->get_text);
	return if($contig == -1);
	$canvas->set_contig($contig);
	$offset->get_adjustment->upper($contig->length);
	$length->get_adjustment->upper($contig->length);
	$self->{'act_contig'} = $contig;
	$canvas->update;
    });

    $canvas->canvas->signal_connect( 'button_press_event', sub {
	if($_[1]->{'button'} == 1) {
	    my $spos = $canvas->world_to_sequence($_[1]->{'x'});
	    my $epos = 1;
	   
	    if($_[1]->{'state'} != 4) {
		$self->{'start_mark'} = $spos; 
		$offset->set_text( $spos );
	    } elsif( $_[1]->{'state'} == 4) {
		$self->{'start_mark'} = $offset->get_text;
		$epos = $spos - $self->{'start_mark'};
		return if( $spos == $self->{'stop_mark'} );
		$self->{'stop_mark'} = $spos;
	    }
	    $canvas->mark($self->{'start_mark'}, $spos, $self->{'strand'}) 
		if($epos > 0);
	} elsif($_[1]->{'button'} == 3) {
	    my $spos = $canvas->world_to_sequence($_[1]->{'x'});
	    my $epos = 1;
	   
	    $self->{'start_mark'} = $offset->get_text;
	    $epos = $spos - $self->{'start_mark'};
	    return if( $spos == $self->{'stop_mark'} );
	    $self->{'stop_mark'} = $spos;
	    $canvas->mark($self->{'start_mark'}, $spos, $self->{'strand'}) 
		if($epos > 0);
	} 
    });

    $canvas->canvas->signal_connect( 'motion_notify_event', sub {
	if($self->{'start_mark'} >= 0) {
	    my $spos = $canvas->world_to_sequence($_[1]->{'x'});
	    my $epos = $spos - $self->{'start_mark'};
	    return if( $spos == $self->{'stop_mark'} );
	    $self->{'stop_mark'} = $spos;
	    $canvas->mark($self->{'start_mark'}, $spos, $self->{'strand'})
		if($epos > 0);
	}
    });
    
    $canvas->canvas->signal_connect('button_release_event', sub {
	my $seq = $canvas->get_marked_seq;
	$length->set_text( length $seq );
	$self->{'start_mark'} = -1;
    });

    $offset->signal_connect('changed', sub { 
	my $offset = int($_[0]->get_text);
	if($offset > $self->{'act_contig'}->length) {
	    $offset = $self->{'act_contig'}->length;
	    $_[0]->set_text($offset);
	}
	$canvas->scroll_to_pos($offset-1);
	$canvas->mark($offset, $length->get_text + $offset, $self->{'strand'});
    });

    $length->signal_connect('changed', sub { 
	my $offset = $offset->get_text;
	$canvas->mark($offset, $length->get_text + $offset, $self->{'strand'});
    });

    $strand->signal_connect('toggled', sub {
	$self->{'strand'} = $strand->active; 
	my $offset = $offset->get_text;
	$canvas->mark($offset, $length->get_text + $offset, $self->{'strand'});
    });

    $apply->signal_connect('clicked', \&import_orf, $self);

    $cancel->signal_connect_object('clicked', $self, 'destroy');

    $combo->set_popdown_strings(@contigs);
    return $self;
}

sub show {
    my($self) = @_;
    $self->show_all;
    $self->{'canvas'}->update;
}

sub import_orf {
    my(undef, $self) = @_;
    my $start = $self->{'offset'}->get_text;
    my $stop  = $start + $self->{'length'}->get_text;
    my $contig = $self->{'act_contig'};
    my $frame = $start % 3;
    my $seq = $self->{'canvas'}->get_marked_seq;
    $frame++;
    $frame *= -1 if($self->{'strand'});


    my $startcodon = substr($seq, 0, 3);
    my $name = $self->{'name'}->get_text;
    if($name eq '') {
	my @all = keys %{$contig->fetchorfs};
	$name = sprintf ("%s_%004d",$contig->name,$#all+2);
    }

  Utils::show_yesno("Create Orf $name:\nStart = $start\nStop = $stop\nStartcodon = $startcodon", $self, sub{
      my $orf=GENDB::orf->create($contig->id,
				 $start + 1,
				 $stop,
				 $name);
      if ($orf < 0) { 
	Utils::show_error("can't create orf object for $name\n"); 
	  return;
      }

      $orf->status(0); # status is putative
      $orf->frame($frame);
      $orf->startcodon ($startcodon);
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
      
      # reset toollevel and order tools
      $orf->toollevel(0);
      for ($job_id = $orf->order_next_job; $job_id != -1;
	   $job_id = $orf->order_next_job) {
	  Job->create($GENDB::Config::GENDB_CONFIG, $job_id);
      }
      main->update_orfs;
      $self->hide;
      my $aedit = new AnnotationEditor;
      $aedit->set_orf($orf);
      $aedit->show_all;
      $self->destroy;
  }, sub{});
}
	

