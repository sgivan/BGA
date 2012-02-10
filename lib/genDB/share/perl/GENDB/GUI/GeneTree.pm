package GeneTree;

($GENDB::GUI::GeneTree::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use strict;
use GENDB::GUI::GenDBWidget;
use GENDB::Config;
use GENDB::orf;
use GENDB::GUI::SearchOrf;

use vars qw(@ISA);

@ISA = qw(GenDBWidget);

sub new {
    my ($class) = @_;
    my $self = $class->SUPER::new;
    bless $self;

    #left for gene tree and right for search interface
    my $hpaned = new Gtk::HPaned;
    my $vpaned = new Gtk::VPaned;
    $vpaned->set_position( 300 );
    $vpaned->border_width( 5 );
    $vpaned->gutter_size( 10 );

    $hpaned->set_position( 200 );
    $hpaned->border_width( 5 );
    $hpaned->gutter_size( 10 );

    #frame for genes tree
    my $cframe = new Gtk::Frame( "Annotated Genes" );

    #scrolled window for gene tree
    my $scroller = new Gtk::ScrolledWindow;
    $scroller->set_policy( 'automatic', 'automatic' );

    my $tree = new Gtk::CTree(1,0);
    $tree->set_expander_style("none");
    $tree->set_line_style("dotted");
    $tree->signal_connect('select_row', \&select_node);

    &fill_genetree($tree);
    
    $scroller->add( $tree );
    $tree->show;

    my $cscroller = new Gtk::ScrolledWindow;
    $cscroller->set_policy( 'automatic', 'always' );

    my $cbox = new Gtk::VBox( 0, 0 );
    $cbox->pack_start( $cscroller, 1, 1, 1 );

    $cframe->add( $scroller );
    $hpaned->add1( $cframe );
    
    my $search = new SearchOrf;
    $self->add_child($search);
    $hpaned->add2( $search );
    $self->{'search_widget'} = $search;

    $self->{ 'canvas_parent' } = $cscroller;
    $self->{ 'canvas_p_p' } = $cbox;
    $self->{ 'tree' } = $tree;

    $self->add($hpaned);
    return $self;
};

sub set_contig {}

# toggle sort type between ascending and descending order
sub sortlist {
    my( $list, $col, $self ) = @_;    $list->set_sort_column( $col );
    $list->set_compare_func( \&sort_func );
    $list->sort;
    if ($list->sort_type eq 'ascending') { 
	$list->set_sort_type( 'descending' ); 
    }
    else { 
	$list->set_sort_type( 'ascending' ); 
    };
};

# use this function for sorting the elements in a row
sub sort_func {
    my( $list, $a, $b, $col ) = @_;

    return ( $a <=> $b or $a cmp $b );
};

sub update_tree {
    my($self) = @_;
    my $tree = $self->{'tree'};

    $self->{'search_widget'}->update;
    
    $tree->freeze;
    $tree->clear;
    &fill_genetree($tree);
    $tree->thaw;
}

sub fill_genetree {
    my ($tree) = @_;
    
    my $root = $tree->insert_node(undef,undef,["  $GENDB_PROJECT"], 5,undef, undef, undef, undef, 0, 1);
    $tree->node_set_row_data($root,{'root' => $GENDB_PROJECT});

    my $gene;
    foreach $gene (@{GENDB::orf->fetchAllOrfsWithState($ORF_STATE_ANNOTATED)}) {
	my $name = $gene->name();
	my $parent = $tree->insert_node( $root,undef,["  $name"], 5, undef, undef, undef, undef, 0, 0 );
	$tree->node_set_row_data($parent, {'name' => $name, 'type' => 'root', 'sibling' => undef} );
    };

    foreach $gene (@{GENDB::orf->fetchAllOrfsWithState($ORF_STATE_FINISHED)}) {
	my $name = $gene->name();
	my $parent = $tree->insert_node( $root,undef,["  $name"], 5, undef, undef, undef, undef, 0, 0 );
	$tree->node_set_row_data($parent, {'name' => $name, 'type' => 'root', 'sibling' => undef} );
    };    
    
    $tree->show;    
};

sub select_node {
    my($tr, $row, $col, $ev) = @_;
    return if($ev->{'type'} ne '2button_press');
    my $n = $tr->node_nth($row);
    my $data = $tr->node_get_row_data($n);
    return if(!defined $data);
    if(!defined $data->{'sibling'}) {
	&addGeneInformation($tr, $n, $data->{'name'}, $data->{'type'});
    }
    $tr->node_set_row_data($n, {'name' => $data->{'name'}, 'sibling' => 1, 'type' => $data->{'type'}} );
}

sub addGeneInformation {
    my ($tree, $parent, $name, $type) = @_;
    my $orf = GENDB::orf->init_name($name);
    
    $tree->freeze;

    if($type eq 'root') {
	my $alias = $tree->insert_node( $parent,undef,['  Alias names'], 5, undef, undef, undef, undef, 0, 0 );
	$tree->node_set_row_data($alias, {'name' => $name, 'type' => 'alias', 'sibling' => undef} );
	my $fact = $tree->insert_node( $parent,undef,['  Facts'], 5, undef, undef, undef, undef, 0, 0 );
	$tree->node_set_row_data($fact, {'name' => $name, 'type' => 'facts', 'sibling' => undef} );
	my $anno = $tree->insert_node( $parent,undef,['  Annotation'], 5, undef, undef, undef, undef, 0, 0 );
	$tree->node_set_row_data($anno, {'name' => $name, 'type' => 'anno', 'sibling' => undef} );
	
    } elsif($type eq 'alias') {
	my @alias = @{$orf->alias_names};
	if($#alias < 0) {
	    $tree->insert_node( $parent,undef,["  no alias Names"], 5, undef, undef, undef, undef, 1, 0 );
	} else {
	    foreach(@alias) {
		$tree->insert_node( $parent,undef,["  $_"], 5, undef, undef, undef, undef, 1, 0 );
	    }
	}
    } elsif($type eq 'facts') {
	my %facts = %{$orf->fetchfacts()};
	my @keys = sort keys %facts;
	if($#keys < 0) {
	    $tree->insert_node( $parent,undef,["  no Facts"], 5, undef, undef, undef, undef, 1, 0 );
	} else {
	    foreach(@keys) {
		$tree->insert_node( $parent,undef,["  ".$facts{$_}->dbref], 5, undef, undef, undef, undef, 1, 0 );
	    }
	}
    } elsif($type eq 'anno') {
	my $annotation = $orf->latest_annotation;
	if( $annotation != -1 ) {
	    foreach($annotation->product, $annotation->name, $annotation->description, $annotation->comment, 
		  GENDB::annotator->init_id($annotation->annotator_id)->name, scalar(localtime($annotation->date))) {
		$tree->insert_node( $parent,undef,["  $_"], 5, undef, undef, undef, undef, 1, 0 );
	    }
	}
    }
    $tree->thaw;
    $tree->expand($parent);
};

1;
