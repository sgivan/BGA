package GENDB::GUI::ContigView;

($VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use POSIX;
use GENDB::GENDB_CONFIG;
use GENDB::Tools::gff_export;
use GENDB::Tools::fasta_exporter;
use GENDB::Tools::embl_exporter;
use GENDB::Tools::genbank_exporter;
use GENDB::contig;
use GENDB::orf;
use GENDB::funcat;
use GENDB::feature_type;
use GENDB::GUI::GenDBWidget;
use GENDB::GUI::OrfCanvas;
use GENDB::GUI::CGPlot;
use GENDB::GUI::Utils;
use GENDB::Config;
use vars qw(@ISA);

@ISA = qw(GenDBWidget);

my $dist = 30;
my $FONT = '-adobe-helvetica-medium-r-normal--12-120-*-*-p-67-*';
my $ZOOM = 10;
my $trans = 90;
my $can_change = 1;
my $selected_node = undef;

my @ORF_STATES = ('putative',
                  'annotated',
                  'ignored',
                  'finished', 
                  'attention needed',
                  'user state 1',
                  'user state 2');


###############################################
###                                         ###
### Main Widget showing contig information: ###
###                                         ###
### tree with all contigs,                  ###
### graphical contig representation,        ###
### orf - information tabel                 ###
###                                         ###
###############################################

sub new {
    my $class = shift;
    my $self = $class->SUPER::new;
    bless $self;

    my $hpaned = new Gtk::HPaned;
    my $vpaned = new Gtk::VPaned;
    $vpaned->set_position( 275 );
    $vpaned->border_width( 5 );

    $hpaned->set_position( 200 );
    $hpaned->border_width( 5 );

    my @cols =  ( 'Name', 
		  'Status',
		  'Length', 
		  'Start', 
		  'Stop',
		  'Gene', 
		  'Frame', 
		  'StartCodon',
		  'StopCodon',
		  'GC%', 
		  'AG%', 
		  '#AA', 
		  'Mol Wt', 
		  'IEP' );

    $self->{'list_config'} = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1];
    
    my $list = new_with_titles Gtk::CList( @cols );
    $list->set_column_width(0, 160 );
    $list->set_column_width(1, 120 );
    $list->set_column_width(2, 80 );
    $list->set_column_width(3, 80 );
    $list->set_column_width(4, 80 );
    $list->set_column_width(5, 80 );
    $list->set_column_width(6, 80 );
    $list->set_column_width(7, 80 );
    $list->set_column_width(8, 80 );
    $list->set_column_width(9, 80 );
    $list->set_column_width(10, 80 );
    $list->set_column_width(11, 80 );
    $list->set_column_width(12, 80 );
    $list->set_column_width(13, 80 );
    $list->set_column_width(14, 80 );
    $list->set_auto_sort( 1 );
    $list->set_column_justification( 1, 'center' );
    $list->set_column_justification( 2, 'right' );
    $list->set_column_justification( 3, 'right' );
    $list->set_column_justification( 4, 'right' );
    $list->set_column_justification( 5, 'center' );
    $list->set_column_justification( 6, 'center' );
    $list->set_column_justification( 7, 'center' );
    $list->set_column_justification( 8, 'center');
    $list->set_column_justification( 9, 'right');
    $list->set_column_justification( 10, 'right');
    $list->set_column_justification( 11, 'right');
    $list->set_column_justification( 12, 'right');
    $list->set_column_justification( 13, 'right');
    $list->set_column_justification( 14, 'right');
    

    my $configstr = GENDB::Tools::UserConfig->get_parameter("orf_list");
    if( $configstr eq '' ) {
      GENDB::Tools::UserConfig->set_parameter("orf_list", '1,1,1,1,1,1,1,1,1,1,1,1,1,1');
	$configstr = '1,1,1,1,1,1,1,1,1,1,1,1,1,1';
    }
    my @config = split(/,/, $configstr);
    my $v= 1;
    foreach(@config) {
	$list->set_column_visibility($v++, $_);
    }
  
    my $tree = new Gtk::CTree(1,0);
    $tree->set_expander_style("square");
    $tree->signal_connect( "button_press_event", \&show_contig_popup, $self );

    my $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'automatic' );
    $scroller->add( $tree );
    my $listscroller = new Gtk::ScrolledWindow;
    $listscroller->set_policy( 'automatic', 'automatic' );
    $listscroller->add( $list );


    $list->signal_connect( 'click_column', \&sortlist );
    $list->signal_connect( 'select_row', \&row_selected, $self );

    my $cbox = new OrfCanvas( $self );
    $self->add_child($cbox);
    $cbox->set_border_width(3);

    my $notebook = new Gtk::Notebook;
    $notebook->set_show_tabs(0);
    $notebook->set_show_border(0);
    $notebook->set_border_width(1);

    my $data_box = &make_data_box( $self );    
    my $cgplot = new CGPlot;

    $notebook->append_page( $listscroller );
    $notebook->append_page( $data_box );
    $notebook->append_page( $cgplot );

    $cbox->set_sync( $cgplot );

    my $cframe = new Gtk::Frame( "Contigs" );
    $cframe->add( $scroller );
    $hpaned->add1( $cframe );
    $vpaned->add1( $cbox );
    $hpaned->add2( $vpaned );
    $vpaned->add2( $notebook );

    $self->{'update'} = 1;
    $self->{ 'list_parent' } = $listscroller;
    $self->{ 'orf_canvas' } = $cbox;
    $self->{ 'tree' } = $tree;
    $self->{ 'list' } = $list;
    $self->{ 'contigs' } = GENDB::contig->fetchallby_name;
    $self->{'switch'} = $notebook;
    $self->{'current_page'} = 0;
    $self->{'cgplot'} = $cgplot;
    $self->{'cols'} = \@cols;

    &make_tree( $self );
    my $page = GENDB::Tools::UserConfig->get_parameter( "orf information" );
    $notebook->set_page( $page );
    
    my $exportmenu = $self->make_export_menu;
    $list->signal_connect('button_press_event', sub {
	my($list, $event) = @_;
	if($event->{'button'} == 3) {
	    $exportmenu->show_all;
	    $exportmenu->popup( undef,undef,1,$event->{'time'},undef );
	}
    });

    $self->add($hpaned);
    return $self;
}

sub make_export_menu {
    my( $self ) = @_;
    my @mitems = ( { path  => '/Export List',
		     callback => sub { $self->open_export_dialog; } } );
    my $item_factory = new Gtk::ItemFactory( 'Gtk::Menu',
					     '<main>',
					     new Gtk::AccelGroup() );
    $item_factory->create_items( @mitems );
    return ( $item_factory->get_widget( '<main>' ) );
}

sub set_information_widget {
    my( $self, $type ) = @_;
    $self->{'switch'}->set_page( $type );
    $self->{'current_page'} = $type;
    if( $type == 0 && defined $self->{'contig'} ) {
	$self->update_list($self->{'contig'}->name);
    }
}

sub make_data_box {
    my( $self ) = @_;
    my $frame = new Gtk::Frame( 'ORF Data' );

    my @first  = ( 'Name:', 'Status:', 'Length:', 'Start:', 
		   'Start \ Stop Codon:', '%GC:', '%AC:', '#AA:', 'Mol Wt \ IEP:' );
    my @second = ( 'Gene Product:', 'Gene Name:', 'EC Number:', 'Category:', 'EMBL Feature:', 
		   'Description:', 'Comment:', 'Annotator:', 'Date:' );

    my $names = "\n";
    foreach( @first ) {
	$names .= "$_\n";
    }

    my $ln = new Gtk::Label( $names );
    $ln->set_justify( 'left' );

    my $hbox = new Gtk::HBox( 1, 1 );

    my $ll = new Gtk::Label;
    $ll->set_justify( 'left' );
    my $rl = new Gtk::Label;
    $rl->set_justify( 'left' );

    my $frame = new Gtk::Frame( "ORF information:" );
    my $fb = new Gtk::HBox( 0, 0 );
    $fb->pack_start( $ln, 0, 0, 5 );
    $fb->pack_start_defaults( $ll );
    $frame->add( $fb );

    $hbox->pack_start( $frame, 1, 1, 5 );

    my $names = "\n";
    foreach( @second ) {
	$names .= "$_\n";
    }

    my $ln = new Gtk::Label( $names );
    $ln->set_justify( 'left' );

    $frame = new Gtk::Frame( "Latest annotation:" );
    $fb = new Gtk::HBox( 0, 0 );
    $fb->pack_start( $ln, 0, 0, 5 );
    $fb->pack_start_defaults( $rl );
    $frame->add( $fb );    
   
    $hbox->pack_start( $frame, 1, 1, 5 );

    $self->{'left_label'} = $ll;
    $self->{'right_label'} = $rl;

    return $hbox;
}

sub orf_canvas {
    my( $self ) = @_;
    return $self->{'orf_canvas'};
}

sub set_base_view {
    my( $self, $bview ) = @_;
    $self->{'baseview'} = $bview;
}

sub sortlist {
    my( $list, $col, $self ) = @_;    
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

sub signal_connect {
    my( $self, $signal, $func, @data ) = @_;
    $self->{ $signal } = $func;
    $self->{ $signal."_data" } = \@data;
}

sub set_orf {
    if( $can_change ) {
	$can_change = 0;
	my( $self, $orf_id ) = @_;
	my $orf = GENDB::orf->init_id( $orf_id );
	my $contig = GENDB::contig->init_id( $orf->contig_id );
	&show_contig_orf( $self, $contig, $orf );
	$can_change = 1;
	return 1;
    } else {
	return 0;
    }
}

sub set_contig {
    my( $self, $contig ) = @_;
    &show_contig_orf( $self, $contig, undef );
}

sub get_contig {
    my ($self) = @_;
    
    return $self->{'contig'};
};

sub show_contig_orf {
    my( $self, $contig, $orf ) = @_;
    &contig_changed( undef, $contig->name, $self, $orf );
    if( defined( $orf ) ) { 
	&orfhi(  $orf, $self, 1 );
    }   
}

sub contig_changed {
    my( undef, $contig, $self, $orf ) = @_;
    if( $self->{'update'} ) {
	if( defined($self->{ 'contig' }) && $self->{ 'contig' }->name eq $contig ) {
	    return;
	}
	$self->{'update'} = 0;
	my $func = $self->{ 'contig_changed' }; 
	main->update_statusbar("Visualizing ORFs of Contig $contig. Please wait ...");
	&update_list( $self, $contig );
	if( ref $func eq 'CODE') {
	    &$func( $contig, @{$self->{'contig_changed_data'}} );
	}

	if(defined($self->{ 'baseview' })) {
	    $self->{ 'baseview' }->set_contig( $self->{ 'contig' } );
	}
	$self->{'cgplot'}->set_contig( $contig );
	main->update_statusbar("Visualizing ORFs of Contig $contig. Please wait ... Done!");
	$self->{'update'} = 1;
    }
}

sub update_list {
    my( $self, $cname ) = @_;
    my $list = $self->{ 'list' };
    my $configstr = GENDB::Tools::UserConfig->get_parameter("orf_list");
    my @config = split(/,/, $configstr);
    my $v= 1;
    foreach(@config) {
	$list->set_column_visibility($v++, $_);
    }

    if(!defined $cname) {
	return if(!defined $self->{'contig'});
	$cname = $self->{'contig'}->name;
    }

    my $contig = $self->{ 'contigs' }->{ $cname };
    my $orfs = $contig->fetchorfs;
    my $length = keys(%{ $orfs });

    $self->{ 'orf_canvas' }->set_contig( $contig );
    $self->{ 'contig' } = $contig;
    
    my %citems;
    $self->{ 'orfitems' } = \%citems;
    my %orfs;
    $self->{ 'orfs' } = \%orfs;
    $self->{ 'oldorf' } = undef;
    
    $list->clear;	

    my @list = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    if ( $self->{'current_page'} == 0 ) {
	$self->init_progress($length-1);
	
	$list->freeze;
	my $count = 0;
	my $iorfs = GENDB::Tools::UserConfig->get_parameter('ignored_orfs_in_list');
	foreach my $orfn( sort(keys(%{ $orfs })) ) {
	    my $orf = $orfs->{$orfn};
	    $self->{'orfs'}{$orfn} = $orf;
	    my $name;
	    next if(!$iorfs && $orf->status == 2);

	    if($config[4]) {
		if ($orf->status == $ORF_STATE_IGNORED) {
		    $name='--';
		} else {
		    my $annotation = $orf->latest_annotation_name;
		    if ($annotation) {
			$name=$annotation;
		    } else {
			$name=$orf->name;
		    }
		}
	    }
	    my $iep = sprintf( "%3.2f", $orf->isoelp ) if($config[12]);

	    $list[0]  = $orf->name           if(1);
	    $list[1]  = $ORF_STATES[$orf->status]         if($config[0]);
	    $list[2]  = $orf->length         if($config[1]);
	    $list[3]  = $orf->start          if($config[2]);
	    $list[4]  = $orf->stop           if($config[3]);
	    $list[5]  = $name                if($config[4]);
	    if ($config[5]) {
		if ($orf->frame > 0) {
		    $list[6] = "+".$orf->frame;
		}
		else {
		    $list[6] = $orf->frame;
		};
	    };
	    $list[7]  = uc($orf->startcodon) if($config[6]);
	    $list[8]  = uc($orf->stopcodon)  if($config[7]);
	    $list[9]  = sprintf( "%3.2f", $orf->gc )             if($config[8]);
	    $list[10]  = sprintf( "%3.2f", $orf->ag )             if($config[9]);
	    $list[11] = $orf->aalength       if($config[10]);
	    $list[12] = sprintf( "%3.2f", $orf->molweight )      if($config[11]);
	    $list[13] = $iep                 if($config[12]);

	    $list->append(@list);
	    
	    $count++;
	    $self->update_progress($count);
	}
	
	$list->thaw;
	$self->end_progress;
    }
    
    $self->get_parent_window->set_cursor( Gtk::Gdk::Cursor->new(68) );
}

sub row_selected {
    my( $list, $self, $row, $col, $event ) = @_;
    if( $event->{'type'} eq '2button_press' ) {
	my $orf = $self->{ 'orfs' }->{ $list->get_text( $row, 0 ) };
	&orfhi( $orf, $self, 0 );
    }
}

sub orfhi {
    my( $orf, $self, $updatelist ) = @_;
    if( $updatelist && $self->{'current_page'} == 0 ) {
	my $row = -1;
	for( my $i = 0; $i < $self->{ 'list' }->rows; $i++ ) {
	    if( $orf->name eq $self->{ 'list' }->get_text( $i, 0 ) ) {
		$row = $i;
		last;
	    }
	}
	$self->{ 'list' }->select_row( $row, 0 );
	$self->{ 'list' }->moveto( $row, 0, 0.5, 0 );
    } elsif( $self->{'current_page'} == 1 ) {
	my $annotation = $orf->latest_annotation;
	my $iep = sprintf( "%.3g", $orf->isoelp );
	my $lt = "";
	my $aliases = "(".join( ",", @{$orf->alias_names} ).")";
	$aliases = "" if( $#{$orf->alias_names} < 0 );
	$lt .= substr($orf->name.$aliases, 0, 35)."\n";
	$lt .= $ORF_STATES[$orf->status]."\n";
	$lt .= $orf->length."\n";
	$lt .= $orf->start."\n";
	$lt .= uc($orf->startcodon).' \ '.uc($orf->stopcodon)."\n";
	$lt .= $orf->gc."\n";
	$lt .= $orf->ag."\n";
	$lt .= $orf->aalength."\n";
	$lt .= $orf->molweight.' \ '.$iep;
	$self->{'left_label'}->set_text( $lt );
	
	if( $annotation != -1 ) {
	    $lt = "";
	    $lt .= substr($annotation->product, 0, 25)."\n";
	    $lt .= substr($annotation->name, 0, 25)."\n";
	    $lt .= $annotation->ec."\n";
	    my $funcat = GENDB::funcat->init_id( $annotation->category );
	    my $fname = "";
	    $fname = $funcat->name if( $funcat != -1 );
	    $lt .= substr($fname, 0, 25)."\n";
	    my $feature = GENDB::feature_type->init_id( $annotation->feature_type );
	    $fname = "";
	    $fname = $feature->name if( $feature != -1 );
	    $lt .= substr($fname, 0, 25 )."\n";
	    $lt .= substr($annotation->description, 0, 25 )."\n";
	    $lt .= substr($annotation->comment, 0, 25 )."\n";
	    my $annotator = GENDB::annotator->init_id($annotation->annotator_id);
	    $lt .= $annotator->name."\n";
	    my $date = localtime($annotation->date);
	    $lt .= $date;
	} else {
	    $lt = "-\n-\n-\n-\n-\n-\n-\n-\n-\n";
	}
	$self->{'right_label'}->set_text( $lt );
    } elsif( $self->{'current_page'} == 2 ) {
	$self->{'cgplot'}->hilite_orf( $orf );
    }

    $self->{ 'orf_canvas' }->hilite( $orf );
    $self->{'baseview'}->hilite( $orf );
    $self->{'baseview'}->parent->show;
}

sub update_contig_tree {
    my($self) = @_;
    delete $self->{ 'contigs' };
    $self->{ 'contigs' } = GENDB::contig->fetchallby_name;
    $self->{'tree'}->freeze;
    $self->{'tree'}->clear;
    $self->make_tree;
    $self->{'tree'}->thaw;
    $self->{'orf_canvas'}->update;
}

sub make_tree {
    my( $self ) = @_;
    my $tree = $self->{ 'tree' };
    my $contig_ref = GENDB::contig->fetchallby_name;

    my $root = $tree->insert_node(undef, undef, [main->gendb_project],
				  5,undef, undef, undef, undef,
				  0, 0 );
    
    foreach my $contig_name (sort(keys(%$contig_ref))) {
	my $ti = $tree->insert_node($root, undef, [$contig_name],
				    5,undef, undef, undef, undef,
				    0, 0 );
	my $contig = $contig_ref->{$contig_name};
	my @orf_stats = $contig->orf_stats;
	$tree->node_set_row_data( $ti, {name => $contig_name} );

	my $rna_count = pop @orf_stats;

	$tree->insert_node($ti, undef, [$contig->length()." bases"], 
			   5, undef, undef, undef, undef, 0, 0 );
	$tree->insert_node($ti, undef, [sprintf("%5d ORFs", $orf_stats[0])], 
			   5, undef, undef, undef, undef, 0, 0 );
	$tree->insert_node($ti, undef, [sprintf("%5d RNAs", $rna_count)],
			   5, undef, undef, undef, undef, 0, 0 );

	$tree->insert_node($ti, undef, [sprintf("%5d ignored", $orf_stats[3])], 
			   5, undef, undef, undef, undef, 0, 0 );

	my $ti2 = $tree->insert_node($ti, undef, 
				     [sprintf("%5d CDSs", ($orf_stats[0] - $orf_stats[3]))], 
				     5, undef, undef, undef, undef, 0, 0 );

	$tree->insert_node($ti2, undef, [sprintf("%5d finished", $orf_stats[4])], 
			   5, undef, undef, undef, undef, 0, 0 );
	$tree->insert_node($ti2, undef, [sprintf("%5d annotated", $orf_stats[2])], 
			   5, undef, undef, undef, undef, 0, 0 );
	$tree->insert_node($ti2, undef, [sprintf("%5d putative", $orf_stats[1])], 
			   5, undef, undef, undef, undef, 0, 0 );
	$tree->insert_node($ti2, undef, [sprintf("%5d need attention", $orf_stats[5])],
			   5, undef, undef, undef, undef, 0, 0 );
	$tree->insert_node($ti2, undef, [sprintf("%5d user state 1", int($orf_stats[6]))],
			   5, undef, undef, undef, undef, 0, 0 );
	$tree->insert_node($ti2, undef, [sprintf("%5d user state 2", int($orf_stats[7]))],
			   5, undef, undef, undef, undef, 0, 0 );
    }
    $tree->expand( $root );

    &tree_selection($tree, $self, 0, 0);
}

sub tree_selection {
    my( $tree, $self, $row, $col ) = @_;
    if( $can_change ) {
	$can_change = 0;
	if( defined( $tree->selection ) &&
	    defined( $tree->node_get_row_data( $tree->selection ) ) ) {
	    $selected_node = $tree->selection;
	    &contig_changed( $tree, $tree->node_get_row_data( 
				    $tree->selection )->{ 'name' }, $self );
	} else {
	    if( defined( $tree->selection ) ) {
		$tree->unselect( $tree->selection );
		if( defined( $selected_node ) ) {
		    $tree->select( $selected_node );
		}
	    }
	}
	$can_change = 1;
    } else {
	if( defined( $tree->selection ) ) {
	    $tree->unselect( $tree->selection );
	    if( defined( $selected_node ) ) {
		$tree->select( $selected_node );
	    }
	}
    }
}

### Callback for popup menu at Pathway Tree
sub show_contig_popup {
    my ( $widget, $self, $event ) = @_;
    my ($row, $column) = $widget->get_selection_info($event->{'x'}, $event->{'y'});

    if ($event->{'type'} eq '2button_press' && $can_change ) {
	&tree_selection( $widget, $self, $row, $column );
	return 0;
    } elsif ($event->{'type'} eq 'button_press') {
	if ($event->{'button'} == 3) {
	    $widget->select_row( $row, $column );
	    my $ctn = $widget->node_nth($row);
	    my $data_ref=$widget->node_get_row_data($ctn);
	    if (!$data_ref) {
		return 0;
	    } else {
		my $contig_name=$data_ref->{'name'};
		# Construct a GtkMenu 'contig_menu'
		my $contig_menu = new Gtk::Menu;    
		$contig_menu->border_width(1);
		
		# create a separator line
		my $separator = new Gtk::MenuItem;
		$separator->set_sensitive(0);

		
		# Construct a GtkMenuItem 'Plot contig'
		my $plot_item = new_with_label Gtk::MenuItem("Plot contig");
		$contig_menu->append($plot_item);
		$plot_item->show;

		# Construct a GtkMenuItem 'export as gff'
	        my $gff_export_item = new_with_label Gtk::MenuItem("Export gff");
		$contig_menu->append($gff_export_item);
		$gff_export_item->show;

		$separator = new Gtk::MenuItem;
		$contig_menu->append($separator);
		
		# Construct a GtkMenuItem 'export as FASTA'
		my $fasta_export_item = new_with_label Gtk::MenuItem("Export FASTA");
		$contig_menu->append($fasta_export_item);
		$fasta_export_item->show;
		
		# Construct a GtkMenuItem 'export as embl'
		my $embl_export_item = new_with_label Gtk::MenuItem("Export EMBL");
		$contig_menu->append($embl_export_item);
		$embl_export_item->show;

		# Construct a GtkMenuItem 'export as genbank'
		my $gbk_export_item = new_with_label Gtk::MenuItem("Export GENBANK");
		$contig_menu->append($gbk_export_item);
		$gbk_export_item->show;

		$separator = new Gtk::MenuItem;
		$contig_menu->append($separator);

		# Add menu item to run tRNAScan
		if (defined ($GENDB_TRNASCANSE)) {
		    my $trnascan_item = Gtk::MenuItem->new_with_label('Run tRNAScan-SE');
		    $contig_menu->append($trnascan_item);
		    $trnascan_item->show;
		    $trnascan_item->signal_connect('activate',
						   \&run_trnascan,
						   $contig_name,
						   $self);
		}

		$separator = new Gtk::MenuItem;
		$contig_menu->append($separator);
                
		# Construct a GtkMenuItem 'update'
	        my $update_item = new_with_label Gtk::MenuItem("Refresh");
		$contig_menu->append($update_item);
		$update_item->show;
		
		$contig_menu->show_all();

		# Connect all signals now 
		$update_item->signal_connect('activate', sub { main->update_contigs; });
		$plot_item->signal_connect( 'activate', \&plot_contig, $contig_name, $self );
		$gff_export_item->signal_connect( 'activate', \&Tools::gff_export::export_gff, $contig_name, $self);
		$embl_export_item->signal_connect( 'activate', \&Tools::embl_exporter::embl_export_dialog, $contig_name, $self);
		$gbk_export_item->signal_connect( 'activate', \&Tools::genbank_exporter::genbank_export_dialog, $contig_name, $self);
		$fasta_export_item->signal_connect( 'activate', \&Tools::fasta_exporter::fasta_export_dialog, 
						    $self->{ 'contigs' }->{ $contig_name }, 
						    $self );
		
		# $analyze_subways->signal_connect( 'activate', \&choose_ext_nodes_dialog, $pathname, $self );
		
		$contig_menu->popup(undef,undef,0,0,undef); ### oder $event->{'button'}
	    };
	};
    };    
};

#############################################
### plotting contig data with Genome_plot ###
#############################################
sub plot_contig {
    my ($widget, $cn, $self) = @_;

    main->update_statusbar("Fetching data for contig $cn. Please wait ...");

    my $contig = GENDB::contig->init_name($cn);
    my @orf_stats = $contig->orf_stats;
    my $orf_num=$orf_stats[0];
    my $i=1;

    $self->init_progress($orf_num);

    my $tmpname=POSIX::tmpnam();
    open(FILE, "> $tmpname") || die "Plot Contig:: Could not open file $tmpname!";
    
    my $length = 0;
    my $name;
    foreach $name (keys %{$contig->fetchorfs()}) {

        my $orf = GENDB::orf->init_name($name);
      
        my $function;
        my $annotation = $orf->latest_annotation;
	if (ref $annotation) {
	    $name = $annotation->name
        };

	if ($orf->status == $ORF_STATE_ANNOTATED) {
	    $function = 'function2';
	}
	elsif ($orf->status == $ORF_STATE_PUTATIVE) {
	    $function = 'function3';
	}
	elsif ($orf->status == $ORF_STATE_IGNORED) {
	    $self->update_progress($i++);
	    next; 
	}
	elsif ($orf->status == $ORF_STATE_FINISHED) {
	    $function = 'function6';
	}
	elsif ($orf->status == $ORF_STATE_ATTENTION_NEEDED) {
	    $function = 'function1';
	}
	elsif ($orf->status == $ORF_STATE_USER_1) {
	    $function = 'function5';
	}
	else {
	    $function = 'function4';
	}

        my $start=$orf->start;
        my $stop=$orf->stop;
        my $gc=$orf->gc;

        $name=~s/ /_/g;
        $function=~s/ /_/g;
        if ($orf->frame < 0) {
            $start=$orf->stop;
            $stop=$orf->start;
        };
#        print FILE "$name $function $start $stop $gc\n";
	print FILE "$name $function $start $stop\n";
	$self->update_progress($i++);
    };
    main->update_statusbar("Fetching data for contig $cn. Please wait... Done.");
    while (Gtk->events_pending) {
        Gtk->main_iteration;
    };

    close FILE;
    $self->end_progress;
    main->update_statusbar("Plotting contig $cn. Please wait...");
    while (Gtk->events_pending) {
        Gtk->main_iteration;
    };
    system("$GENDB_GENOMEPLOT -f $tmpname &");
    main->update_statusbar("Plotting contig $cn. Please wait... Done.");
};

sub open_export_dialog {
    my($self) = @_;
    my $dia = new Gtk::Dialog;
    $dia->set_title('Export Orflist');
    my $nb = new Gtk::Notebook;
    $nb->set_homogeneous_tabs(1);
    my @cols = @{$self->{'cols'}};
    my $tlist = new_with_titles Gtk::CList('id', 'Tool', 'Description');

    # filesel page
    my $vbox = new Gtk::VBox(0, 3);
    my $label = new Gtk::Label;
    $label->parse_uline("_E_x_p_o_r_t_ _t_a_b_l_e_ _t_o_ _f_i_l_e_:");
    my $hbox = new Gtk::HBox(1, 3);
    my $entry = new Gtk::Entry;
    my $browse = new Gtk::Button('Browse');
    my $hb = new Gtk::HBox(0, 0);
    my $frame = new Gtk::Frame('Table Information:');

    my $configstr = GENDB::Tools::UserConfig->get_parameter("orf_list");
    my @config = split(/,/, $configstr);
    my $cnt = 0;
    my $txt = 'Name';
    my $label1 = new Gtk::Label($txt);	
    my $label2 = new Gtk::Label($txt);	
    my $label3 = new Gtk::Label();
    my $label4 = new Gtk::Label();

    for(my $i = 0; $i <= $#config; $i++) {
	if($config[$i]) {
	    $txt .= "\n" if($txt ne '');
	    $txt .= $cols[$i];
	    $cnt++;
	}
	if($cnt == 6) {
	    $label1->set_text($txt);
	    $txt = '';
	}
    }
    if($cnt < 6) {
	while($cnt++ < 6) { $txt .= "\n" };
	$label1->set_text($txt);
	$txt = '';
    }
    while($cnt++ < 13) { $txt .= "\n" };
    
    $label2->set_text($txt);

    $label1->set_justify('left');
    $label2->set_justify('left');
    $label3->set_justify('left');
    $label4->set_justify('left');

    $hb->pack_start_defaults($label1);
    $hb->pack_start_defaults($label2);
    $hb->pack_start_defaults($label3);
    $hb->pack_start_defaults($label4);
    $frame->add($hb);
    $hbox->pack_start_defaults($entry);
    $hbox->pack_start_defaults($browse);
    $vbox->pack_start($label, 0, 0, 3);
    $vbox->pack_start($hbox, 0, 0, 3);
    $vbox->pack_start_defaults($frame);
    $nb->append_page($vbox, new Gtk::Label('Export'));

    # Annotation page
    my $frame = new Gtk::Frame('Add annotation');
    $hbox = new Gtk::HBox(0, 0);
    $vbox = new Gtk::VBox(1, 3);
    my %add_anno;
    foreach('Product', 'EC Number', 'Category', 'EMBL Feature') {
	$add_anno{$_} = new Gtk::CheckButton($_);
	$vbox->pack_start_defaults($add_anno{$_});
	$add_anno{$_}->signal_connect('toggled', sub{$self->make_label($label1, $label2, $label3, $label4, \%add_anno, $tlist)});
    }
    $hbox->pack_start_defaults($vbox);
    $vbox = new Gtk::VBox(1, 3);
    foreach('Description', 'Comment', 'Annotator', 'Date') {
	$add_anno{$_} = new Gtk::CheckButton($_);
	$vbox->pack_start_defaults($add_anno{$_});
	$add_anno{$_}->signal_connect('toggled', sub{$self->make_label($label1, $label2, $label3, $label4, \%add_anno, $tlist)});
    }
    $hbox->pack_start_defaults($vbox);
    $frame->add($hbox);
    $nb->append_page($frame, new Gtk::Label('Annotation'));
    $self->make_label($label1, $label2, $label3, $label4, \%add_anno, $tlist);

    # Facts page
    my $frame = new Gtk::Frame('Add best fact from tool:');
    my $scr = new Gtk::ScrolledWindow;
    $scr->set_policy('automatic', 'automatic');
    $tlist->set_column_visibility(0, 0);
    $tlist->set_selection_mode('multiple');
    $tlist->set_column_width(1, 150);
    my $tools = GENDB::tool->fetchall;
    foreach(@$tools) {
	$tlist->append($_->id, $_->name, $_->description);
    }
    $tlist->signal_connect('select_row', sub{$self->make_label($label1, $label2, $label3, $label4, \%add_anno, $tlist)});
    $tlist->signal_connect('unselect_row', sub{$self->make_label($label1, $label2, $label3, $label4, \%add_anno, $tlist)});
    $scr->add($tlist);
    $frame->add($scr);
    $nb->append_page($frame, new Gtk::Label('Facts'));

    $dia->vbox->add($nb);
    
    # buttons 
    my $ok = new Gtk::Button('OK');
    my $cancel = new Gtk::Button('Cancel');
    $dia->action_area->pack_start_defaults($ok);
    $dia->action_area->pack_start_defaults($cancel);

    $browse->signal_connect('clicked', sub {
      Utils::select_file(1, sub{$entry->set_text(shift)}, sub{});
    });

    $ok->signal_connect('clicked', sub { 
	my $file = $entry->get_text;
	if(!open(FILE, ">$file")) {
	  Utils::show_error("Could not open File $file!");
	    return;
	}
	main->update_statusbar("Export list to $file...");
	my $list = $self->{'list'};
	my @aconf;
	my $configstr = GENDB::Tools::UserConfig->get_parameter("orf_list");
	my @config = split(/,/, $configstr);
	my @tools = $tlist->selection;
	my @tconf;
	foreach(@tools) {
	    push(@tconf, $tlist->get_text($_, 0));
	}

	foreach('Product', 'EC Number', 'Category', 'EMBL Feature',
		'Description', 'Comment', 'Annotator', 'Date' ) {
	    push(@aconf, $add_anno{$_}->active);
	}
	
	# get column names
	my $column_names = '';
	$column_names .= &get_list_cols($list, \@config);
	$column_names .= &get_annot_cols(\@aconf);
	$column_names .= &get_fact_cols(\@tconf);

	print FILE "$column_names\n";

	$self->init_progress($list->rows);
	for(my $i = 0; $i < $list->rows; $i++) {
	    $self->update_progress($i);
	    my $orfn = $list->get_text($i, 0);
	    my $orf = GENDB::orf->init_name($orfn);
	    my $listentry = &get_list_entry($list, $i, \@config);
	    if( $orf != -1 ) {
		my $le = &get_annotation_entry($orf, \@aconf);
		my $te = &get_best_fact_entry($orf, \@tconf);
		$listentry .= $le.$te;
	    }
	    print FILE $listentry."\n";
	}
	$self->end_progress;
	main->update_statusbar("Export list to $file...done!");
	close FILE;
	$dia->destroy;
    });
    $cancel->signal_connect('clicked', sub{$dia->destroy});

    $dia->set_position('center');
    $dia->show_all;
}

sub make_label {
    my($self, $label1, $label2, $label3, $label4, $add_anno, $tlist) = @_;
    my $configstr = GENDB::Tools::UserConfig->get_parameter("orf_list");
    my @config = split(/,/, $configstr);
    my @cols = @{$self->{'cols'}};
    my $txt = "Name\n";
    my $cnt = 1;
    for(my $i = 0; $i <= $#config; $i++) {
	if($config[$i]) {
	    $txt .= $cols[$i+1]."\n";
	    $cnt++;
	    if($cnt == 6) {
		$label1->set_text(substr($txt, 0, length($txt)-1));
		$txt = '';
	    } elsif($cnt == 12 && $txt ne '') {
		$label2->set_text(substr($txt, 0, length($txt)-1));
		$txt = '';
	    }
	}
    }

    foreach('Product', 'EC Number', 'Category', 'EMBL Feature',
	    'Description', 'Comment', 'Annotator', 'Date' ) {
	if($add_anno->{$_}->active) {
	    $txt .= "$_\n";
	    $cnt++;
	    if($cnt == 6 && $txt ne '') {
		$label1->set_text(substr($txt, 0, length($txt)-1));
		$txt = '';
	    } elsif($cnt == 12 && $txt ne '') {
		$label2->set_text(substr($txt, 0, length($txt)-1));
		$txt = '';
	    } elsif($cnt == 18 && $txt ne '') {
		$label3->set_text(substr($txt, 0, length($txt)-1));
		$txt = '';
	    }
	}
    }

    my @sel = $tlist->selection;
    my $sel = $#sel + 1;
    if($sel) {
	my $hm = ($sel != 1) ? "s" : "";
	$txt .= "$sel Fact$hm\n";
	$cnt++;
	if($cnt == 6 && $txt ne '') {
	    $label1->set_text(substr($txt, 0, length($txt)-1));
	    $txt = '';
	} elsif($cnt == 12 && $txt ne '') {
	    $label2->set_text(substr($txt, 0, length($txt)-1));
	    $txt = '';
	} elsif($cnt == 18 && $txt ne '') {
	    $label3->set_text(substr($txt, 0, length($txt)-1));
	    $txt = '';
	}
    }
	    
    if($cnt < 6) {
	while($cnt++ < 6) { $txt .= "\n" };
	$label1->set_text(substr($txt, 0, length($txt)-1));
	$txt = '';
    }
    if($cnt < 12) {
	while($cnt++ < 12) { $txt .= "\n" };
	$label2->set_text(substr($txt, 0, length($txt)-1));
	$txt = '';
    }
    if($cnt < 18) {
	while($cnt++ < 18) { $txt .= "\n" };
	$label3->set_text(substr($txt, 0, length($txt)-1));
	$txt = '';
    }
    if($cnt < 24) {
	while($cnt++ < 24) { $txt .= "\n" };
	$label4->set_text(substr($txt, 0, length($txt)-1));
	$txt = '';
    }
}

sub get_best_fact_entry {
    my($orf, $tconf) = @_;
    my $orf_id = $orf->id;
    my $entry = '';
    foreach my $tool_id ( @$tconf ) {
	my $tool = GENDB::tool->init_id( $tool_id );
	next if( $tool == -1 );
	my $id = $tool->id;
	my $max_fact = undef;
	my $tool_facts = GENDB::fact->fetchbySQL( "orf_id = $orf_id AND tool_id = $id" );
	foreach( @$tool_facts ) {
	    if( defined( $max_fact ) ) {
		if( $_->score < $max_fact->score ) {
		    $max_fact = $_;
		} 
	    } else {
		$max_fact = $_;
	    }
	}
	next if( !defined( $max_fact ) );
	$entry .= $max_fact->dbref." -- ".$max_fact->score." -- ".$max_fact->description."\t";
    }
    $entry =~ tr/\n/  /;
    return $entry;
}

sub get_fact_cols {
    my ($tconf) = @_;

    my $list_cols = '';
    foreach my $tool_id ( @$tconf ) {
	my $tool = GENDB::tool->init_id( $tool_id );
	next if( $tool == -1 );
	$list_cols .= $tool->name()."\t";
    }

    return $list_cols;
}

sub get_annotation_entry {
    my($orf, $aconf) = @_;
    my $anno = $orf->latest_annotation;
    my $entry = '';
    $entry .= $anno->product."\t"         if($aconf->[0]);
    $entry .= $anno->ec."\t"              if($aconf->[1]);
    if($aconf->[2]) {
	my $funcat = GENDB::funcat->init_id( $anno->category );
	my $fname = "";
	$fname = $funcat->name if( $funcat != -1 );
	$entry .= $fname."\t";
    }
    if($aconf->[3]) {
	my $feature = GENDB::feature_type->init_id( $anno->feature_type );
	$fname = "";
	$fname = $feature->name if( $feature != -1 );
	$entry .= $fname."\t";
    }
    $entry .= $anno->description."\t"     if($aconf->[4]);
    $entry .= $anno->comment."\t"         if($aconf->[5]);
    if($aconf->[6]) {
	my $annotator = GENDB::annotator->init_id($anno->annotator_id);
	$entry .= $annotator->name."\t";
    }
    $entry .= localtime($anno->date)."\t" if($aconf->[7]);
    
    $entry =~ tr/\n/  /;
    return $entry;
}

sub get_annot_cols {
    my ($aconf) = @_;

    my $list_cols = '';
    $list_cols .= "product\t"         if($aconf->[0]);
    $list_cols .= "ec\t"              if($aconf->[1]);
    $list_cols .= "funcat\t"          if($aconf->[2]);
    $list_cols .= "feature_type\t"    if($aconf->[3]);
    $list_cols .= "description\t"     if($aconf->[4]);
    $list_cols .= "comment\t"         if($aconf->[5]);
    $list_cols .= "annotator\t"       if($aconf->[6]);
    $list_cols .= "date\t"            if($aconf->[7]);

    return $list_cols;
}

sub get_list_entry {
    my($list, $row, $config) = @_;
    my $entry = '';
    for( my $j = 0; $j < $list->columns; $j++ ) {
	if( $config->[$j-1] || $j == 0 ) {
	    $entry .= $list->get_text($row, $j)."\t";
	}
    }
    $entry =~ tr/\n/  /;
    return $entry;
}

sub get_list_cols {
    my($list, $config) = @_;

    my $list_cols = '';
    for( my $j = 0; $j < $list->columns; $j++ ) {
	if( $config->[$j-1] || $j == 0 ) {
	    $list_cols .= $list->get_column_title($j)."\t";
	}
    }
    return $list_cols;
}

# run trnascan for this contig
sub run_trnascan {
    my (undef, $contig_name, $self) = @_;
    
    my $contig = GENDB::contig->init_name($contig_name);
    require GENDB::Tools::tRNAScan;
    if (GENDB::Tools::tRNAScan::check_for_trnas($contig)) {
	my $do_remove=-1;
      Utils::show_yesno('Delete existing tRNA information for contig "'.$contig->name.'" and rerun tRNAScan-SE ?',
			main, sub {$do_remove=1;}, sub {$do_remove=0;});
	
	while ($do_remove == -1) {
	    while (Gtk->events_pending) {
		Gtk->main_iteration;
	    };
	}
	if ($do_remove) {
	  GENDB::Tools::tRNAScan::remove_trnas($contig);
	}
	else {
	    return;
	}
    }
    main->update_statusbar(sprintf "Running tRNAScan-SE for contig %s. This may take a few minutes. Please wait ...", $contig->name);
    while (Gtk->events_pending) {
        Gtk->main_iteration;
    };
  GENDB::Tools::tRNAScan::run_on_contig($contig);
    main->update_statusbar("tRNAScan-SE finished");
    while (Gtk->events_pending) {
        Gtk->main_iteration;
    };
    main->update_contigs;
}

1;
