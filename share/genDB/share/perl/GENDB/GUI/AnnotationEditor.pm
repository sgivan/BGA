package AnnotationEditor;

($VERSION) = ('$Revision: 1.1.1.1 $' =~ /([\d\.]+)/g);

use strict;
use Gtk;
use GENDB::orf;
use GENDB::funcat;
use GENDB::feature_type;
use GENDB::annotator;
use GENDB::Tools::ProjectConfig;
use vars qw(@ISA);

@ISA = qw(Gtk::Dialog);

my @ORF_STATES = ('putative',
		  'annotated',
		  'ignore - artificial ORF',
		  'finished', 
		  'attention needed',
		  'user state 1',
		  'user state 2');

my %ORF_STATES = ('putative' => 0,
		  'annotated' => 1,
		  'ignore - artificial ORF' => 2,
		  'finished' => 3, 
		  'attention needed' => 4,
		  'user state 1' => 5,
		  'user state 2' => 6);

my @widgetnames =  ('Gene Product', 
		    'Gene Name',
		    'EC Number',
		    'Category', 
		    'EMBL Feature',
		    'Description', 
		    'Comment',
		    'Annotator',
		    'Date' );


################################
###                          ###
###  Dialog to annotate ORFs ###
###                          ###
################################

sub new {
    my $class = shift;
    my $self = $class->SUPER::new;
    bless $self, $class;

    my $frame1 = new Gtk::Frame;
    my $hbox = new Gtk::HBox( 0, 0 );
    my $combo = new Gtk::Combo;
    my $funcat_label = new Gtk::Label;
    my $widgets = &create_widgets;

    my $topfuncats = GENDB::funcat->get_toplevel_funcats;
    my $fmenu = new Gtk::Menu;
    foreach( @$topfuncats ) {
	my $name = $_->name;
	my $fid = $_->id;
	my $item = new Gtk::MenuItem( $name );
	if( &next_level_funcats( $item, $_, $self ) ) { 
	    $item->signal_connect( 'activate', sub {
		$self->{'widgets'}{'Category'}->set_text( $name );
		$self->{'funcat_id'} = $fid;
	    } );
	}
	$fmenu->append( $item );
    }
    
    my $funcats = new Gtk::OptionMenu;
    $funcats->set_menu( $fmenu );

    my $topfeatures = GENDB::feature_type->get_toplevel_feature_types;
    $fmenu = new Gtk::Menu;
    foreach( @$topfeatures ) {
	my $name = $_->name;
	my $fid = $_->id;
	my $item = new Gtk::MenuItem( $name );
	if( &next_level_features( $item, $_, $self ) ) { 
	    $item->signal_connect( 'activate', sub {
		$self->{'widgets'}{'Category'}->set_text( $name );
		$self->{'feature_id'} = $fid;
	    } );
	}
	$fmenu->append( $item );
    }
    
    my $features = new Gtk::OptionMenu;
    $features->set_menu( $fmenu );

    $combo->entry->set_editable( 0 );
    $combo->set_popdown_strings( @ORF_STATES );
    $hbox->set_border_width(5);
    $hbox->pack_start( new Gtk::Label( 'Category:' ), 0, 0, 5 );
    $hbox->pack_end( $combo, 0, 0, 0 );
    $hbox->pack_end( new Gtk::Label( 'State: ' ), 0, 0, 5 );
    $hbox->pack_end( $features, 1, 1, 10 );
    $hbox->pack_end( new Gtk::Label( 'EMBL Feature:' ), 0, 0, 5 );
    $hbox->pack_end( $funcats, 1, 1, 10 );
    
    $frame1->add( $hbox );
    $self->vbox->pack_start( $frame1, 0, 0, 0 );
 
    my $frame = new Gtk::Frame();
    $frame->set_border_width(5);
    my $hbox1 = new Gtk::HBox( 0, 0 );
    my $list = new_with_titles Gtk::CList( ('ID', 'Annotator', 'Date') );
    $list->set_column_visibility( 0, 0 );
    $list->set_column_width(1, 120 );
    $list->set_column_width(2, 80 );
    $list->column_titles_passive;
    $list->signal_connect( 'select_row', \&show_annotation, $self );
    $hbox1->pack_start( $list, 0, 0, 0 );

    my $frame2 = new Gtk::Frame;
    $frame2->set_border_width(5);
    my $table = new Gtk::Table( 10, 300, 0 );
    $table->set_border_width(5);
    my $y = 0;
    foreach( @widgetnames ) {
	my $label = new Gtk::Label( $_ );
	my $add = 1;
	my $w = $widgets->{$_};
	if(ref $widgets->{$_} eq 'Gtk::Text') {
	    $w = new Gtk::ScrolledWindow;
	    $w->set_policy('automatic', 'automatic');
	    $w->add($widgets->{$_});
	    $add = 5;
	}

	# add popup menu for default gene product names
	if ($_ eq 'Gene Product') {
	    $w->signal_connect( 'event', \&geneprod_event );
	}

	$table->attach_defaults( $label, 0, 2, $y, $y+$add );
	$table->attach_defaults( $w, 3, 10, $y, $y+$add );
	$y += $add;
    }
    $frame2->add( $table );
    $hbox1->pack_end( $frame2, 1, 1, 1 );
    
    $frame->add( $hbox1 );
    $self->vbox->pack_end( $frame, 1, 1, 1 );
    
    my $bb = new Gtk::HButtonBox;
    $bb->set_layout('end');
    $bb->set_border_width(5);
    $self->action_area->add($bb);
    
    my $button = new Gtk::Button( 'Show current' );
    $button->signal_connect( 'clicked', \&show_current_annot, $self );
    $bb->pack_start_defaults($button);
    $button = new Gtk::Button( 'Add New' );
    $button->signal_connect( 'clicked', \&writetoDB, $self );
    $bb->pack_start_defaults($button);
    $button = new Gtk::Button( 'Dismiss' );
    $bb->pack_start_defaults($button);
    $button->signal_connect( 'clicked', sub{ $self->destroy } );

    $self->{ 'list' } = $list;
    $self->{ 'widgets' } = $widgets;
    $self->{ 'status' } = $combo;

    $self->set_position( 'center' );

    my $date = localtime(time());
    $self->{'widgets'}->{'Date'}->set_text($date);
    $self->{'widgets'}->{'Annotator'}->set_text($ENV{'USER'});
    
    # add necessary fields to store current annotation data
    $self->{'curr_row'} = 0;
    $self->{'prev_row'} = 0;
    $self->{'description'} = '';
    $self->{'comment'} = '';
    $self->{'ec'} = '';
    $self->{'product'} = '';
    $self->{'name'} = '';
    $self->{'funcat'} = '';
    $self->{'feature'} = '';
    $self->{'curr_status'} = '';

    return $self;
}

sub set_fact {
    my( $self, $fact ) = @_;
    my $db;
    my $id;

    if( $fact->dbref =~ /^(\w*)\|(.*)$/ ) {
	$db = $1;
	if( $db eq "trembl" || $db eq "tremblnew" ) { $db = "sptrembl" }
	elsif( $db eq "sprot" ) { $db = "swissprot" }
	$id = $2;
    } else {
	$db = "pfamhmm";
	$id = $fact->dbref;
    }
    my $tool = GENDB::tool->init_id ($fact->tool_id())->name;
    $self->{'widgets'}->{'Description'}->insert_text( $fact->description, 0 );
    $self->{'widgets'}->{'Description'}->set_point(0);
    $self->{'widgets'}->{'Comment'}->insert_text(
			  "Annotation derived from Facts\nDB: $db\nID: $id\nTool: $tool", 0 );
    $self->{'widgets'}->{'Comment'}->set_point(0);

    $self->{'widgets'}->{'EC Number'}->set_text( $fact->EC_number );
    $self->{'widgets'}->{'Gene Product'}->set_text( $fact->gene_product );
    $self->{'widgets'}->{'Gene Name'}->set_text( $fact->gene_name );
    $self->{'widgets'}->{'Gene Product'}->set_position(1);
    $self->{'widgets'}->{'Gene Name'}->set_position(1);

    $self->{ 'status' }->entry->set_text( 'annotated' );

}

sub show_annotation {
    my( $list, $self, $row, $col, $event ) = @_;

    if ($self->{'prev_row'} == 0) {
	$self->{'description'} = $self->{'widgets'}->{'Description'}->get_chars(0, -1);
	$self->{'comment'} = $self->{'widgets'}->{'Comment'}->get_chars(0, -1);
	$self->{'ec'} = $self->{'widgets'}->{'EC Number'}->get_chars(0, -1);
	$self->{'product'} = $self->{'widgets'}->{'Gene Product'}->get_chars(0, -1);
	$self->{'name'} = $self->{'widgets'}->{'Gene Name'}->get_chars(0, -1);
	$self->{'funcat'} = $self->{'widgets'}{'Category'}->get();
	$self->{'curr_funcat_id'} = $self->{'funcat_id'};
	$self->{'feature'} = $self->{'widgets'}{'EMBL Feature'}->get();
	$self->{'curr_feature_id'} = $self->{'feature_id'};
	$self->{'curr_status'} = $self->{'status'}->entry->get_text;

	$self->{'prev_row'} = 1;
    }
    
    $self->{'curr_row'} = $row;

    my $annotationid = $list->get_text($row, 0);
    my $annotation = GENDB::annotation->init_id($annotationid);
    my $annotator = GENDB::annotator->init_id($annotation->annotator_id);
    $self->{'widgets'}->{'Gene Product'}->set_text($annotation->product );
    $self->{'widgets'}->{'Gene Name'}->set_text($annotation->name );
    $self->{'widgets'}->{'EC Number'}->set_text($annotation->ec );
    my $funcat = GENDB::funcat->init_id( $annotation->category );
    my $fname = "";
    $fname = $funcat->name if( $funcat != -1 );
    $self->{'widgets'}->{'Category'}->set_text( $fname );
    $self->{'funcat_id'} = $annotation->category;
    
    my $feature = GENDB::feature_type->init_id( $annotation->feature_type );
    $fname = "";
    $fname = $feature->name if( $feature != -1 );
    $self->{'widgets'}->{'EMBL Feature'}->set_text( $fname );
    $self->{'feature_id'} = $annotation->feature_type;
    
    $self->{'widgets'}->{'Description'}->delete_text( 0, -1 );
    $self->{'widgets'}->{'Description'}->insert_text($annotation->description, 0 );
    $self->{'widgets'}->{'Comment'}->delete_text( 0, -1 );
    $self->{'widgets'}->{'Comment'}->insert_text($annotation->comment, 0 );
    
    $self->{'widgets'}->{'Annotator'}->set_text($annotator->name );
    my $date = localtime($annotation->date);
    $self->{'widgets'}->{'Date'}->set_text($date);
    
    my $orf = GENDB::orf->init_id($annotation->orf_id);
    $self->{ 'status' }->entry->set_text( $ORF_STATES[$orf->status()] );
}

sub set_orf {
    my( $self, $orf ) = @_;
    my $annotations_ref = $orf->fetch_annotations;
    my @annotations = sort { $b->date <=> $a->date } values(%$annotations_ref);
    my $status = $orf->status;
    foreach my $annotation (@annotations) {
	my $user = GENDB::annotator->init_id($annotation->annotator_id)->name;
	my @date = localtime($annotation->date);
	my $date = sprintf("%.2d.%.2d.%4d",
			   $date[3], $date[4]+1, $date[5]+1900);
	$self->{'list'}->append( $annotation->id, $user, $date );
    }
    $self->{'status'}->entry->set_text( $ORF_STATES[$status] );
    $self->{'orf'} = $orf;
    $self->set_title( "Annotations of ORF ".$orf->name );
}


sub writetoDB {
    my( undef, $self ) = @_;

    my $orf = $self->{'orf'};
    my $latest_annotation = $orf->latest_annotation;

    my $description = $self->{'widgets'}->{'Description'}->get_chars(0, -1);
    chomp($description);
    my $comment = $self->{'widgets'}->{'Comment'}->get_chars(0, -1);
    chomp($comment);

    my $status = $ORF_STATES{$self->{'status'}->entry->get_text};
    my $product = $self->{'widgets'}->{'Gene Product'}->get_chars(0, -1);
    my $genename = $self->{'widgets'}->{'Gene Name'}->get_chars(0, -1);
    my $enzyme = $self->{'widgets'}->{'EC Number'}->get_chars(0, -1);

    my $category = $self->{'funcat_id'} if( defined( $self->{'funcat_id'} ) );
    my $feature_type = $self->{'feature_id'} if( defined( $self->{'feature_id'} ) );
    

    # check for changes compared to current annotation
    my $diff = 0;
    $diff++ if ($orf->status ne $status);
    $diff++ if ($latest_annotation < 0);
    if ($latest_annotation > 0) {
	$diff++ if ($latest_annotation->product ne $product);
	$diff++ if ($latest_annotation->name ne $genename);
	$diff++ if ($latest_annotation->ec ne $enzyme);
	$diff++ if ($latest_annotation->category ne $category);
	$diff++ if ($latest_annotation->description ne $description);
	$diff++ if ($latest_annotation->comment ne $comment);
	$diff++ if ($latest_annotation->feature_type ne $feature_type);
    }

    if ($diff) {
	
	my $annotator = GENDB::annotator->init_name($ENV{'USER'});
	my $annoid;
	if ($annotator < 0) {
	  Utils::show_error( 'Sorry You are not allowed to annotate in this project!' );
	    return;
	} else {
	    $annoid = $annotator->id;
	}
	$orf->status($status);
	my $newannotation = GENDB::annotation->create($genename, $orf->id);
	if ($newannotation < 0) {
	  Utils::show_error( "can't create new annotation" );
	    return;
	} 
	$description =~ s/\(//g;
	$description =~ s/\)//g;

	$newannotation->mset({
	    'product' => $product,
	    'ec' => $enzyme,
	    'category' => $category,
	    'description' => $description,
	    'comment' => $comment,
	    'annotator_id' => $annoid,
	    'feature_type' => $feature_type,
	    'date' => time()
	    });

	# update the listview
	my $user = GENDB::annotator->init_id($newannotation->annotator_id)->name;
	my @date = localtime($newannotation->date);
	my $date = sprintf("%.2d.%.2d.%4d",
			   $date[3], $date[4]+1, $date[5]+1900);
	$self->{'list'}->append( $newannotation->id, $user, $date );

	main->update_orfs;
    }
    $self->destroy;
}

sub create_widgets {
    my %wids;
    $wids{ 'Gene Product' } = new Gtk::Entry;
    $wids{ 'Gene Name' } = new Gtk::Entry;
    $wids{ 'EC Number' } = new Gtk::Entry;
    $wids{ 'Category' } = new Gtk::Label;
    $wids{ 'EMBL Feature' } = new Gtk::Label;
    $wids{ 'Description' } = new Gtk::Text;
    $wids{ 'Description' }->set_editable( 1 );
    $wids{ 'Description' }->set_usize( 100, 50 );
    $wids{ 'Comment' } = new Gtk::Text;
    $wids{ 'Comment' }->set_editable( 1 );
    $wids{ 'Comment' }->set_usize( 100, 50 );
    $wids{ 'Annotator' } = new Gtk::Label;   
    $wids{ 'Date' } = new Gtk::Label;

    return \%wids;
}

sub next_level_funcats {
    my( $item, $parent, $self ) = @_;
    my $nmenu = new Gtk::Menu;

    my $nitem = new Gtk::MenuItem( $parent->name );
    $nitem->signal_connect( 'activate', sub {
	$self->{'widgets'}{'Category'}->set_text( $parent->name );
	$self->{'funcat_id'} = $parent->id;
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
	    $nitem->signal_connect( 'activate', sub {
		$self->{'widgets'}{'Category'}->set_text( $name );
		$self->{'funcat_id'} = $fid;
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
	$self->{'widgets'}{'EMBL Feature'}->set_text( $parent->name );
	$self->{'feature_id'} = $parent->id;
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
	    $nitem->signal_connect( 'activate', sub {
		$self->{'widgets'}{'EMBL Feature'}->set_text( $name );
		$self->{'feature_id'} = $fid;
	    } );
	}
	$nmenu->append( $nitem );
    }
    $item->set_submenu( $nmenu );
    return 0;
}


###################################################################################
# Callback at gene product text entry to popup a menu with default product names  #
###################################################################################
sub geneprod_event {
    my( $entry, $event ) = @_;

    if ($event->{'type'} eq 'button_press') {
	if ($event->{'button'} == 3) {
	    # Construct a GtkMenu ''
	    my $product_menu = new Gtk::Menu;    
	    $product_menu->border_width(1);
	    
	    # get default gene products from ProjectConfig
	    my @geneproducts = split(",", GENDB::Tools::ProjectConfig->get_parameter("gene products"));

	    foreach (@geneproducts) {
		# Construct a GtkMenuItem for each default gene product
		my $product_item = new_with_label Gtk::MenuItem($_);
		$product_menu->append($product_item);
		$product_item->show;
		
		# Connect signal to set the default product name now 
		$product_item->signal_connect( 'activate', \&set_default_product, $entry, $_);
	    }

	    $product_menu->popup(undef,undef,1,$event->{'time'},undef);
	}
    }
}
 

##################################################################
# Callback at gene product menu item to set default product name #
##################################################################
sub set_default_product {
    my( $menu_item, $entry, $label ) = @_;
    
    $entry->set_text($label);
    
}


########################################################################
# Callback at 'Show current' button to display current user annotation #
########################################################################
sub show_current_annot {
    my( $button, $self ) = @_;
    
    $self->{'widgets'}->{'Description'}->delete_text( 0, -1 );
    $self->{'widgets'}->{'Description'}->insert_text( $self->{'description'}, 0 );
    $self->{'widgets'}->{'Comment'}->delete_text( 0, -1 );
    $self->{'widgets'}->{'Comment'}->insert_text($self->{'comment'}, 0 );
    $self->{'widgets'}->{'Description'}->set_point(0);
    $self->{'widgets'}->{'Comment'}->set_point(0);

    $self->{'widgets'}{'EMBL Feature'}->set_text( $self->{'feature'} );
    $self->{'widgets'}{'Category'}->set_text( $self->{'funcat'} );

    $self->{'widgets'}->{'EC Number'}->set_text( $self->{'ec'} );
    $self->{'widgets'}->{'Gene Product'}->set_text( $self->{'product'} );
    $self->{'widgets'}->{'Gene Product'}->set_position(1);
    $self->{'widgets'}->{'Gene Name'}->set_text( $self->{'name'} );
    $self->{'widgets'}->{'Gene Name'}->set_position(1);

    $self->{ 'status' }->entry->set_text( $self->{'curr_status'} );
    
    my $date = localtime(time());
    $self->{'widgets'}->{'Date'}->set_text($date);
    $self->{'widgets'}->{'Annotator'}->set_text($ENV{'USER'});

    $self->{'prev_row'} = 0;

    $self->{'list'}->unselect_row($self->{'curr_row'},0);
    
}

1;
