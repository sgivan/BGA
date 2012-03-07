package CGRB::PFAM;
# $Id: PFAM.pm,v 3.3 2006/10/09 22:52:50 givans Exp $

use strict;
use Carp;


use CGRB::CGRBDB;
use vars qw/ @ISA /;

@ISA = qw/ CGRBDB /;

1;

sub new {
  my $pkg = shift;

  my $self = $pkg->generate('PFAM25','genDB_web','microbes');

  return $self;
}

sub interpro_go {
  my $self = shift;
  my $pfamID = shift;

  $self->_get_interpro_go($pfamID);
}

sub _get_interpro_go {
  my $self = shift;
  my $pfamID = shift;
  my $dbh = $self->dbh();
  my ($sth,$rtn);
  my $pfam_autoID = $self->id_to_autoID($pfamID);
#  print "pfam_acc = '$pfamID', auto_pfamA = '$pfam_autoID'\n";

#   $sth = $dbh->prepare("select interpro_and_go.interpro_id, interpro_abstract, go_function , go_component, go_process, pfamA.auto_pfamA \
#                         from pfamA, interpro_and_go, pfam_to_interpro \
#                         where pfamA_id = ? and pfamA.auto_pfamA = pfam_to_interpro.auto_pfamA \
#                         and pfam_to_interpro.auto_interpro = interpro_and_go.auto_interpro"
# 		      );

  $sth = $dbh->prepare("select i.interpro_id, i.abstract, g.go_id, g.term, g.category from interpro i, gene_ontology g where i.auto_pfamA = ? and g.auto_pfamA = ?");

#  $sth->bind_param(1,$pfamID);
  $sth->bind_param(1,$pfam_autoID);
  $sth->bind_param(2,$pfam_autoID);

  $rtn = $self->dbAction($dbh,$sth,2);

  if ($rtn) {
    return $rtn;
  } else {
    return undef;
  }

}

sub interpro {
  my $self = shift;
  my $pfamID = shift;

  $self->_get_interpro($pfamID);
}

sub _get_interpro {
  my $self = shift;
  my $pfamID = shift;
  my $table = 'interpro';
  my ($dbh,$sth,$rtn) = ($self->dbh());
  my $pfam_autoID = $self->id_to_autoID($pfamID);

  $sth = $dbh->prepare("select `interpro_id`, `abstract` from interpro where `auto_pfamA` = ?");
  $sth->bind_param(1,$pfam_autoID);

  $rtn = $self->dbAction($dbh,$sth,2);

  if ($rtn) {
    return $rtn;
  } else {
    return undef;
  }
}

sub go {
  my $self = shift;
  my $pfamID = shift;

  $self->_get_go($pfamID);
}

sub _get_go {
  my $self = shift;
  my $pfamID = shift;
  my ($dbh,$sth,$rtn) = ($self->dbh());
  my $pfam_autoID = $self->id_to_autoID($pfamID);

  $sth = $dbh->prepare("select `go_id`, `term`, `category` from gene_ontology where `auto_pfamA` = ?");
  $sth->bind_param(1,$pfam_autoID);

  $rtn = $self->dbAction($dbh,$sth,2);

  if ($rtn) {
    return $rtn;
  } else {
    return undef;
  }
}

sub fetchRow_by_accession {
  my $self = shift;
  my $pfam_acc = shift;
  my $table = shift;
  my ($rtn);
  $table = 'pfamA' unless ($table);

  $rtn = $self->sselect('*',$table,'pfamA_acc',$pfam_acc);

  if ($rtn) {
    return $rtn;
  } else {
    return undef;
  }
}

sub _return_arrayref {
  my $rslt = shift;
  my $elem = shift;
  $elem = 0 unless ($elem);
  my @rtn;

  if ($rslt) {
    if (ref($rslt) == 'ARRAY') {
      foreach my $row (@$rslt) {
	push(@rtn,$row->[$elem]);
      }
    }
  }
  if (@rtn) {
    return \@rtn;
  } else {
    return undef;
  }
}

sub interpro_id {
  my $self = shift;
  my $pfamID = shift;
  my @rtn;
  my $rslt = $self->interpro_go($pfamID);
#  _return_arrayref($self->interpro_go($pfamID),0);
  _return_arrayref($self->interpro($pfamID),0);
}

sub interpro_abstract {
  my $self = shift;
  my $pfamID = shift;
#  _return_arrayref($self->interpro_go($pfamID),1);

#  my $aref = $self->interpro($pfamID);
#  _return_arrayref($self->interpro_go($pfamID),1);
  _return_arrayref($self->interpro($pfamID),1);
}

sub interpro_info {
  my $self = shift;
  my $pfamID = shift;
  my @rtn;

  my $ids = $self->interpro_id($pfamID);
  my $abstracts = $self->interpro_abstract($pfamID);

  for (my $i = 0; $i < scalar(@$ids); ++$i) {
    push(@rtn, [$ids->[$i], $abstracts->[$i]]);
  }
  return \@rtn;
}

sub go_function {
  my $self = shift;
  my $pfamID = shift;
#  _return_arrayref($self->interpro_go($pfamID),2);
  return ['deprecated method, use go_category()'];
}

sub go_component {
  my $self = shift;
  my $pfamID = shift;
#  _return_arrayref($self->interpro_go($pfamID),3);
  return ['deprecated method, use go_category()'];
}

sub go_process {
  my $self = shift;
  my $pfamID = shift;
#  _return_arrayref($self->interpro_go($pfamID),4);
  return ['deprecated method, use go_category()'];
}

sub go_category {
  my $self = shift;
  my $pfamID = shift;
  _return_arrayref($self->go($pfamID),2);
}

sub go_term {
  my $self = shift;
  my $pfamID = shift;
  _return_arrayref($self->go($pfamID),1);
}

sub go_id {
  my $self = shift;
  my $pfamID = shift;
  _return_arrayref($self->go($pfamID),0);
}

sub go_info {
  my $self = shift;
  my $pfamID = shift;
  my @rtn;

  my $go_id = $self->go_id($pfamID);
  my $go_term = $self->go_term($pfamID);
  my $go_category = $self->go_category($pfamID);

  for (my $i = 0; $i < scalar(@$go_id); ++$i) {
    push(@rtn, [$go_id->[$i], $go_term->[$i], $go_category->[$i]]);
  }
  return \@rtn;
}

sub pfam_autoID {
  my $self = shift;
  my $pfamID = shift;
#  _return_arrayref($self->interpro_go($pfamID),5);
  $self->id_to_autoID($pfamID);
}

sub acc_to_id {
  my $self = shift;
  my $pfam_acc = shift;
  return undef unless ($pfam_acc);

  my $rtn = _return_arrayref($self->fetchRow_by_accession($pfam_acc,'pfamA'),2);

  if ($rtn) {
    return $rtn->[0];
  }
  return undef;
}

sub id_to_acc {
  my $self = shift;
  my $pfam_id = shift;
  return undef unless ($pfam_id =~ /\w+/);

  my $rtn = $self->sselect('pfamA_acc','pfamA','pfamA_id',$pfam_id);

  if ($rtn) {
#    print "returning: '", $rtn->[0]->[0], "'\n";
    return $rtn->[0]->[0];
  } else {
    return undef;
  }
}

sub acc_to_autoID {
  my $self = shift;
  my $pfam_acc = shift;

  my $rtn = _return_arrayref($self->fetchRow_by_accession($pfam_acc,'pfamA'),0);

  if ($rtn) {
    return $rtn->[0];
  }
  return undef;
}

sub id_to_autoID {
  my $self = shift;
  my $pfam_id = shift;

  my $rtn = $self->sselect('auto_pfamA','pfamA','pfamA_id',$pfam_id);

  if ($rtn) {
    return $rtn->[0]->[0];
  } else {
    return undef;
  }
}

sub fetch_NCBI_species {
  my $self = shift;
  my $pfam_acc = shift;

  # Need the auto_id of the pfamseq
  if (my $rtn = _return_arrayref($self->fetchRow_by_accession($pfam_acc,'pfamseq'),0)) {
    # have auto_id of pfamseq, use to get ncbi_code from pfamseq_ncbi

    exit(0);
    my  $ncbi_code = $self->sselect('ncbi_code','pfamseq_ncbi','auto_pfamseq',$rtn->[0]);
    if ($ncbi_code) {
      return $self->sselect('species','ncbi_taxonomy','ncbi_code',$ncbi_code->[0]->[0]);
    }
  }
  return undef;
}

sub _get_species {


}

sub get_Seq_by_id {# this retrieves a pfamseq, not a pfamA sequence
  my $self = shift;
  my $dbRef = shift;

  my $rtn = $self->sselect('sequence','pfamseq','pfamseq_id',$dbRef);

  if ($rtn) {

    eval {
      require Bio::Seq::SeqFactory;
      };
    return undef if ($@);

    my $factory = Bio::Seq::SeqFactory->new();
    my $seq = $factory->create(
			       -id	=>	$dbRef,
			       -seq	=>	$rtn->[0]->[0],
			      );
    return $seq;
  }
  return undef;
}

sub pfam_description {
  my $self = shift;
  my $pfamID = shift;

  my $row = $self->fetchRow_by_accession($self->id_to_acc($pfamID));

  if ($row) {
#    return $row->[0]->[3];# not sure why, but this needs to be updated
    return $row->[0]->[4];
  } else {
    return undef;
  }
}
