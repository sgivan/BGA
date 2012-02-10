package GENDB::Pathways::SubwayView;

$VERSION = 1.2;

require 5.003;
require Exporter;

use Config;
use POSIX;
use GENDB::GENDB_CONFIG;
use GENDB::Pathways::DBInterface;

use pathwayDB::enzyme;

$vcg_path = $GENDB_XVCG;    

sub viewSubway {
    my ($p_id, $p_name, $ecs_ref, $sub_path_nr, $sub_path_chks, $iv_sub_path_chks, $fac, $pb)=@_;
    
    $tmpname=POSIX::tmpnam();
    my $fh=&getSubway_IMG($p_name,$p_id,$ecs_ref,$sub_path_nr,$sub_path_chks,$iv_sub_path_chks,$fac,$tmpname, $pb);
    
    return($fh);
};


#####################################################
# create an image of a selected subway in a pathway #
#####################################################
sub getSubway_IMG {
    my ($path,$path_id,$ec_ref,$sub_path_nr,$valid_sub_chunks,$invalid_sub_chunks,$fac,$tmpname, $pb_ref)=@_;
    
    my $pb=$$pb_ref;
    my %path_ecs=%$ec_ref;
    @nodes = &getAllNodes($path);
    $pb->set_value(20);
    while (Gtk->events_pending) {
	Gtk->main_iteration;
    };
    @edges = &getAllEdges($path);
    $pb->set_value(40);
    while (Gtk->events_pending) {
	Gtk->main_iteration;
    };
        
    $edge_str=pathwayDB::pathway_edges->getSubwayEdges($path_id,$sub_path_nr,$valid_sub_chunks);
    $invalid_edge_str=pathwayDB::pathway_edges->getSubwayEdges($path_id,$sub_path_nr,$invalid_sub_chunks);
        
    # create vcg-file
    open(FILE, ">$tmpname.vcg") || die "Can't open file!!!";
    print FILE "/* #################################################### */\n
         graph: { title: \"$path\"
	          height: 800
	          width: 900
	          x: 40 
	          y: 40
	          manhatten_edges: yes
	          display_edge_labels: yes
	          port_sharing: no
	          straight_phase: yes
	          color: white
	          layout_downfactor: 5 
	          layout_upfactor:   5 
	          layout_nearfactor: 200
                  /*layoutalgorithm: normal*/\n\n
/* ################# nodes #####################################*/\n";


    # prepare nodes for writing in GDL notation
    # Status 'NODE' => shape rect, 'PATHWAY' => shape ellipse,
    # Type 'EXTERNAL' => shape rhomb     
    my $nodenum=@nodes;
    my $step=25/$nodenum;
    my $p_val=40;
    foreach  $noderef (@nodes) {
	$node=$noderef->title;
	$status=$noderef->status;
	$label=$noderef->name;
	$type=$noderef->type;
	
	$newlabel="";                   #linebreak labels > 30 
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
	
	if ($type eq '0') { #EXTERNER Knoten
	    $shape = 'shape: rhomb';
	    print FILE "node: { title:\"$node\" label:\"$newlabel\" color: black textcolor: white $shape }\n";
	}
	elsif ($status eq '0') { #PATHWAY Knoten
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
	
	# edges contained in edgestring are drawn in different style!!!
	$line_st='continuous';
	$clr='red';
	$edg=$snode.'-'.$tnode;

	if ($edge_str=~/$edg/) {
	    $line_st='dotted';
	    $clr='blue';
	};
	
	if ($invalid_edge_str=~/$edg/) {
	    $line_st='dotted';
	    $clr='orange';
	};
	    
	@singleECs = split(',',$elabel);
	
      EC:foreach $s_ec (@singleECs) {
	  
	  if ($s_ec!~/META|NON_ENZYMATIC|UNKNOWN_EC/) {
	      $occ=pathwayDB::enzyme->getEC_occurence($s_ec);
	      $new_label.=$s_ec.'('.$occ.")\n";
	  }
	  else {
	      $new_label=$elabel.',';  #necessary because new label will be chopped
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
	    print FILE "edge: { sourcename:\"$snode\" targetname:\"$tnode\" label:\"$new_label\" linestyle: $line_st color: $clr textcolor: $textcolor thickness: 4 }\n";
	};
	
	if ($estatus eq '0') { #BACK-Edge
	    print FILE "edge: { sourcename:\"$snode\" targetname:\"$tnode\" label:\"$new_label\" linestyle: $line_st color: $clr textcolor: $textcolor backarrowsize: 10 backarrowstyle: solid thickness: 4 }\n";
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
   
    # System-Calls for conversion VCG -> PPM -> PNG 
    system("$vcg_path -ppmoutput $tmpname.ppm -silent -xdpi $fac -ydpi $fac $tmpname.vcg");

    return($tmpname);
};


1;
