package UserConfDialog;

use GENDB::GENDB_CONFIG;
use Gtk;
use GENDB::Tools::UserConfig;
use GENDB::tool;
use vars qw(@ISA);

@ISA = qw(Gtk::Dialog);

my $SHOWN = 0;

###########################################
###                                     ###
### Dialog to change user configuration ###
###                                     ###
###########################################

sub new {
    my( $class ) = @_;
    return -1 if($SHOWN);
    my $self = $class->SUPER::new;
    bless $self, $class;

    $self->set_title( 'User Configuration' );
    $self->set_default_size( 400, 300 );

    my $notebook = new Gtk::Notebook;

    $self->factview_config( $notebook );
    $self->signalp_config( $notebook ) if(defined $GENDB::GENDB_CONFIG::GENDB_SIGNALP);
    $self->browser_config( $notebook );
    $self->orflist_config( $notebook );
    $self->vbox->add( $notebook );
    my $bb = new Gtk::HButtonBox;
    my $close = new Gtk::Button( 'Close' );
    my $apply = new Gtk::Button( 'Apply' );
    $bb->set_layout( 'spread' );
    $bb->pack_start_defaults( $close );
    $bb->pack_start_defaults( $apply);

    $self->action_area->add( $bb );
    
    $close->signal_connect( 'clicked', sub { $SHOWN = 0; $self->destroy } );
    $apply->signal_connect( 'clicked', sub {
	$self->apply_signalp if(defined $GENDB::GENDB_CONFIG::GENDB_SIGNALP);
	$self->apply_factview;
	$self->apply_browser;
	if($self->apply_orflist) {
	    main->update_all;
	}
    });
    $SHOWN = 1;
    return $self;
}

sub orflist_config {
    my( $self, $nb ) = @_;
    my $mainbox = $self->create_page( 'ORF list', $nb );

    # create header label
    my $header = new Gtk::Label("SignalP configuration dialog:");
    $header->parse_uline( "_O_r_f_L_i_s_t_ _C_o_n_f_i_g_u_r_a_t_i_o_n_");
    $mainbox->pack_start($header, 0, 1, 5);
 
    my $frame = new Gtk::Frame('Information in List');
    my $hbox = new Gtk::HBox(1,1);
    my $vbox1 = new Gtk::VBox(1,1);
    my $vbox2 = new Gtk::VBox(1,1);
    my $configstr = GENDB::Tools::UserConfig->get_parameter("orf_list");
    my @config = split(/,/, $configstr);
    
    $hbox->pack_start_defaults($vbox1);
    $hbox->pack_start_defaults($vbox2);
    $frame->add($hbox);
    $mainbox->pack_start($frame, 1, 1, 5);
 
    my @cols =  ( 'Length', 
		  'Status',
		  'Start', 
		  'Stop',
		  'Gene', 
		  'Frame', 
		  'Start codon',
		  'Stop codon',
		  'GC%', 
		  'AC%', 
		  '#AA', 
		  'Mol weight', 
		  'IEP' );
    my $v = 0;
    foreach(@cols) {
	$self->{$_.'_item'} = new Gtk::CheckButton($_);
	$self->{$_.'_item'}->set_active($config[$v]);
	if($v < 6) {
	    $vbox1->pack_start_defaults($self->{$_.'_item'});
	} else {
	    $vbox2->pack_start_defaults($self->{$_.'_item'});
	}
	$v++;
    }
    $self->{'cols'} = \@cols;
}

sub apply_orflist {
    my( $self ) = @_;
    my $configstr = GENDB::Tools::UserConfig->get_parameter("orf_list");
    my $confstr = '';
    foreach(@{$self->{'cols'}}) {
	$confstr .= $self->{$_.'_item'}->active.',';
    }
    return 0 if($configstr eq $confstr);
    GENDB::Tools::UserConfig->set_parameter("orf_list", $confstr);
    return 1;
}

# SignalP Configuration Tabfolder 
sub signalp_config {
    my( $self, $nb ) = @_;
    my $box = $self->create_page( 'SignalP', $nb );
    # main box for header, configuration and buttons
    my $mainbox = new Gtk::VBox(0,0);
    
    # create header label
    my $header = new Gtk::Label("SignalP configuration dialog:");
    $header->parse_uline( "_S_i_g_n_a_l_P_ _c_o_n_f_i_g_u_r_a_t_i_o_n_");
    $mainbox->pack_start($header, 0, 1, 5);

    # frame for choice of organism
    my $org_frame = new Gtk::Frame("Type of organism:");
    $org_frame->set_label_align(0.01, 0);
    # create box for choice of organism
    my $org_box = new Gtk::HBox(0,0);
    # create radio buttons 
    my $gramp_button = new Gtk::RadioButton("gram positive");
    $org_box->pack_start( $gramp_button, 1, 1, 0 );    
    my $gramm_button = new Gtk::RadioButton("gram negative", $gramp_button);
    $org_box->pack_start( $gramm_button, 1, 1, 0 );
    my $euk_button = new Gtk::RadioButton("eukaryotes", $gramp_button);
    $org_box->pack_start( $euk_button, 1, 1, 0 );

    $org_frame->add($org_box);
    $mainbox->pack_start($org_frame, 1, 1, 0);

    if (GENDB::Tools::UserConfig->get_parameter("signalp type") eq "gram+") {
	$gramp_button->set_active(1);
    }
    elsif (GENDB::Tools::UserConfig->get_parameter("signalp type") eq "gram-") {
	$gramm_button->set_active(1);
    }
    else {
	$euk_button->set_active(1);
    };
    
    # create frame for choice of output format
    my $out_frame = new Gtk::Frame("Output format:");
    $out_frame->set_label_align(0.01, 0);
    # create box for choice of output format
    my $format_box = new Gtk::HBox(0,0);
    # create radio buttons
    my $short_button = new Gtk::RadioButton("short");
    $format_box->pack_start( $short_button, 1, 1, 0);
    my $summary_button = new Gtk::RadioButton("summary", $short_button);
    $format_box->pack_start( $summary_button, 1, 1, 0);
    my $full_button = new Gtk::RadioButton("full", $short_button);
    $format_box->pack_start( $full_button, 1, 1, 0);

    $out_frame->add($format_box);
    $mainbox->pack_start($out_frame, 1, 1, 0);
    
    if (GENDB::Tools::UserConfig->get_parameter("signalp format") eq "short") {
	$short_button->set_active(1);
    }
    elsif (GENDB::Tools::UserConfig->get_parameter("signalp format") eq "summary") {
	$summary_button->set_active(1);
    }
    else {
	$full_button->set_active(1);
    };
    
    # create box for selection of graphics mode and sequence length
    my $opt_box = new Gtk::HBox(0,0);
    # create a CheckButton for graphics mode
    my $gm_button = new Gtk::CheckButton("Display ps output");
    $opt_box->pack_start( $gm_button, 1, 1, 0);
    my $trunc_box = new Gtk::HBox(0,0);
    my $trunc_label = new Gtk::Label("Truncate sequence to:");
    $trunc_box->pack_start($trunc_label, 1, 1, 0);
    # create Adjustment with SpinButton for sequence length
    my $adj = new Gtk::Adjustment(80,
				  10,
				  100,
				  1,
				  5,
				  undef);
    my $spin = new Gtk::SpinButton($adj, 0.5, 0);
    $spin->set_update_policy('if_valid');
    $trunc_box->pack_start($spin, 1, 1, 0);
    $opt_box->pack_start($trunc_box, 1, 1, 0);

    $mainbox->pack_start( $opt_box, 1, 1, 0);

    # set CheckButton to configured value
    if (GENDB::Tools::UserConfig->get_parameter("signalp graphics mode") eq "-G") {
	$gm_button->set_active(1);
    }
    else {
	$gm_button->set_active(0);
    };
    
    # set SpinButton to configured value
    $spin->set_value(GENDB::Tools::UserConfig->get_parameter("signalp trunc"));
    $box->add( $mainbox );
    $self->{gramp_button} = $gramp_button;
    $self->{gramm_button} = $gramm_button;
    $self->{short_button} = $short_button;
    $self->{full_button}  = $full_button;
    $self->{gm_button}    = $gm_button;
    $self->{spin}         = $spin;
}

# save changes
sub apply_signalp {
    my( $self ) = @_;

    # set signalp type
    if ($self->{gramp_button}->active) {
      GENDB::Tools::UserConfig->set_parameter("signalp type", "gram+");
    }
    elsif ($self->{gramm_button}->active) {
      GENDB::Tools::UserConfig->set_parameter("signalp type", "gram-");
    }
    else {
      GENDB::Tools::UserConfig->set_parameter("signalp type", "euk");
    };

    # set signalp output format
    if ($self->{short_button}->active) {
      GENDB::Tools::UserConfig->set_parameter("signalp format", "short");
    }
    elsif ($self->{full_button}->active) {
      GENDB::Tools::UserConfig->set_parameter("signalp format", "full");
    }
    else {
      GENDB::Tools::UserConfig->set_parameter("signalp format", "summary");
    };

    # set signalp graphics mode
    if ($self->{gm_button}->active) {
      GENDB::Tools::UserConfig->set_parameter("signalp graphics mode", "-G");
    }
    else {
      GENDB::Tools::UserConfig->set_parameter("signalp graphics mode", "-g");
    };
    
    # set sequence length to truncate
  GENDB::Tools::UserConfig->set_parameter("signalp trunc", $self->{spin}->get_value_as_int());
}

# FactView Configration Tabfolder
sub factview_config {
    my( $self, $nb ) = @_;
    my $box = $self->create_page( 'Fact view', $nb );

    my $list = new_with_titles Gtk::CList(( 'ID', 'Name', 'Description' ));
    $list->set_selection_mode( 'multiple' );
    $list->set_column_visibility( 0, 0 );
    $list->set_column_width( 1, 160 );
    $list->set_column_width( 2, 160 );
    $list->column_titles_passive;
    
    my $lscr = new Gtk::ScrolledWindow;
    $lscr->set_policy( 'automatic', 'automatic' );
    $lscr->add( $list );
    my $hbox = new Gtk::HBox( 1, 1 );
    $hbox->pack_start_defaults( new Gtk::Label( 'max Level to Show' ) );
    my $level_combo = new Gtk::Combo;
    $level_combo->set_popdown_strings( 'Level0', 'Level1', 'Level2', 'Level3', 'Level4', 'Level5' );
    $hbox->pack_start_defaults( $level_combo );

    my $tools = GENDB::tool->fetchall;
    my @toollist = split( / /, GENDB::Tools::UserConfig->get_parameter( "toollist" ) );
    $level_combo->entry->set_text( GENDB::Tools::UserConfig->get_parameter( "factlevel" ) );

    foreach my $tool ( @$tools ) {
	$list->append( $tool->id, $tool->name, $tool->description );
    }
    my $i = 0;
    while( $i < $list->rows ) {
	foreach( @toollist ) {
	    if( $list->get_text( $i, 0 ) == $_ ) {
		$list->select_row( $i, 0 );
	    }
	}
	$i++;
    }
    my $l = new Gtk::Label;
    $l->parse_uline( "_S_h_o_w_ _T_o_o_l_r_e_s_u_l_t_s_ _i_n_ _F_a_c_t_ _v_i_e_w_" );
    $box->pack_start( $l, 0, 0, 5 );
    $box->pack_start_defaults( $lscr );
    $box->pack_end( $hbox, 0, 0, 5 );
    $self->{list} = $list;
    $self->{level_combo} = $level_combo;
}

# save changes
sub apply_factview {
    my( $self ) = @_;

    my @rows = $self->{list}->selection;
    my $level = $self->{level_combo}->entry->get_text;
    my $tools;
    foreach( @rows ) {
	$tools .= $self->{list}->get_text( $_, 0 )." ";
    }
  GENDB::Tools::UserConfig->set_parameter( "toollist", $tools );
  GENDB::Tools::UserConfig->set_parameter( "factlevel", $level );
}

# Browser Configuration Tabfolder
sub browser_config {
    my( $self, $nb ) = @_;
    my $box = $self->create_page( 'Browser', $nb );

    my %description = ( 'Netscape' => [$GENDB::GENDB_CONFIG::GENDB_NETSCAPE,"Netscape® Communicator 4.76\nCopyright © 1994-2000 Netscape Communications Corporation,\n All rights reserved. "],
			'KDE-Konqueror' => [$GENDB::GENDB_CONFIG::GENDB_KONQUEROR,"Konqueror 2.1 (Using KDE2.1)\nWeb browser, file manager, ...\n ® 1999-2000, The Konqueror developers."],
			'Opera' => [$GENDB::GENDB_CONFIG::GENDB_OPERA,"Opera 5.0 for Solaris - 20010618 Build 003 -[5b1]\nCopyright © 1995-2001, Opera Software. All rights reserved."],
			'Internal-Browser' => [$GENDB::GENDB_CONFIG::GENDB_GTKHTML, "GenDB internal Browser."] );

    my $hbox = new Gtk::HBox( 0, 0 );
    $hbox->set_border_width( 5 );
    my $browserlist = new Gtk::Combo;
    $browserlist->entry->set_editable( 0 );
    my @browser;
    foreach(keys %description) {
	push(@browser, $_) if(defined($description{$_}->[0]));
    }
    $browserlist->set_popdown_strings( @browser );
    
    $hbox->pack_start_defaults( new Gtk::Label( "Default Browser: " ) );
    $hbox->pack_start_defaults( $browserlist );
    my $l = new Gtk::Label( "Select Browser" );
    my $desc = new Gtk::Label;
    $l->parse_uline( "_S_e_l_e_c_t_ _B_r_o_w_s_e_r_" );
    $box->pack_start( $l, 0, 0, 5 );
    $box->pack_start( $hbox, 0, 0, 5 );
    $box->pack_start_defaults( $desc );

    $browserlist->entry->signal_connect( 'changed', sub {
	$desc->set_text( $description{shift->get_text}->[1] );
    });
    $browserlist->entry->set_text( GENDB::Tools::UserConfig->get_parameter("browser") );
    $self->{browserlist} = $browserlist;
}

# save changes
sub apply_browser {
    my( $self ) = @_;  
  GENDB::Tools::UserConfig->set_parameter( "browser", $self->{browserlist}->entry->get_text );
}

# create a new Tabfolder
sub create_page {
    my( $self, $name, $nb ) = @_;
    my $vbox = new Gtk::VBox( 0, 0 );

    $nb->append_page( $vbox, new Gtk::Label($name) );

    return $vbox;
}
1;
