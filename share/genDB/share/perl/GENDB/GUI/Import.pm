package GENDB::GUI::Import;

$VERSION = 1.4;

use GENDB::GUI::Utils;
use GENDB::Tools::Glimmer2;
use GENDB::contig;
use GENDB::orf;
use GENDB::Common;
use GENDB::Config;
use File::Basename;

####################################################
###                                              ###
### TODO:                                        ###
### - improve import contig subroutine           ###
### - include function call to update viewer     ###
###   after contig import (refresh contig list)  ###
### - enable import from EMBL file               ###
### - add more comments                          ###
### - implement wizards for automatic annotation ###
###                                              ###
####################################################

### 
# config area

my $config_dir_parameter_name='FASTA_dialog_dir';
my $contig_name_length=30;

# end of config area
###

####################################################
### import new contig from file and run glimmer2 ###
####################################################
sub add_contig {
    my ($call, $mainref, $finished_cb, $cancel_cb)=@_;
   
    $finished_cb = sub {} if(ref $finished_cb ne 'CODE');
    $cancel_cb = sub {} if(ref $cancel_cb ne 'CODE');

    my $dialog = new Gtk::Dialog;
    $dialog->title("Import new contig:");
    $dialog->set_modal(1);
    $dialog->set_position('mouse');

    my $import_box = new Gtk::VBox(0,0);
    $import_box->border_width(5);

    ### create entry for import data / file selection
    my $selection_box = new Gtk::HBox(0,0);
    my $file_label = new Gtk::Label("Import contig from file:");
    $selection_box->pack_start( $file_label, 1, 0, 0 );
    my $file_entry = new Gtk::Entry();
    $selection_box->pack_start( $file_entry, 1, 1, 5 );
    my $browse_button = new Gtk::Button("Browse...");
    $browse_button->signal_connect( 'clicked', \&import_filedialog, \$file_entry );
    my $help_box = new Gtk::VBox(1,0);
    $help_box->pack_start($browse_button, 0, 0, 0 );
    $selection_box->pack_start( $help_box, 0, 0, 0 );


    ### create frame for all import options
    my $frame = new Gtk::Frame("Configure glimmer options for import:");
    $frame->set_label_align(0.01, 0); 

    my $config_box = new Gtk::VBox(0,0);
    $config_box->border_width(5);
    
    my $use_long_button = new Gtk::RadioButton("use longest contig");
    $config_box->pack_start( $use_long_button, 1, 1, 0 );
    
    my $use_model_button = new Gtk::RadioButton("use model file:", $use_long_button);
    my $model_entry = new Gtk::Entry();
    $model_entry->set_sensitive(0);
    my $model_browse_button = new Gtk::Button("Browse...");
    $model_browse_button->set_sensitive(0);
    
    $use_long_button->signal_connect( 'clicked', sub { 
	$model_entry->set_text("");
	$model_entry->set_sensitive(0);
	$model_browse_button->set_sensitive(0);
    });
    $use_model_button->signal_connect( 'clicked', sub { 
	$model_entry->set_sensitive(1);
	$model_browse_button->set_sensitive(1);
    });

    $model_browse_button->signal_connect( 'clicked', \&import_filedialog, \$model_entry );
    my $model_box = new Gtk::HBox(0,0);
    $model_box->pack_start( $use_model_button, 0, 0, 0 );
    $model_box->pack_start( $model_entry, 1, 1, 5 );
    my $help_box2 = new Gtk::VBox(1,0);
    $help_box2->pack_start( $model_browse_button, 0, 0, 0 );
    $model_box->pack_start( $help_box2, 0, 0, 0 );
    $config_box->pack_start( $model_box, 1, 1, 0 );

    $config_box->pack_start( new Gtk::HSeparator(), 1, 1, 3 );
    my $update_button = new Gtk::CheckButton("update all contigs");
    $config_box->pack_start( $update_button, 1, 1, 0 );
    my $linear_button = new Gtk::CheckButton("import linear contig");
    $config_box->pack_start( $linear_button, 1, 1, 0 );
    my $code = $GENDB_CODON || 0;	
    $config_box->pack_start( new Gtk::Label( "Using genetic code $code!" ), 1, 1, 0 );
    $frame->add($config_box);
   
    $import_box->pack_start( $selection_box, 1, 1, 0 );
    $import_box->pack_start( new Gtk::HSeparator(), 1, 1, 3 );
    $import_box->pack_end( $frame, 1, 1, 0 );

    ### Put buttons into HButtonBox
    my $button_box = new Gtk::HButtonBox();
    $button_box->set_layout_default('spread');
    my $ok_button = new Gtk::Button("Import contig...");
    $ok_button->signal_connect( 'clicked', sub {
	my $import_file=$file_entry->get_text();
	if ($import_file ne "") {
	    $dialog->destroy;
	    &import_contig($mainref, $import_file, $update_button->active, $linear_button->active, $model_entry->get_text(), $finished_cb);
	}
	else {
	  Utils::show_error("Import error: No import data specified!", $dialog);
	};
    });
    
    my $cancel_button = new Gtk::Button("Cancel");
    $cancel_button->signal_connect( 'clicked', sub { 
	&$cancel_cb;
	$dialog->destroy; 
    } );

    $button_box->add($ok_button);
    $button_box->add($cancel_button);

    $dialog->vbox->add($import_box);
    $dialog->action_area->add($button_box);   
    
    $dialog->show_all;
};


#####################################
### create file dialog for import ###
#####################################
sub import_filedialog {
    my ($widget, $entry)=@_;

    my $dirname = GENDB::Tools::UserConfig->get_parameter($config_dir_parameter_name);
    if (!$dirname) {
	# set directory to home directory
	$dirname = $ENV{'HOME'}."/";
    }
    my $file_dialog = new Gtk::FileSelection( "Select file with new contig data" );
    $file_dialog->hide_fileop_buttons();
    $file_dialog->set_modal(1);
    $file_dialog->set_filename($dirname);
    $file_dialog->signal_connect( "destroy", sub { $file_dialog->destroy; });

    # Connect the ok_button to file_ok_sel function
    $file_dialog->ok_button->signal_connect( "clicked", \&file_ok_sel, $file_dialog, $entry );
                  
    # Connect the cancel_button to destroy the widget
    $file_dialog->cancel_button->signal_connect( "clicked", sub { $file_dialog->destroy; });
    
    $file_dialog->show();
};


#############################
### get selected filename ###
#############################
sub file_ok_sel {
    my ($widget, $fd, $entry_ref)=@_;
    
    my $entry=$$entry_ref;
    my $file=$fd->get_filename();
    $entry->set_text($file);
    $fd->destroy;

    # update user configuration to restore 
    # selected path next time this dialog
    # is used
  GENDB::Tools::UserConfig->set_parameter($config_dir_parameter_name,
					  dirname ($file)."/");
};


########################################
### import contig from selected file ###
###         ATTENTION:               ###
### still some weird BL code in here ###
########################################
sub import_contig {
    my ($mainref, $import_file, $updateall, 
	$linear_contig, $model_file, $finished_cb) = @_;

    my $main=$$mainref;
    my $win=$main->get_parent_window;

    stat ($import_file);
    if (! -r _) {
			Utils::show_error("Cannot read contig file $import_file!");
			return;
    }

    if ($model_file ne "") {
			stat ($model_file);
			if (! -r _) {
	    	Utils::show_error("Cannot read model file $model_file!");
	    	return;
			}
    }
    my $newsequences = read_fasta_file($import_file);

    main->update_statusbar("Reading sequence(s) from file... ");
    ### main->busy_cursor($main, 1);
    my $cursor = Gtk::Gdk::Cursor->new(150);
    $win->set_cursor($cursor);
    Gtk->main_iteration while ( Gtk->events_pending );
    
    my $glimmer = GENDB::Tools::Glimmer2->new();
    
    if ($model_file ne "") {
	$glimmer->model_file($model_file);
    };
    # tell the user whats going on...
    my $msg="";
    $glimmer->statusmessage(\$msg);
    
    #include new sequences into database...
    foreach $seq (keys %$newsequences) {
	my $new_contig=GENDB::contig->create($seq, $$newsequences{$seq});
	$new_contig->length(length $$newsequences{$seq});
	### BUGFIX: DO NOT CONTINUE with import when contig name ne to imported contig name in DB
	my $cid=$new_contig->id;
	my $real_contig=GENDB::contig->init_id($cid);
	if ($seq ne $real_contig->name) {
	    my $l=length($real_contig->name) - 5;
	    Utils::show_error("Contigname too long!\nShorten contig name in input data (should be < $l chars) and try again!");
	    $real_contig->delete;
	    $win->set_cursor(Gtk::Gdk::Cursor->new(68));
	    $cursor=undef;
	    main->update_statusbar("Aborted import of contig!");
	    ### main->busy_cursor($main, 0);
	    return;
	};
    };
    
    ### $glimmer->verbose(1);

    if ($updateall == 1) {
	# inserts all contigs to glimmer object
	foreach $contig (@{GENDB::contig->fetchall}) {
	    $glimmer->add_sequence($contig->name, $contig->sequence);
	}	
    }
    else {
	foreach $seq (keys %$newsequences) {
	    $glimmer->add_sequence($seq, GENDB::contig->init_name($seq)->sequence);
	}
    };

    if ($linear_contig == 1) {
	$glimmer->linear_contig(1);
    }
    else {
	$glimmer->linear_contig(0);
    };

    main->update_statusbar("Running glimmer2... ");
    Gtk->main_iteration while ( Gtk->events_pending );
    $glimmer->run_glimmer();

    main->update_statusbar("Updating database... ");
    Gtk->main_iteration while ( Gtk->events_pending );

    my %contigs;

    $orfs_ref = $glimmer->orfs;

    # get annotator for glimmer import
    my $annotator = GENDB::annotator->init_name("glimmer");
    if ($annotator == -1) {
	# create a default glimmer annotator
	print "*** Creating default glimmer annotator! ***\n";
	$annotator = GENDB::annotator->create();
	$annotator->name("glimmer");
	$annotator->description("Glimmer ORF finder");
    };

  foreach $seq (keys %$orfs_ref) {
		my $contig = $contigs{$seq};
		if(!defined $contig) {
	    $contig = GENDB::contig->init_name($seq);
	    $contigs{$seq} = $contig;
		}
	
		if ($contig < 0) {
	    die "Cannot get contig $seq.....\n";
		}

	# get a list of ORFs stored in DB 
	# and a list of all predicted ORFs
	my @orfs_in_db = sort {$a->start <=> $b->start} values (%{$contig->fetchorfs});
	my @generated_orfs = @{$orfs_ref->{$seq}};
	@generated_orfs = sort {$a->{'from'} <=> $b->{'from'}} @generated_orfs;

	# this is a mean hack
	# we need to know the highest id allready stored in db
	# (id = "<sequencename>_000x")
	my $next_orf_id =0;
	foreach (@orfs_in_db) {
	    my ($junk,$orf_id) = split "_", $_->name();
	    $next_orf_id = $orf_id if ($orf_id > $next_orf_id);
	}
	$next_orf_id++;

        # lets do a cross check of both lists
	# new ORFs (ORF not in db) shall be created,
	# old ORFs (ORF in db, but not in @generated_orfs)
	# are marked "attention needed"
	for ($i=0; $i < scalar(@generated_orfs); $i++) {
		if (defined ($orfs_in_db[0])) {
			while ($orfs_in_db[0]->start < $generated_orfs[$i]->{'from'}) {
		    
		    # annotated and finished are not touched by this

		    if (($orfs_in_db->state != $ORF_STATE_ATTENTION_NEEDED) ||
			($orfs_in_db->state != $ORF_STATE_IGNORED) ||
			($orfs_in_db->state != $ORF_STATE_ANNOTATED) ||
			($orfs_in_db->state != $ORF_STATE_FINISHED)) {
			# these ORFs has been deprecated, so mark them
			$orfs_in_db[0]->status($ORF_STATE_ATTENTION_NEEDED);
			my $annotation=GENDB::annotation->create('',$orfs_in_db[0]->id);
			if ($annotation < 0) {
			    die "can't create annotation object for $annotation\n";
			}
			
			# set annotator to glimmer
			$annotation->annotator_id($annotator->id);
			$annotation->description('ORF was deprecated by another glimmer2-run');
			$annotation->date(time());
		    }	
		    
		    shift @orfs_in_db;
		}
		
		# both orfs got the same start position,	   
		if ($orfs_in_db[0]->start == $generated_orfs[$i]->{'from'}) {
		    if ($orfs_in_db[0]->stop == $generated_orfs[$i]->{'to'}) {
			# if start and stop position are the same,
			# this orf is already in database
			shift @orfs_in_db;
			next;
		    }
		}
	    }
	    my $orf_data = $generated_orfs[$i];
	    
	    # create a new orf
	    my $orf_prefix = "C".$contig->id;
	    my $orfname=sprintf ("%s_%004d",$orf_prefix,$next_orf_id);
	    $next_orf_id++;
	    
	    my $orf=GENDB::orf->create($contig->id,
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
	    # set comment to glimmer comment
	    if (defined $comment) {
		$annotation->comment($comment);
	    }
	    $annotation->name($orfname);
	    $annotation->description('ORF created by glimmer2');
	    $annotation->date(time());
	}
 }

    &$finished_cb(values %contigs);

    $win->set_cursor(Gtk::Gdk::Cursor->new(68));
    $cursor=undef;
    main->update_statusbar("Import of contig successfully finished!");
    ### main->busy_cursor($main, 0);
    main->update_contigs;
};



1;
