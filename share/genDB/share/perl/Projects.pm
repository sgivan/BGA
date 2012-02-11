package Projects;
# $Id: Projects.pm,v 1.2 2006/05/31 18:13:19 givans Exp $
# this package is a fast hack to manage GENDB projects

use Carp qw(croak);
use GENDB::GENDB_CONFIG qw($GENDB_PROJECT_FILE);
use Exporter;
use strict;
use vars qw (@EXPORT $VERSION $projects $project_list_file);

@EXPORT=qw(init_project);

($VERSION) = ('$Revision: 1.2 $' =~ /([\d\.]+)/g);

my $projects={}; # big hairy global variable

1;

sub new {
  my $class = shift;
  my $db = shift;
  my $self = {};

  if ($db) {
    init_project($db);
  } else {
    _load_project_list();
  }
  bless($self, $class);

  return $self;
}

sub _load_project_list {
    my $projects={};
    open (PROJECTS, $GENDB_PROJECT_FILE) or 
	die "Cannot open project list file $GENDB_PROJECT_FILE";
    while (<PROJECTS>) {
	my ($projectname, $projectpath) = split /\s/;
	$projects->{$projectname} = $projectpath;
    }
    close (PROJECTS);
    return $projects;
}

sub _get_project_lib {
  #    my ($project_name) = @_;
  my $self = shift;
  my $project_name = shift;

  my $projects = _load_project_list();
  if (!exists $projects->{$project_name}) {
    # first try...project may be added to project list
    # after the last time the list was read
    _load_project_list();
  }
  return $projects->{$project_name};
}

sub _get_project_lib_deprecated {
  my ($project_name) = @_;

  my $projects = _load_project_list();
  if (!exists $projects->{$project_name}) {
    # first try...project may be added to project list
    # after the last time the list was read
    _load_project_list();
  }
  return $projects->{$project_name};
}


sub init_project {
  my $self = shift;
  my $project_name = shift;
  my $project;

  if ($project_name) {
    $project = $self->_init_project($project_name);
  } else {
#    $project_name = $self;# this is the old way -- $self is a text string
    _init_project_deprecated($self);
  }
  return $project;
}

 sub _init_project {
   my $self = shift;
   my $project_name = shift;

   eval {
     require Project;
   };

   if ($@) {
     croak "cannot find Project module:  $@";
   }

   my $project = Project->new($project_name);
#   $project->init($project_name);
#   print "Projects::_init_project:  \$project is a '", ref($project), "'\n";

   return $project;
 }

 sub _init_project_deprecated {
   my ($project_name) = @_;

   my $lib_dir = _get_project_lib_deprecated($project_name);

   if (defined ($lib_dir)) {
     # append project module hierarchie to include path
     # the project hierarchie has to be th first element
     unshift @INC, $lib_dir;

     # require all needed modules..
     eval { require GENDB::Config; import GENDB::Config;};


     if ($@) {
       croak "cannot 'use' GENDB::Config: $@";
     }
#     shift @INC;
   } else {
     croak "Projects::_init_project_deprecated:  unknown project name $project_name";
   }
 }

sub project_lib {
#    my ($project_name) = @_;
    my ($self,$project_name) = @_;

#    my $lib_dir = _get_project_lib($project_name);
    my $lib_dir = $self->_get_project_lib($project_name);
    if (defined $lib_dir) {
	return $lib_dir;
    }
    else {
	warn "unknown project name $project_name";
    }
}

sub list_projects {
  my $self = shift;
  my $projects = _load_project_list();
  my @project_names = keys %$projects;
  return \@project_names;
}

sub list_project_paths {
  my $self = shift;
  my %project_paths;

  while (my ($key,$value) = each %$projects) {
    $project_paths{$key} = $value;
  }
  return \%project_paths;
}

sub _projects {


}
