package Project;
# $Id$

use warnings;
use strict;
use Carp;
use vars qw/ @ISA @INC $GENDB_DBSOURCE /;
#use lib '/local/cluster/genDB/share/perl';
use Exporter;
use Projects;


@ISA = qw/ Projects /;

1;

 sub new {
   my $pkg = shift;
   my $project_name = shift;

   my $self = $pkg->SUPER::new($project_name);
   $self->init($project_name);
   return $self;
 }


sub init {
  my $self = shift;
  my $project_name = shift || $self->name();

  if ($project_name) {
    $self->_init($project_name);
  }
#  print "Project::init: \$self isa '", ref($self), "'\n";
  return $self;
}

sub _init {
#  print "Project::_init called\n";

  my $self = shift;
  my $project_name = shift;

  my $lib_dir = $self->_get_project_lib($project_name);
#  print "project lib dir: '$lib_dir'\n";
  if (defined ($lib_dir)) {
    # append project module hierarchie to include path
    # the project hierarchie has to be th first element
#    unshift @INC, $lib_dir;
    my @tempINC = @INC;
    @INC = ();
    foreach my $path (@tempINC) {
      if ($path !~ /gendb\/lib/i) {
	push(@INC,$path);
      }
    }
    unshift @INC, $lib_dir;

    # require all needed modules..
#    eval { require GENDB::Config; import GENDB::Config;};
    eval { 
#      require GENDB::DBMS;
#      GENDB::DBMS::switch_db($GENDB_DBSOURCE);
      require "$lib_dir/GENDB/Config.pm";
      import GENDB::Config;
      require GENDB::DBMS;
      GENDB::DBMS::switch_db($GENDB_DBSOURCE);
    };

    if ($@) {
      croak "cannot 'use' GENDB::Config: $@";
    }
#    map { print "$_\n" } @INC;
#    shift @INC;
#    map { print "$_\n" } @INC;
    $self->{name} = $project_name;
  } else {
    croak "Project::_init:  unknown project name $project_name";
  }
}

sub name {
  my $self = shift;
  my $name = shift;

  $name ? $self->{name} = $name : return $self->{name};
}

sub contig {
  my $self = shift;

  $self->_init_contig();
}

sub _init_contig {
  my $self =shift;

  eval {
    require GENDB::contig;
  };
  if ($@) {
    croak("can't load GENDB::contig: $@");
  }
}

sub annotation {
  my $self = shift;

  $self->_init_annotation();
}

sub _init_annotation {
  my $self = shift;

  eval {
    require GENDB::annotation;
  };
  if ($@) {
    croak("can't load GENDB::annotation: $@");
  }

}

sub fact {
  my $self = shift;

  $self->_init_fact();
}

sub _init_fact {
  my $self = shift;

  eval {
    require GENDB::fact;
  };
  if ($@) {
    croak("can't load GENDB::fact: $@");
  }
}

sub orf {
  my $self = shift;

  $self->_init_orf();
}

sub _init_orf {
  my $self = shift;

  eval {
    require GENDB::orf;
  };
  if ($@) {
    croak("can't load GENDB::orf: $@");
  }
}

sub orfstate {
  my $self = shift;

  $self->_init_orfstate();
}

sub _init_orfstate {
  my $self = shift;

  eval {
    require GENDB::orfstate;
  };
  if ($@) {
    croak("can't load GENDB::orfstate: $@");
  }
}

sub tool {
  my $self = shift;

  $self->_init_tool();
}

sub _init_tool {
  my $self = shift;

  eval {
    require GENDB::tool;
  };
  if ($@) {
    croak("can't load GENDB::tool: $@");
  }
}
