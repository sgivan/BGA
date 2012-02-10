package GENDB::GUI::PredictionDialog;

use Data::Dumper;

use Gtk;
use GENDB::contig;
use lib '/vol/bioinfo/src/Geneprediction/Gendb/';
use OrfPrediction::Glimmer;
use OrfPrediction;

use vars qw(@ISA);

@ISA = qw(Gtk::Dialog);

my @predictors = qw(Glimmer Critica Orpheus Genemark);

sub new {
    my($class, $contig_names) = @_;
    my $self = $class->SUPER::new;
    bless $self, $class;

    $self->{'glimmer_config'} = { 'linear_contig' => 0,
				  'use_rbs_pattern'   => 0,
				  'use_rbs_pattern' => 0,
				  'rbs_pattern' => '',
				  'train_contigs' => {},
				  'train_method' => 'Long Orfs' };

    $self->{'used Tools'} = { 'Glimmer' => -1,
			      'Critica' => 0,
			      'Orpheus' => 0,
			      'Genemark' => 0 };

    my %new_contigs;
    foreach(@$contig_names) {
	$new_contigs{$_} = 1;
    }

    $self->{'contig_names'} = \%new_contigs;  

    $self->set_title("Gene Prediction");
    $self->set_position('center');
    $self->vbox->set_border_width(5);
    $self->vbox->set_spacing(3);
    
    my $label = new Gtk::Label("Start GenePrediction with:");
    $label->parse_uline("_S_t_a_r_t_ _G_e_n_e_P_r_e_d_i_c_t_i_o_n_ _w_i_t_h_:_");
    $self->vbox->pack_start_defaults($label);
    foreach(@predictors) {
	my $hb = $self->make_selection($_, ($_ eq "Glimmer"));
	$self->vbox->pack_start_defaults($hb);
	$hb->set_sensitive(0) if($_ eq "Critica" || $_ eq "Orpheus" || $_ eq "Genemark");
    }

    my $bb = new Gtk::HButtonBox;
    my $ok = new Gtk::Button("Start");
    my $cancel = new Gtk::Button("Cancel");

    $bb->pack_start_defaults($ok);
    $bb->pack_start_defaults($cancel);

    $self->action_area->add($bb);
    $self->{'functions'} = [];

    $ok->signal_connect('clicked', sub { $self->start_prediction });
    $cancel->signal_connect('clicked', sub { $self->destroy });

    return $self;
}

sub run_after_prediction {
    my($self, $code_ref) = @_;
    return if(ref $code_ref ne "CODE");
    push( @{$self->{'functions'}}, $code_ref);
}

sub start_prediction {
    my($self) = @_;
    
    foreach(@predictors) {
	if($self->{'used Tools'}->{$_} == 1) {
	    $self->{'used Tools'}->{$_} = 0;
	    my $func = "run_$_";
	    $self->$func();
	} elsif($self->{'used Tools'}->{$_} == -1) {
	  Utils::show_error("Please Configure $_");
	    return;
	}
    }
    foreach(@{$self->{'functions'}}) {
	&$_();
    }
}

sub make_predict_sequences {
    my($self) = @_;

    my $fetch = '0';

    foreach(sort keys %{$self->{'contig_names'}}) {
	$fetch .= " OR name = \"$_\"";
    }

    my $sequence = GENDB::contig->fetchbySQL($fetch);
    my %sequences;
    foreach my $sequence_obj (@$sequence) {
	$sequences{$sequence_obj->name()} = $sequence_obj->sequence();
    }

    return \%sequences;
}

sub make_train_sequences {
    my($self) = @_;

    my $fetch = '0';

    foreach(sort keys %{$self->{'glimmer_config'}->{'train_contigs'}}) {
	$fetch .= " OR name = \"$_\"";
    }

    my $sequence = GENDB::contig->fetchbySQL($fetch);
    my %sequences;
    foreach my $sequence_obj (@$sequence) {
	$sequences{$sequence_obj->name()} = $sequence_obj->sequence();
    }

    return \%sequences;
}

sub run_Critica {
    my($self) = @_;
}

sub run_Orpheus {
    my($self) = @_;
}

sub run_GeneMark {
    my($self) = @_;
}

sub run_Glimmer {
    my($self) = @_;

    my $train_sequences = $self->make_train_sequences;
    my $predict_sequences = $self->make_predict_sequences;
    
    my $glimmer_obj = new OrfPrediction::Glimmer;
    $glimmer_obj->verbose(1);
    $glimmer_obj->linear_contig($self->{'glimmer_config'}->{'linear_contig'});
    $glimmer_obj->rbs4startprediction($self->{'glimmer_config'}->{'use_rbs_pattern'});
    $glimmer_obj->RBSPattern($self->{'glimmer_config'}->{'rbs_pattern'}) if($self->{'glimmer_config'}->{'use_rbs_pattern'});
 
    if($self->{'glimmer_config'}->{'train_method'} eq 'Long Orfs') {
	$glimmer_obj->train_glimmer_with_long_orfs($train_sequences);
    } elsif($self->{'glimmer_config'}->{'train_method'} eq 'use Glimmer') {
	$self->{'used Tools'}->{'Glimmer'} = 0;
    }elsif($self->{'glimmer_config'}->{'train_method'} eq 'use Critica') {
	$self->{'used Tools'}->{'Critica'} = 0;
    } 
    $glimmer_obj->run_glimmer($predict_sequences);
    $glimmer_obj->orfs2db($predict_sequences);
}

sub make_selection {
    my($self, $toolname, $on) = @_;

    my $hbox = new Gtk::HBox(1, 1);
    $hbox->set_border_width(5);
    $hbox->set_spacing(3);
    my $check = new Gtk::CheckButton($toolname);
    $check->set_active($on);
    my $button = new Gtk::Button("Preferences");
    my $label = new Gtk::Label($on ? "Please Configure" : "not Used");

    $hbox->pack_start_defaults($check);
    $hbox->pack_start_defaults($button);
    $hbox->pack_start_defaults($label);

    $button->signal_connect('clicked', sub {
	$self->open_configuration($toolname, sub {
	    my($ok) = @_;
	    $label->set_text(($ok != -1) ? "OK" : "Please Configure");
	    $self->{'used Tools'}->{$toolname} = $ok;
	}, 
				  sub { $label->set_text("Please Configure") }) if($check->active);
    });

    $check->signal_connect('toggled', sub {
	if($check->active) {
	    $label->set_text("Please Configure");
	} else {
	    $label->set_text("not Used");
	}
    });

    return $hbox;
}

sub open_configuration {
    my($self, $type, $ok_ref, $cancel_ref) = @_;
    my $ok = -1;
    my $func = "make_".$type."_config";
    
    my $dia = new Gtk::Dialog;
    $dia->set_title("$type Configuration");
    $dia->set_modal(1);
    
    $dia->vbox->pack_start_defaults($self->$func(\$ok));

    my $bb = new Gtk::HButtonBox;
    my $okbutton = new Gtk::Button("OK");
    my $cancel = new Gtk::Button("Cancel");

    $bb->pack_start_defaults($okbutton);
    $bb->pack_start_defaults($cancel);

    $dia->action_area->add($bb);

    $okbutton->signal_connect('clicked', sub { &$ok_ref($ok); $dia->destroy });
    $cancel->signal_connect('clicked', sub { &$cancel_ref(); $dia->destroy });

    $dia->set_default_size(500, 400) if($type eq "Glimmer");

    $dia->set_position('center');
    $dia->show_all;
}

sub make_Glimmer_config {
    my($self, $ok) = @_;
    my $hbox = new Gtk::HBox(1, 5);
    my $vbox = new Gtk::VBox(0, 0);
    $vbox->set_border_width(5);

    my $linear_contigs = new Gtk::CheckButton('Use linear Contigs');
    $linear_contigs->set_active($self->{'linear_contig'});

    my $use_rbs_pattern = new Gtk::CheckButton('Use RBS Pattern');
    $use_rbs_pattern->set_active($self->{'use_rbs_pattern'});

    my $hb1 = new Gtk::HBox(0, 3);

    my $rbs_pattern = new Gtk::Entry;
    $rbs_pattern->set_sensitive(0);
    $hb1->pack_start($use_rbs_pattern, 0, 0, 1);
    $hb1->pack_start($rbs_pattern, 0, 0, 1);

    my $hb = new Gtk::HBox(0, 3);
    my $method = new Gtk::Combo;
    $method->set_popdown_strings("Long Orfs", "Use Glimmer", "Use Critica");
    $hb->pack_start(new Gtk::Label("Training Method:"), 0, 0, 1);
    $hb->pack_start($method, 0, 0, 1);
    
    foreach($linear_contigs, $hb1, $hb) {
	$vbox->pack_start($_, 0, 0, 3);
    }

    my $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy('automatic', 'automatic');

    my $list = new_with_titles Gtk::CList('Select Training Contigs');
    $list->set_selection_mode('multiple');
    $scroller->add($list);

    my $frame = new Gtk::Frame('Options');
    $frame->set_border_width(5);
    $frame->add($vbox);

    $hbox->pack_start($frame, 0, 0, 3);
    $hbox->pack_start($scroller, 1, 1, 3);

    $linear_contigs->signal_connect('toggled', sub {
	$self->{'glimmer_config'}->{'linear_contig'} = $linear_contigs->active;
    });

    $use_rbs_pattern->signal_connect('toggled', sub {
	$rbs_pattern->set_sensitive($use_rbs_pattern->active);
	$self->{'glimmer_config'}->{'use_rbs_pattern'} = $use_rbs_pattern->active;
	if($use_rbs_pattern->active && $rbs_pattern->get_text eq "") {
	    $$ok = 0;
	} elsif(!$use_rbs_pattern->active && defined $list->selection) {
	    $$ok = 1;
	}
    });
    
    $rbs_pattern->signal_connect('changed', sub {
	$self->{'glimmer_config'}->{'rbs_pattern'} = $rbs_pattern->get_text;
	if($self->{'glimmer_config'}->{'rbs_pattern'} ne "" && defined $list->selection) {
	    $$ok = 1;
	} else {
	    $$ok = 0;
	}
    });

    $method->entry->signal_connect('changed', sub {
	$self->{'glimmer_config'}->{'train_method'} = $method->entry->get_text;
    });

    $linear_contigs->set_active($self->{'glimmer_config'}->{'linear_contig'});
    $use_rbs_pattern->set_active($self->{'glimmer_config'}->{'use_rbs_pattern'});
    $rbs_pattern->set_text($self->{'glimmer_config'}->{'rbs_pattern'});
    $method->entry->set_text($self->{'glimmer_config'}->{'train_method'});
    $list->signal_connect('select_row', sub {
	my($l, $r, $c) = @_;
	my $selection = $l->get_text($r, 0);
	$self->{'glimmer_config'}->{'train_contigs'}->{$selection} = 1;
	$$ok = 1;
    });
    $list->signal_connect('unselect_row', sub {
	my($l, $r, $c) = @_;
	my $selection = $l->get_text($r, 0);
	delete $self->{'glimmer_config'}->{'train_contigs'}->{$selection};
	if(defined $l->selection) {
	    $$ok = 1;
	} else {
	    $$ok = 0;
	}
    });

    my $i = 0;
    foreach(sort keys %{GENDB::contig->contig_names}) {
#	if(!$self->{'contig_names'}->{$_}) {
	$list->append($_);
	if($self->{'glimmer_config'}->{'train_contigs'}->{$_}) {
	    $list->select_row($i, 0);
	}
	$i++;
#	}
    }
    return $hbox;
}

sub make_Critica_config {
    my($self, $ok) = @_;
    my $vbox = new Gtk::VBox(1, 1);
    my $check = new Gtk::CheckButton('Use Critica');
    $vbox->add($check);
    $check->signal_connect('toggled', sub { $$ok = $check->active });
    return $vbox;
}

sub make_Orpheus_config {
    my($self, $ok) = @_;
    my $vbox = new Gtk::VBox(1, 1);
    my $check = new Gtk::CheckButton('Use Orpheus');
    $vbox->add($check);
    $check->signal_connect('toggled', sub { $$ok = $check->active });
    return $vbox;
}

sub make_Genemark_config {
    my($self, $ok) = @_;
    my $vbox = new Gtk::VBox(1, 1);
    my $check = new Gtk::CheckButton('Use Genemark');
    $vbox->add($check);
    $check->signal_connect('toggled', sub { $$ok = $check->active });
    return $vbox;
}
