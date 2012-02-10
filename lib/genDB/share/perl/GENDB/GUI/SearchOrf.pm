package SearchOrf;

($GENDB::GUI::SearchOrf::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use Gtk;
use GENDB::GUI::GenDBWidget;
use GENDB::GUI::FactView;
use GENDB::orf;
use GENDB::contig;
use GENDB::funcat;
use GENDB::feature_type;

use vars( qw(@ISA) );
@ISA = qw( GenDBWidget );

my %ORF_STATES = ('putative' => 0,
		  'annotated' => 1,
		  'ignore - artificial ORF' => 2,
		  'finished' => 3, 
		  'attention needed' => 4,
		  'user state 1' => 5,
		  'user state 2' => 6);
my @orf_states = ('putative',
		  'annotated',
		  'ignore - artificial ORF',
		  'finished', 
		  'attention needed',
		  'user state 1',
		  'user state 2');
my %sort_val = ( 'Name' => 'name',
		 'State' => 'status',
		 'Frame' => 'frame',
		 'Length' => '(stop - start)',
		 'Start' => 'start',
		 'Stop' =>'stop',
		 'Molweight' => 'molweight',
		 'IEP' => 'isoelp',
		 'GC' => 'gc' );

########################################
###				     ###
### Interface to search the database ###
###				     ###
########################################

sub new {
    my( $class ) = @_;
    my $self = $class->SUPER::new;
    bless $self, $class;

    my $scroller = new Gtk::ScrolledWindow;
    my $list =  new_with_titles Gtk::CList( 
		( 'ID', 'Name', 'Contig', 'EC', 'State', 'Length', 'Start', 'Gene', 
		  'Frame', 'Start', 'GC%', 'AC%', '#AA', 'Mol Wt', 'IEP' ) );
    my $frame = new Gtk::Frame( 'Search Options' );
    $frame->add( &optionwidget( $self ) );
    for( my $i = 0; $i < 15; $i++ ) {
	$list->set_column_width( $i, 80 );
    }
    $self->{'list'} = $list;
    $list->set_auto_sort( 1 );
    $list->set_column_visibility( 0, 0 );
    $list->set_column_width(1, 120 ); 
    $list->signal_connect( 'click_column', \&sortlist );
    $list->signal_connect( 'select_row', \&row_selected, $self );
    $list->signal_connect( 'button_press_event', \&button_press, $self );
    
    $scroller->add( $list );
    $self->pack_start( $frame, 0, 0, 5 );
    $self->pack_start( $scroller, 1, 1, 5 );
    $self->{'running'} = 0;
    &make_contig_index( $self );

    &clear_entry( undef, $self );
    
    return $self;
}

sub update {
    my($self) = @_;
    my @contigs = ( '*', sort keys %{GENDB::contig->fetchallby_name} );

    $self->{'contig_combo'}->set_popdown_strings(@contigs);
}

sub make_contig_index {
    my( $self ) = @_;
    my $contigs = GENDB::contig->fetchall;
    my @index;
    foreach( @$contigs ) {
	$index[$_->id] = $_->name;
    }
    $self->{'contig_index'} = \@index;
}

sub button_press {
    my( $list, $self, $event ) = @_;
    if( $event->{'button'} == 3 ) {
	my @info = $list->get_selection_info( $event->{'x'}, $event->{'y'} );
	$list->select_row( $info[0], $info[1] );
	&row_selected( $list, $self, $info[0], $info[1], $event );
	return 0;
    }
}

sub row_selected {
    my( $list, $self, $row, $col, $event ) = @_;
    return if( $self->{'running'} );
    if( $event->{'type'} eq '2button_press' ) {
	my $orf_id = $list->get_text( $row, 0 );
	main->show_orf( $orf_id );
    } elsif( $event->{'button'} == 3 && $col == 1 ) {
	my $orf_id = $list->get_text( $row, 0 );
	my $orf = GENDB::orf->init_id( $orf_id );
	my @names = @{$orf->alias_names};
	my $menu = new Gtk::Menu;
	my $newname = new Gtk::MenuItem('Create new Name');
	$newname->signal_connect('activate', \&create_alias_name, $self, $orf_id);
	$menu->append($newname);
	if( $#names >= 0 ) {
	    $menu->append(new Gtk::MenuItem);
	    foreach( @names ) {
		my $item = new Gtk::MenuItem( $_ );
		$item->signal_connect( 'activate', \&swap_names, $self, $orf_id, $_ );
		$menu->append( $item );
	    }
	}
	$menu->show_all;
	$menu->popup( undef,undef,1,$event->{'time'},undef );
    }
}

sub create_alias_name {
    my($item, $self, $orf_id) = @_;
    my $orf = GENDB::orf->init_id( $orf_id );
    my $dia = new Gtk::Dialog;
    $dia->set_title('new alias name');
    $dia->vbox->pack_start(new Gtk::Label('Create new Name'), 0, 0, 4);
    $dia->vbox->pack_start(new Gtk::Label("Orf: ".$orf->name), 0, 0, 4);
    my $entry = new Gtk::Entry;
    $dia->vbox->pack_start($entry, 0, 0, 4);

    my $ok = new Gtk::Button('OK');
    $ok->signal_connect('clicked', sub {
      GENDB::orf_names->create($orf_id, $entry->get_text) if($entry->get_text ne '');
	$dia->destroy;
    });

    my $cancel = new Gtk::Button('Cancel');
    $cancel->signal_connect('clicked', sub {
	$dia->destroy;
    });
    my $hh = new Gtk::HButtonBox;
    $hh->pack_start_defaults($ok);
    $hh->pack_start_defaults($cancel);
    $dia->action_area->add($hh);
    $dia->set_position('center');
    $dia->set_modal(1);
    $dia->show_all;
}

sub swap_names {
    my( $item, $self, $orf_id, $name ) = @_;
    my $orf = GENDB::orf->init_id( $orf_id );
    my $orf_name = GENDB::orf_names->init_name( $name );
    $orf_name->name( $orf->name );
    $orf->name( $name );
}

sub optionwidget {
    my( $self ) = @_;
    my $vbox = new Gtk::VBox( 0, 5 );
    my $hbox = new Gtk::HBox( 0, 5 );
    my $w = new Gtk::VBox( 1, 5 );
    my $h = new Gtk::HBox( 1, 5 );

    # Orf Name
    $h->pack_start_defaults( new Gtk::Label( "Name (Regexp):" ) );
    $self->{'orf_name_entry'} = new Gtk::Entry;
    $self->{'orf_name_entry'}->signal_connect('activate', \&start_search, $self);
    $self->{'orf_name_entry'}->set_text( '*' );
    $h->pack_start_defaults( $self->{'orf_name_entry'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    # EC Number
    $h->pack_start_defaults( new Gtk::Label( "EC Number:" ) );
    $self->{'EC_entry'} = new Gtk::Entry;
    $self->{'EC_entry'}->signal_connect('activate', \&start_search, $self);
    $h->pack_start_defaults( $self->{'EC_entry'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    # Fact
    $h->pack_start_defaults( new Gtk::Label( "Fact (Regexp):" ) );
    $self->{'fact_entry'} = new Gtk::Entry;
    $self->{'fact_entry'}->signal_connect('activate', \&start_search, $self);
    $h->pack_start_defaults( $self->{'fact_entry'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    # Contig Name
    $h->pack_start_defaults( new Gtk::Label( "Contig Name:" ) );
    $self->{'contig_combo'} = new Gtk::Combo;
    $self->{'contig_combo'}->entry->signal_connect('activate', \&start_search, $self);
    my @contigs = ( '*', sort keys %{GENDB::contig->fetchallby_name} );
    $self->{'contig_combo'}->set_popdown_strings( @contigs );
    $self->{'contig_combo'}->entry->set_editable( 0 );
    $h->pack_start_defaults( $self->{'contig_combo'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    # Orf State
    $h->pack_start_defaults( new Gtk::Label( "Orf State:" ) );
    $self->{'state_combo'} = new Gtk::Combo;
    $self->{'state_combo'}->entry->signal_connect('activate', \&start_search, $self);
    my @states =  ( '*',
		    'putative',
		    'annotated',
		    'ignore - artificial ORF',
		    'finished', 
		    'attention needed',
		    'user state 1',
		    'user state 2');
    $self->{'state_combo'}->set_popdown_strings( @states );
    $self->{'state_combo'}->entry->set_editable( 0 );
    $h->pack_start_defaults( $self->{'state_combo'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    # Orf Frame
    $h->pack_start_defaults( new Gtk::Label( "Orf Frame:" ) );
    $self->{'frame_combo'} = new Gtk::Combo;
    $self->{'frame_combo'}->entry->signal_connect('activate', \&start_search, $self);
    my @frames =  ( qw( * -3 -2 -1 1 2 3 ) );
    $self->{'frame_combo'}->set_popdown_strings( @frames );
    $self->{'frame_combo'}->entry->set_editable( 0 );
    $h->pack_start_defaults( $self->{'frame_combo'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    # Category
    $h->pack_start_defaults( new Gtk::Label( 'Category' ) );
    my $topfuncats = GENDB::funcat->get_toplevel_funcats;
    my $fmenu = new Gtk::Menu;
    my $item = new Gtk::MenuItem( '*' );
    $item->signal_connect( 'activate', sub {
	$self->{'funcat_search'} = '*';
    } );
    $fmenu->append( $item );
    $fmenu->append( new Gtk::MenuItem );
    foreach( @$topfuncats ) {
	my $name = $_->name;
	my $fid = $_->id;
	my $item = new Gtk::MenuItem( $name );
	if( &next_level_funcats( $item, $_, $self ) ) { 
	    my $func = $_;
	    $item->signal_connect( 'activate', sub {
		$self->{'funcat_search'} = $func;
	    } );
	}
	$fmenu->append( $item );
    }
    my $funcats = new Gtk::OptionMenu;
    $funcats->set_menu( $fmenu );
    $self->{'funcat_menu' } = $funcats;
    $h->pack_start_defaults($funcats);
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );


    # EMBL Features
    $h->pack_start_defaults( new Gtk::Label( 'EMBL Features' ) );
    my $topfuncats = GENDB::feature_type->get_toplevel_feature_types;
    $fmenu = new Gtk::Menu;
    my $item = new Gtk::MenuItem( '*' );
    $item->signal_connect( 'activate', sub {
	$self->{'feature_search'} = '*';
    } );
    $fmenu->append( $item );
    $fmenu->append( new Gtk::MenuItem );
    foreach( @$topfuncats ) {
	my $name = $_->name;
	my $fid = $_->id;
	my $item = new Gtk::MenuItem( $name );
	if( &next_level_features( $item, $_, $self ) ) { 
	    my $func = $_;
	    $item->signal_connect( 'activate', sub {
		$self->{'feature_search'} = $func;
	    } );
	}
	$fmenu->append( $item );
    }
    my $features = new Gtk::OptionMenu;
    $features->set_menu( $fmenu );
    $self->{'feature_menu'} = $features;
    $h->pack_start_defaults($features);
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    # Limit
    $h->pack_start_defaults( new Gtk::Label( "Limit Search:" ) );
    $self->{'limit_entry'} = new Gtk::Entry;
    $self->{'limit_entry'}->signal_connect('activate', \&start_search, $self);
    $h->pack_start_defaults( $self->{'limit_entry'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    ### next col ###
    $hbox->pack_start_defaults( $w );
    $hbox->pack_start( new Gtk::VSeparator, 0, 0, 0 );
    $w = new Gtk::VBox( 1, 5 );

    # Orf Length
    $h->pack_start_defaults( new Gtk::Label( "Orf Length:" ) );
    $self->{'length_gle'} = &make_gle;
    $h->pack_start_defaults( $self->{'length_gle'} );
    $self->{'length_entry'} = new Gtk::Entry;
    $self->{'length_entry'}->signal_connect('activate', \&start_search, $self);
    $h->pack_start_defaults( $self->{'length_entry'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    # Orf Start
    $h->pack_start_defaults( new Gtk::Label( "Start Position:" ) );
    $self->{'start_gle'} = &make_gle;
    $h->pack_start_defaults( $self->{'start_gle'} );
    $self->{'start_entry'} = new Gtk::Entry;
    $self->{'start_entry'}->signal_connect('activate', \&start_search, $self);
    $h->pack_start_defaults( $self->{'start_entry'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    # Orf End
    $h->pack_start_defaults( new Gtk::Label( "Stop Position:" ) );
    $self->{'end_gle'} = &make_gle;
    $h->pack_start_defaults( $self->{'end_gle'} );
    $self->{'end_entry'} = new Gtk::Entry;
    $self->{'end_entry'}->signal_connect('activate', \&start_search, $self);
    $h->pack_start_defaults( $self->{'end_entry'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    # Orf Molweight
    $h->pack_start_defaults( new Gtk::Label( "Orf Molweight:" ) );
    $self->{'molweight_gle'} = &make_gle;
    $h->pack_start_defaults( $self->{'molweight_gle'} );
    $self->{'molweight_entry'} = new Gtk::Entry;
    $self->{'molweight_entry'}->signal_connect('activate', \&start_search, $self);
    $h->pack_start_defaults( $self->{'molweight_entry'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    # Orf IEP
    $h->pack_start_defaults( new Gtk::Label( "Orf IEP:" ) );
    $self->{'IEP_gle'} = &make_gle;
    $h->pack_start_defaults( $self->{'IEP_gle'} );
    $self->{'IEP_entry'} = new Gtk::Entry;
    $self->{'IEP_entry'}->signal_connect('activate', \&start_search, $self);
    $h->pack_start_defaults( $self->{'IEP_entry'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );
    
    # Orf GC
    $h->pack_start_defaults( new Gtk::Label( "Orf %GC:" ) );
    $self->{'GC_gle'} = &make_gle;
    $h->pack_start_defaults( $self->{'GC_gle'} );
    $self->{'GC_entry'} = new Gtk::Entry;
    $self->{'GC_entry'}->signal_connect('activate', \&start_search, $self);
    $h->pack_start_defaults( $self->{'GC_entry'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    # Sort Search
    $h->pack_start_defaults( new Gtk::Label( "Sorted by:" ) );
    $self->{'sort_by'} = new Gtk::Combo;
    $self->{'sort_by'}->entry->set_editable(0);
    $self->{'sort_by'}->set_popdown_strings(
		  ( '*', 'Name', 'State', 'Frame', 'Length',
		    'Start', 'Stop', 'Molweight', 'IEP', 'GC' ) );
    $h->pack_start_defaults( $self->{'sort_by'} );
    $self->{'asc_desc'} = new Gtk::Combo;
    $self->{'asc_desc'}->entry->set_editable(0);
    $self->{'asc_desc'}->set_popdown_strings( qw( * Ascending Descending ) );
    $h->pack_start_defaults( $self->{'asc_desc'} );
    $w->pack_start_defaults( $h );
    $h = new Gtk::HBox( 1, 5 );

    $hbox->pack_start_defaults( $w );
    $vbox->pack_start_defaults( $hbox );

    #buttons
    $h = new Gtk::HBox( 1, 5 );
    my $ok = new Gtk::Button( 'Start Search' );
    my $clear = new Gtk::Button( 'Clear Entries' );
    $h->pack_start( $clear, 0, 1, 25 );
    $h->pack_start( $ok, 0, 1, 25 );
    $ok->signal_connect( 'clicked', \&start_search, $self );
    $clear->signal_connect( 'clicked', \&clear_entry, $self );
    $vbox->pack_start( $h, 0, 0, 5 );

    return $vbox;
}

sub start_search {
    my( undef, $self ) = @_;
    my $fetch = "";
    return if( $self->{'running'} );
    $self->{'running'} = 1;
    main->update_statusbar( "start search..." );
    Gtk->main_iteration while( Gtk->events_pending );

    # search alias names
    my $tmp = $self->{'orf_name_entry'}->get_text;
    my $orf_ids = undef;
    my %done;

    if( $tmp ne "" && $tmp ne '*' ) {
	$fetch .= " AND " if( $fetch ne "" );
	my $aliases = GENDB::orf_names->fetchbySQL( "name REGEXP \'^$tmp\$\' " );
	$fetch .= "( " if( $aliases != -1 );
	foreach( @$aliases ) {
	    my $id = $_->orf_id;
	    if( !$done{$id} ) {
		$fetch .= " id = $id OR ";
		$done{$id} = 1;
	    }
	}
	$fetch .= " 0 ) " if( $aliases != -1 );
    }

    # search gene names
    $tmp = $self->{'orf_name_entry'}->get_text;
    $orf_ids = undef;

    if( $tmp ne "" && $tmp ne '*' ) {
	$fetch .= " OR " if( $fetch ne "" );
	my $annotations = GENDB::annotation->fetchbySQL( "name REGEXP \'^$tmp\$\'" );
	$fetch .= "( " if( $annotations != -1 );
	foreach( @$annotations ) {
	    my $id = $_->orf_id;
	    my $o = GENDB::orf->init_id( $id );
	    next if( $o == -1 );
	    my $la = $o->latest_annotation;
	    if( $la->id == $_->id ) {
		if( !$done{$id} ) {
		    $fetch .= " id = $id OR ";
		    $done{$id} = 1;
		}
	    }
	}
	$fetch .= " 0 ) " if( $annotations != -1 );
    }
    
    # search for name
    $tmp = $self->{'orf_name_entry'}->get_text;
    $tmp = '.*' if( $tmp eq '*' );
    $fetch .= " OR " if( $fetch ne "" );
    $fetch .= "name REGEXP \'^$tmp\$\' " if( $tmp ne "" );

    # search fact description
    $tmp = $self->{'fact_entry'}->get_text;
    $orf_ids = undef;

    if( $tmp ne "" && $tmp ne '*' ) {
      FactView::set_search_string($tmp);
	$fetch .= " AND " if( $fetch ne "" );
	my $facts = GENDB::fact->fetchbySQL( "description REGEXP \'^$tmp\$\'" );
	$fetch .= "( " if( $facts != -1 );
	foreach( @$facts ) {
	    my $id = $_->orf_id;
	    if( !$done{$id} ) {
		$fetch .= " id = $id OR ";
		$done{$id} = 1;
	    }
	}
	$fetch .= " 0 ) " if( $facts != -1 );
    }

    # search funcats 
    $tmp = $self->{'funcat_search'};
    $orf_ids = undef;

    if( $tmp ne "" && $tmp ne '*' ) {
	$fetch .= " AND " if( $fetch ne "" );
	my $funcats = $tmp->get_all_children;
	my $anno_fetch = "(";
	foreach( @$funcats ) {
	    $anno_fetch .= 'category = '.$_->id." OR ";
	}
	if( $tmp->name =~ /.*UNCLASSIFIED.*/ ){
	    $anno_fetch .= 'category IS NULL OR ';
	}
	$anno_fetch .= "0)";
	my $annotations = GENDB::annotation->fetchbySQL( $anno_fetch );
	$fetch .= "( " if( $annotations != -1 );

	### many annotations ==> gets very slow ###
	foreach( @$annotations ) {
	    my $id = $_->orf_id;
	    my $a = GENDB::orf->init_id( $id );
	    if( defined( $a ) && $a != -1 ) {
		my $la = $a->latest_annotation;
		if( $la->id == $_->id ) {
		    if( !$done{$id} ) {
			$fetch .= " id = $id OR ";
			$done{$id} = 1;
		    }
		}
	    }
	}
	$fetch .= " 0 ) " if( $annotations != -1 );
    }

    # search features
    $tmp = $self->{'feature_search'};
    $orf_ids = undef;

    if( $tmp ne "" && $tmp ne '*' ) {
	$fetch .= " AND " if( $fetch ne "" );
	my $features = $tmp->get_all_children;
	my $anno_fetch = "(";
	foreach( @$features ) {
	    $anno_fetch .= 'feature_type = '.$_->id." OR ";
	}
	$anno_fetch .= "0)";
	my $annotations = GENDB::annotation->fetchbySQL( $anno_fetch );
	$fetch .= "( " if( $annotations != -1 );

	### many annotations ==> gets very slow ###
	foreach( @$annotations ) {
	    my $id = $_->orf_id;
	    my $la = GENDB::orf->init_id( $id )->latest_annotation;
	    if( $la->id == $_->id ) {
		if( !$done{$id} ) {
		    $fetch .= " id = $id OR ";
		    $done{$id} = 1;
		}
	    }
	}
	$fetch .= " 0 ) " if( $annotations != -1 );
    }

    # annotations with EC
    my $tmp = $self->{'EC_entry'}->get_text;
    my $orf_ids = undef;

    if( $tmp ne "" && $tmp ne '*' ) {
	$fetch .= " AND " if( $fetch ne "" );
	my $annotations = GENDB::annotation->fetchbySQL( "ec REGEXP \'^$tmp\$\' " );
	$fetch .= "( " if( $annotations != -1 );
	foreach( @$annotations ) {
	    $fetch .= " id = ".$_->orf_id." OR ";
	}
	$fetch .= " 0 ) " if( $annotations != -1 );
    }

    # search contig
    $tmp = $self->{'contig_combo'}->entry->get_text;
    if( $tmp ne "" && $tmp ne '*' ) {
	$fetch .= " AND " if( $fetch ne "" );
	my $id = GENDB::contig->init_name( $tmp )->id;
	$fetch .= " contig_id = $id ";
    }

    # search state
    $tmp = $self->{'state_combo'}->entry->get_text;
    if( $tmp ne "" && $tmp ne '*' ) {
	$fetch .= " AND " if( $fetch ne "" );
	my $id = $ORF_STATES{$tmp};
	$fetch .= " status = $id ";
    }

    #search frame
    $tmp = $self->{'frame_combo'}->entry->get_text;
    if( $tmp ne "" && $tmp ne '*' ) {
	$fetch .= " AND " if( $fetch ne "" );
	$fetch .= " frame = $tmp ";
    }

    #search length
    $tmp = $self->{'length_entry'}->get_text;
    if( $tmp ne "" && $tmp ne '*' ) {
	$tmp--;
	my $range = $self->{'length_gle'}->entry->get_text;
	$fetch .= " AND " if( $fetch ne "" );
	$fetch .= " stop - start  $range $tmp ";
    }

    #search start
    $tmp = $self->{'start_entry'}->get_text;
    if( $tmp ne "" && $tmp ne '*' ) {
	my $range = $self->{'start_gle'}->entry->get_text;
	$fetch .= " AND " if( $fetch ne "" );
	$fetch .= " start $range $tmp ";
    }

    #search end
    $tmp = $self->{'end_entry'}->get_text;
    if( $tmp ne "" && $tmp ne '*' ) {
	my $range = $self->{'end_gle'}->entry->get_text;
	$fetch .= " AND " if( $fetch ne "" );
	$fetch .= " stop $range $tmp ";
    }

    #search molweight
    $tmp = $self->{'molweight_entry'}->get_text;
    if( $tmp ne "" && $tmp ne '*' ) {
	my $range = $self->{'molweight_gle'}->entry->get_text;
	$fetch .= " AND " if( $fetch ne "" );
	if( $range eq "=" ) {
	    $fetch .= " ABS( molweight - $tmp ) < 0.01 ";
	} else {
	    $fetch .= " molweight $range $tmp ";
	}
    }

    #search IEP
    $tmp = $self->{'IEP_entry'}->get_text;
    if( $tmp ne "" && $tmp ne '*' ) {
	my $range = $self->{'IEP_gle'}->entry->get_text;
	$fetch .= " AND " if( $fetch ne "" );
	if( $range eq "=" ) {
	    $fetch .= " ABS( isoelp - $tmp ) < 0.001 ";
	} else {
	    $fetch .= " isoelp $range $tmp ";
	}
    }

    #search GC
    $tmp = $self->{'GC_entry'}->get_text;
    if( $tmp ne "" && $tmp ne '*' ) {
	my $range = $self->{'GC_gle'}->entry->get_text;
	$fetch .= " AND " if( $fetch ne "" );
	$fetch .= " gc $range $tmp ";
    }

    # sort
    $tmp = $self->{'sort_by'}->entry->get_text;
    if( $tmp ne "" && $tmp ne '*' ) {
	my $adtmp = $self->{'asc_desc'}->entry->get_text;
	my $sortby = $sort_val{$tmp};
	my $ad = 'DESC';
	$ad = 'ASC' if( $adtmp eq "Ascending" );
	$ad = '' if( $adtmp eq '*' );
	$fetch .= " ORDER BY $sortby $ad ";
    }

    # limit
    $tmp = $self->{'limit_entry'}->get_text;
    $limit = int($tmp);
    if( $limit ) {
	$fetch .= " LIMIT $limit ";
    }

    # start the query
    # and fill the list
    if( $fetch ne "" ) {
	my $orfs = GENDB::orf->fetchbySQL( $fetch );

	$self->{'list'}->freeze;
	$self->{'list'}->clear;
	my $number = $#{$orfs}+1;
	main->update_statusbar( "$number Orfs found!" );

	$self->init_progress($number);
	my $count = 0;

	foreach( sort( @{ $orfs } ) ) {
	    my $orf = $_;
	    
	    my $name;
	    if ($orf->status == $ORF_STATE_IGNORED) {
		$name='--';
	    } else {
		my $annotation = $orf->latest_annotation;
		if ($annotation && $annotation != -1) {
		    $name=$annotation->name;
		    $ec = $annotation->ec;
		} else {
		    $name=$orf->name;
		}
	    }

	    my $iep = sprintf( "%.3g", $orf->isoelp );

	    $self->{'list'}->append( ( $orf->id,
			     $orf->name,
			     $self->{'contig_index'}->[$orf->contig_id],
			     $ec,
			     $orf_states[$orf->status],
			     $orf->length,
			     $orf->start,
			     $name,
			     $orf->frame,
			     uc($orf->startcodon),
			     $orf->gc,
			     $orf->ag,
			     $orf->aalength,
			     $orf->molweight,
			     $iep ) );
	    $self->update_progress($count++);
	    
	}
	$self->{'list'}->thaw;
	$self->end_progress;
    }
    $self->{'running'} = 0;
}

sub clear_entry {
    my( undef, $self ) = @_;
    $self->{'orf_name_entry'}->set_text( '*' );
    $self->{'fact_entry'}->set_text( '*' );
    $self->{'contig_combo'}->entry->set_text( '*' );
    $self->{'state_combo'}->entry->set_text( '*' );
    $self->{'frame_combo'}->entry->set_text( '*' );
    $self->{'length_entry'}->set_text( '*' );
    $self->{'start_entry'}->set_text( '*' );
    $self->{'end_entry'}->set_text( '*' );
    $self->{'molweight_entry'}->set_text( '*' );
    $self->{'IEP_entry'}->set_text( '*' );
    $self->{'GC_entry'}->set_text( '*' );
    $self->{'EC_entry'}->set_text( '*' );
    $self->{'limit_entry'}->set_text( '*' );

    $self->{'IEP_gle'}->entry->set_text( '<' );
    $self->{'molweight_gle'}->entry->set_text( '<' );
    $self->{'end_gle'}->entry->set_text( '<' );
    $self->{'start_gle'}->entry->set_text( '<' );
    $self->{'length_gle'}->entry->set_text( '<' );
    $self->{'sort_by'}->entry->set_text( '*' );
    $self->{'asc_desc'}->entry->set_text( '*' );

    $self->{'funcat_menu'}->set_history( 0 );
    $self->{'funcat_search'} = '*';
    $self->{'feature_menu'}->set_history( 0 );
    $self->{'feature_search'} = '*';

  FactView::set_search_string('NOTHING');
}

sub search_hash {
    my( $self, $ihash ) = @_;
    $self->{'orf_name_entry'} ->set_text(        $ihash->{'orf_name'}      || '*' );
    $self->{'fact_entry'}     ->set_text(        $ihash->{'fact'}          || '*' );
    $self->{'contig_combo'}   ->entry->set_text( $ihash->{'contig_name'}   || '*' );
    $self->{'state_combo'}    ->entry->set_text( $ihash->{'orf_state'}     || '*' );
    $self->{'frame_combo'}    ->entry->set_text( $ihash->{'orf_frame'}     || '*' );
    $self->{'length_entry'}   ->set_text(        $ihash->{'orf_length'}    || '*' );
    $self->{'start_entry'}    ->set_text(        $ihash->{'orf_start'}     || '*' );
    $self->{'end_entry'}      ->set_text(        $ihash->{'orf_stop'}      || '*' );
    $self->{'molweight_entry'}->set_text(        $ihash->{'orf_molweight'} || '*' );
    $self->{'IEP_entry'}      ->set_text(        $ihash->{'orf_iep'}       || '*' );
    $self->{'GC_entry'}       ->set_text(        $ihash->{'orf_gc'}        || '*' );
    $self->{'EC_entry'}       ->set_text(        $ihash->{'orf_ec'}        || '*' );
    $self->{'limit_entry'}    ->set_text(        $ihash->{'limit'}         || '*' );

    $self->{'IEP_gle'}->entry->set_text( $ihash->{'orf_iep_range'} || '<'  );
    $self->{'molweight_gle'}->entry->set_text( $ihash->{'orf_molweight_range'} || '<'  );
    $self->{'end_gle'}->entry->set_text( $ihash->{'orf_end_range'} || '<'  );
    $self->{'start_gle'}->entry->set_text( $ihash->{'orf_start_range'} || '<'  );
    $self->{'length_gle'}->entry->set_text( $ihash->{'orf_length_range'} || '<'  );
    $self->{'sort_by'}->entry->set_text( $ihash->{'sort_by'} || '*' );
    $self->{'asc_desc'}->entry->set_text( $ihash->{'asc_desc'} || '*' );

    $self->{'funcat_menu'}->set_history( 0 );
    $self->{'funcat_search'} = '*';
    $self->{'feature_menu'}->set_history( 0 );
    $self->{'feature_search'} = '*';

    Gtk->main_iteration while(Gtk->events_pending);
    &start_search( undef, $self );
}

sub make_gle {
    my $ret = new Gtk::Combo;
    $ret->set_popdown_strings( ( qw( < = > ) ) );
    $ret->set_usize( 1, 1 );
    $ret->entry->set_editable( 0 );
    return $ret;
}

sub sortlist {
    my( $list, $col, $self ) = @_;
    return if( $self->{'running'} );
    $list->set_sort_column( $col );
    $list->set_compare_func( \&sort_func );
    $list->sort;
    if( $list->sort_type eq 'ascending' ) { $list->set_sort_type( 'descending' ); }
    else  { $list->set_sort_type( 'ascending' ); }
}

sub sort_func {
    my( $list, $a, $b, $col ) = @_;
    return ( $a <=> $b or $a cmp $b );
}

sub next_level_funcats {
    my( $item, $parent, $self ) = @_;
    my $nmenu = new Gtk::Menu;

    my $nitem = new Gtk::MenuItem( $parent->name );
    $nitem->signal_connect( 'activate', sub {
	$self->{'funcat_search'} = $parent;
    } );
    $nmenu->append( $nitem );
    $nmenu->append( new Gtk::MenuItem );

    my $next_funcats = $parent->get_children;

    return 1 if( $#{$next_funcats} < 0 );
    foreach( @$next_funcats ) {
	my $name = $_->name;
	my $fid = $_->id;
	my $nitem = new Gtk::MenuItem( $name );
	if( &next_level_funcats( $nitem, $_, $self ) ) {
	    my $func = $_;
	    $nitem->signal_connect( 'activate', sub {
		$self->{'funcat_search'} = $func;
	    } );
	}
	$nmenu->append( $nitem );
    }
    $item->set_submenu( $nmenu );
    return 0;
}

sub next_level_features {
    my( $item, $parent, $self ) = @_;
    my $nmenu = new Gtk::Menu;

    my $nitem = new Gtk::MenuItem( $parent->name );
    $nitem->signal_connect( 'activate', sub {
	$self->{'feature_search'} = $parent;
    } );
    $nmenu->append( $nitem );
    $nmenu->append( new Gtk::MenuItem );

    my $next_features = $parent->get_children;

    return 1 if( $#{$next_features} < 0 );
    foreach( @$next_features ) {
	my $name = $_->name;
	my $fid = $_->id;
	my $nitem = new Gtk::MenuItem( $name );
	if( &next_level_features( $nitem, $_, $self ) ) {
	    my $func = $_;
	    $nitem->signal_connect( 'activate', sub {
		$self->{'feature_search'} = $func;
	    } );
	}
	$nmenu->append( $nitem );
    }
    $item->set_submenu( $nmenu );
    return 0;
}

1;
