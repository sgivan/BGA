package GENDB::Pathways::PathView;

$VERSION = 1.1;

use POSIX;
use GENDB::Pathways::DBInterface;
use pathwayDB::enzyme;


#########################################################################
# create a file in gdl format for a pathway to be visualized using xvcg #
#########################################################################
sub createVCG_file {
    my ($path,$ecs_ref,$fac,$pb_ref)=@_;
    my $pb=$$pb_ref;
    my %path_ecs=%$ecs_ref;

    @nodes = GENDB::Pathways::DBInterface::getAllNodes($path);
    $pb->set_value(25);
    while (Gtk->events_pending) {
	Gtk->main_iteration;
    };

    @edges = GENDB::Pathways::DBInterface::getAllEdges($path);
    $pb->set_value(50);
    while (Gtk->events_pending) {
	Gtk->main_iteration;
    };
   
    # create vcg file #
    my $tmpname=POSIX::tmpnam();
    $path=~s/ /_/g;
    open(FILE, ">$tmpname.vcg") || die "Can't open file!!!";
    # write header information
    print FILE "/* #################################################### */\n
         graph: { title: \"$path\"
	          height: 800
	          width: 900
	          x: 40 
	          y: 40
	          manhatten_edges: yes
	          display_edge_labels: yes
	          port_sharing: no
                  priority_phase: yes
	          straight_phase: yes
	          color: white
	          layout_downfactor: 5 
	          layout_upfactor:   5 
	          layout_nearfactor: 200
                  /*layoutalgorithm: normal*/\n\n
/* ################# nodes #####################################*/\n";


    # write node data, nodes with status 'NODE' as rectangles, external nodes as rhombes, pathways as ellipses     
    my $nodenum=@nodes;
    my $step=25/$nodenum;
    my $p_val=50;
    foreach  $noderef (@nodes) {
	$node=$noderef->title;
	$status=$noderef->status;
	$label=$noderef->name;
	$type=$noderef->type;
	
	$newlabel=""; 
	# labels are separated after 1. '-' nearest to 30. character
	$labelLen=length($label);       
	$remainingStr=$label;
	$remainingLen=$labelLen;
	$offset=0;
	$len=$labelLen;
	
	while ($remainingLen > 30) {
	    $actStr=substr($remainingStr,0,29);
	    $trennPos=rindex($actStr,"-",29)+1;
	    $newlabel.=substr($remainingStr,0,$trennPos).'\n';
	    $len-=$trennPos;
	    $remainingStr=substr($remainingStr,$trennPos,$len);
	    $remainingLen=length($remainingStr);
	};
	$newlabel.=$remainingStr;
	
	if ($type eq '0') { #EXTERNAL NODE
	    $shape = 'shape: rhomb';
	    print FILE "node: { title:\"$node\" label:\"$newlabel\" color: black textcolor: white $shape }\n";
	}
	elsif ($status eq '0') { #PATHWAY NODE
	    $shape = 'shape: ellipse';
	    print FILE "node: { title:\"$node\" label:\"$newlabel\" color: black textcolor: white $shape }\n";
	} 
	else {
	    print FILE "node: { title:\"$node\" label:\"$newlabel\" color: black textcolor: white}\n";
	};
	
	#increment progressbar
	$p_val+=$step;
	$pb->set_value(int $p_val);
	while (Gtk->events_pending) {
	    Gtk->main_iteration;
	};

    };


    # write edge data
    my $edgenum=@edges;
    $step=25/$edgenum;
    foreach $edgeref (@edges) {
	$snode = $$edgeref{source}; 
	$tnode = $$edgeref{target}; 
	$elabel = $$edgeref{label};
	$estatus = $$edgeref{estatus};
	my $textcolor='black';
		
	$new_label="";
	@singleECs = split(',',$elabel);
	
      EC:foreach $s_ec (@singleECs) {
	  if ($s_ec!~/META|NON_ENZYMATIC|UNKNOWN_EC/) {
	      $occ=pathwayDB::enzyme->getEC_occurence($s_ec);
	      $new_label.=$s_ec.'('.$occ.")\n";
	  }
	  else {
	      $new_label=$elabel.',';  # necessary for chop
	  };

	  if (exists $path_ecs{$s_ec}) {
	      $textcolor = 'magenta';
	      last EC;
	  }
	  else {
	      $textcolor = 'black';
	  };
      };
	
	chop($new_label);
	if ($estatus eq '1') { #NORM-Edge
	    print FILE "edge: { sourcename:\"$snode\" targetname:\"$tnode\" label:\"$new_label\" color: red textcolor: $textcolor thickness: 4 }\n";
	};
	
	if ($estatus eq '0') { #BACK-Edge
	    print FILE "edge: { sourcename:\"$snode\" targetname:\"$tnode\" label:\"$new_label\" color: red textcolor: $textcolor backarrowsize: 10 backarrowstyle: solid thickness: 4 }\n";
	};
	
	#increment progressbar
	$p_val+=$step;
	$pb->set_value(int $p_val);
	while (Gtk->events_pending) {
	    Gtk->main_iteration;
	};

    };
    
    
    print FILE "}\n";
    close FILE;
    
    return($tmpname);
};
    
1;
