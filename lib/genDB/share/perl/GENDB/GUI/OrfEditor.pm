package OrfEditor;

($GENDB::GUI::OrfEditor::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

# this package provides an interface to manipulate
# the start position of ORFs

use GENDB::contig;
use GENDB::orf;
use GENDB::Common;
use GENDB::fact;
use GENDB::orfstate;
use GENDB::annotation;
use GENDB::annotator;
use GENDB::GUI::Utils;
use GENDB::GUI::SequenceCanvas;
use GENDB::Tools::genetic_codes;

use Job;

####################################################
###                                              ###
### TODO:                                        ###
### - include function call to update viewer     ###
###   after orf edit operation (refresh orfview) ###
### - add more comments                          ###
###                                              ###
####################################################

###############################################
### open orf editor window for selected orf ###
###############################################
sub orf_editor {
    my ($call, $orfname)=@_;
    
    my $self;
    # get the objects and init internal data
    $self->{orf} = GENDB::orf->init_name($orfname);
    my $contig = GENDB::contig->init_id($self->{orf}->contig_id);
    if ($self->{orf}->frame > 0) {
	$self->{sequence} = $contig->sequence;
	$self->{startposition} = $self->{orf}->start;
	$self->{stopposition} = $self->{orf}->stop;
    } 
    else {
	$self->{sequence} = complement ($contig->sequence);
	$self->{startposition} = $self->{orf}->stop;
	$self->{stopposition} = $self->{orf}->start;
    };

    my $dialog = new Gtk::Dialog;
    $dialog->title("ORF Editor");
    $dialog->set_position('center');

    my $editor_box = new Gtk::VBox(0,0);
    $editor_box->border_width(5);

    ### create frame for current settins of ORF
    my $frame = new Gtk::Frame("Current settings:");
    $frame->set_label_align(0.01, 0); 

    my $settings_box = new Gtk::VBox(0,0);
    $settings_box->border_width(5);    

    $editor_box->pack_start( $frame, 1, 1, 0 );
    
    $self->{sequencelength} = length ($self->{sequence});
    $self->{oldstartposition} = $self->{startposition};
    $self->{startcodon} = $self->{orf}->startcodon;
    $self->{oldstartcodon} = $self->{startcodon};
    $self->{frame} = $self->{orf}->frame;

    ### add some labels for current settings of selected orf
    my $infolabel = new Gtk::Label("Old start position : $self->{oldstartposition}\nOld stop position : $self->{stopposition}\nOld start codon : $self->{oldstartcodon}\nFrame: ".$self->{orf}->frame);
    $infolabel->set_justify('left');
    $settings_box->pack_start($infolabel, 1, 1, 0);
    $frame->add($settings_box);
    
    ### Put buttons into HBox for prev / next start codon
    my $startcodon_box = new Gtk::HBox(1, 1);
    my $prev_sc_button = new Gtk::Button("Previous startcodon");
    $prev_sc_button->signal_connect( 'clicked', \&codonsearch, $self, -1);
    
    my $next_sc_button = new Gtk::Button("Next startcodon");
    $next_sc_button->signal_connect( 'clicked', \&codonsearch, $self, 1 );
    $startcodon_box->pack_start($prev_sc_button, 1, 1, 0);
    $startcodon_box->pack_start($next_sc_button, 1, 1, 0);
    $editor_box->pack_start($startcodon_box, 1, 1, 0);

    ### Put buttons into HButtonBox for prev / next ATG
    my $atg_button_box = new Gtk::HBox(1, 1);
    my $prev_atg_button = new Gtk::Button("Previous ATG");
    $prev_atg_button->signal_connect( 'clicked', \&codonsearch, $self, -1, 1 );
    
    my $next_atg_button = new Gtk::Button("Next ATG");
    $next_atg_button->signal_connect( 'clicked', \&codonsearch, $self, 1, 1 );
    $atg_button_box->pack_start($prev_atg_button, 1, 1, 0);
    $atg_button_box->pack_start($next_atg_button, 1, 1, 0);
    $editor_box->pack_start($atg_button_box, 1, 1, 0);
    
    ### Add sequence viewer
    my $baseview = new SequenceCanvas;
    $baseview->set_contig( $contig );
    $baseview->set_usize( 600, 350 );
    $self{ 'baseview' } = $baseview;
    $editor_box->pack_start($baseview, 1, 1, 0);

    $self->{ 'start_pos' } = new Gtk::Entry();
    $self->{ 'start_pos' }->set_editable( 0 );
    $self->{ 'start_codon' } = new Gtk::Entry();
    $self->{ 'start_codon' }->set_editable( 0 );

    my $statusbox = new Gtk::HBox(0, 0);
    $statusbox->pack_start(new Gtk::Label("New start position:"), 0, 0, 0);
    $statusbox->pack_start($self->{ 'start_pos' }, 0, 0, 0);
    $statusbox->pack_start(new Gtk::Label("New start codon:"), 0, 0, 0);
    $statusbox->pack_start($self->{ 'start_codon' }, 0, 0, 0);

    $editor_box->pack_start($statusbox, 1, 1, 0);
    
    ### Put buttons into HButtonBox
    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("Update orf");
    $ok_button->signal_connect( 'clicked', \&updateORF, $self, $dialog );
    
    my $cancel_button = new Gtk::Button("Cancel");
    $cancel_button->signal_connect( 'clicked', sub { 
	&setstartposition($self, $self->{oldstartposition});
	$dialog->destroy;
    } );

    $button_box->add($ok_button);
    $button_box->add($cancel_button);

    $dialog->vbox->add($editor_box);
    $dialog->action_area->add($button_box);   
    
    $dialog->show_all;
    $baseview->hilite( $self->{'orf'} );
};

1;

sub updateposition {
    my ($entry, $self) = @_;
    if (($self->{startposition}) && 
	($self->{startposition} == int ($self->{startposition}))) {
	
	setstartposition($self, $self->{startposition});

	$self->{ 'start_pos' }->set_text( $self->{startposition} );
	$self->{ 'start_codon' }->set_text( $self->{startcodon} );
	
	$self{ 'baseview' }->scroll_to_pos( $self->{startposition} - 50 );
    }
}

# revert all changes
sub discardchanges {

    my( $self ) = @_;

    $self->setstartposition($self->{oldstartposition});
    $self->parent->destroy;
}

sub updateORF {

    my( undef, $self, $dialog ) = @_;

    &setstartposition($self, $self->{startposition});

    if (($self->{startposition} != $self->{oldstartposition}) ) {

	### compute new molweight and iep
	my $orf = $self->{orf};
	my $orf_aaseq = $orf->aasequence();
	$orf->isoelp(GENDB::Common::calc_pI($orf_aaseq));

	# there's a name clash !
	# calling $orf->molweight uses GENDB::Common::molweight
	# damnit importing of symbols !
	# we should fix this as soon as possible
	# IC IC IC IC IC 
	my $molweight = GENDB::Common::molweight($orf_aaseq);
      GENDB::orf::molweight($orf, $molweight);

	Utils::show_yesno("ORF start position has been changed, delete old facts and rerun tools ?", 
		   $self,
		   sub{ &make_new_facts( $self ); main->update_orfs; $dialog->destroy },
		   sub{  }
		   );
    }

}

sub make_new_facts {
    my( $self ) = @_;

    main->update_statusbar( "Rerunning Tools for ORF: ".$self->{orf}->name );

    $self->{orf}->drop_facts;
    
    # create an annotation entry
    my $annotator = GENDB::annotator->init_name($ENV{'USER'});
    my $annotation = GENDB::annotation->create("", $self->{orf}->id);
    $annotation->annotator_id ($annotator->id);
    $annotation->date(time);
    $annotation->description("ORF start position changed");
    $annotation->comment("Start position changed from ".$self->{oldstartposition}." to ".$self->{startposition});

    # editing the orf start position is an annotation
    $self->{orf}->status($ORF_STATE_ANNOTATED);
    

    # reset toollevel and order tools
    $self->{orf}->toollevel(0);
    for ($job_id = $self->{orf}->order_next_job; $job_id != -1;
	 $job_id = $self->{orf}->order_next_job) {
	Job->create($GENDB::Config::GENDB_CONFIG, $job_id);
    }
}


sub setstartposition {
    my ($self, $newposition) = @_;

    if ($self->{frame} > 0) {
	if (($newposition < $self->{stopposition}) &&
	    (($self->{stopposition} - $newposition) % 3 == 2)) {
	    $self->{orf}->start($newposition);
	    $self->{startposition} = $newposition;
	    $self->{orf}->startcodon(substr ($self->{orf}->sequence, 0, 3));
	    $self->{startcodon} = $self->{orf}->startcodon;
	}
    }
    elsif (($newposition > $self->{stopposition}) &&
	   (($newposition - $self->{stopposition}) % 3 == 2)) {
	$self->{orf}->stop($newposition);
	$self->{startposition} = $newposition;
	$self->{orf}->startcodon(substr ($self->{orf}->sequence, 0, 3));
	$self->{startcodon} = $self->{orf}->startcodon;
    }
}

# change the start position to point to another 
# start codon
sub codonsearch {
    my (undef, $self, $direction, $onlyATG) = @_;
    
    # direction is 1 for next codon, -1 for previous codon
    my $starts = GENDB::Tools::genetic_codes->get_start_codons();
    my $stops = GENDB::Tools::genetic_codes->get_stop_codons();
    
    # define default values as a fallback
    if (!$starts) {
	$starts = "ATG|GTG|TTG";
    };
   
    if (!$stops) {
	$stops = "TAG|TAA|TGA";
    };

    # predefined pattern for start and stopcodons;
    my $startpattern = (defined($onlyATG)) ? "ATG":
	    #"ATG|CTG|GTG|TTG";
	$starts;
            #"ATG|GTG|TTG"; 
            # bei Next Start Codon sollten nur ATG(Met), GTG(Val) und TTG(Leu)
            # genommen werden, nicht auch andere Leu-Kodons.
    my $stoppattern = $stops; #"TAG|TAA|TGA";

    # direction is positive while searching from 5' to 3' on reverse strand
    if( ($direction > 0) && ($self->{frame} < 0) ) {
	$direction = -1;
    } elsif( ($direction < 0) && ($self->{frame} < 0) ) {
	$direction = 1;
    }

    # build search pattern according to frame and direction
    my $searchpattern = $startpattern."|".$stoppattern;
    if ((($direction > 0) && ($self->{frame} < 0)) ||
	(($direction < 0) && ($self->{frame} > 0))) {
	$searchpattern = reverse ($searchpattern);
	$stoppattern = reverse($stoppattern);
    }
    $searchpattern = '('.$searchpattern.')';
    $stoppattern = '('.$stoppattern.')';

    my $searchstring="";
    if ($direction > 0) {

	# build the searchstring and set search start position
	$searchstring = $self->{sequence};
	pos $searchstring = $self->{startposition} + 1;
	
	while ($searchstring =~ /$searchpattern/gi) {
	    # pos returns the first base after the startcodon
	    my $hit = pos $searchstring;
	    
	    # pattern may overlap..so start next search at next base
	    pos $searchstring = $hit - 2;

	    # test whether the hit is on the same frame
	    if ($self->{frame} > 0) {
		next if ((($hit - $self->{startposition}) % 3) != 2);
	    }
	    else {
		next if ((($hit - $self->{startposition}) % 3) != 0);
	    }
	    if ($self->{frame} > 0) {
		#adjust position
		$hit -= 2;

		# valid hit ?
		if ($hit < $self->{stopposition}) {

		    # hit a stopcodon ?
		    if ($1 =~ /$stoppattern/i) {
			if ($onlyATG) {
			    Utils::show_information("No ATG before next stop codon.",$self);
			    last;
			}
			else {
			    Utils::show_information("No start codon before next stop codon",$self);
			    last;
			}
		    }
		    else {
			# update position
			$self->{startposition} = $hit;
			last;
		    }
		}
		else {
		    Utils::show_information ("Stop codon reached.", $self);
		    last;
		}
	    }
	    else {
		if ($1 =~ /$stoppattern/i) {
		    if ($onlyATG) {
			Utils::show_information("No ATG before next stop codon.",$self);
			last;
		    }
		    else {
			Utils::show_information("No start codon before next stop codon",$self);
			last;
		    }
		}
		else {
		    $self->{startposition}=$hit;
		    last;
		}
	    }
	}
    }
    else {
	# we are searching from right to left,
	# so reverse search string and start position
	$searchstring = reverse ($self->{sequence});
	pos $searchstring = $self->{sequencelength} - $self->{startposition} + 1;

	while ($searchstring =~ /$searchpattern/gi) {
	    # pos returns the first base after the startcodon
	    my $hit = pos $searchstring;

	    # pattern may overlap..so start next search at next base
	    pos $searchstring = $hit - 2;
	    $hit = $self->{sequencelength} - $hit;

	    # skip hits on other frames
	    if ($self->{frame} > 0) {
		next if ((($hit - $self->{startposition}) % 3) != 2);
	    }
	    else {
		next if ((($hit - $self->{startposition}) % 3) != 0);
	    }
	    if ($self->{frame} > 0) {
		$hit += 1;
		if ($1 =~ /$stoppattern/i) {
		    if ($onlyATG) {
			Utils::show_information("No ATG before next stop codon.", $self);
			last;
		    }
		    else {
			Utils::show_information("No start codon before next stop codon", $self);
			last;
		    }
		}
		else {
		    $self->{startposition} = $hit;
		    last;
		}
	    }
	    else {
		if ($self->{stopposition} < $hit) {
		    if ($1 =~ /$stoppattern/) {
			if ($onlyATG) {
			    Utils::show_information("No ATG before next stop codon.",$self);
			    last;
			}
			else {
			    Utils::show_information("No start codon before next stop codon",$self);
			    last;
			}
		    }
		    else {
			$self->{startposition} = $hit + 3;
			last;
		    }
		}
		else {
		    Utils::show_information("Stop codon reached.", $self);
		    last;
		}
	    }
	}
    }
    updateposition ($self, $self);
}

