package GENDB::GUI::UpdateDialog;

use Gtk;
use vars(qw(@ISA));

use GENDB::contig;
use GENDB::GUI::Import;
#use GENDB::GUI::ImportFasta;

@ISA = qw(Gtk::Dialog);

sub new {
    my($class) = @_;
    my $self = $class->SUPER::new;
    bless $self, $class;

    $self->set_title("Update contigs");

    my $list = new_with_titles Gtk::CList("Choose contigs to update");
    $list->set_selection_mode('multiple');
    $list->column_titles_passive;
    my $scr = new Gtk::ScrolledWindow;
    $scr->set_policy('automatic', 'automatic');

    $scr->add($list);
    $self->vbox->add($scr);
    
    my $ok = new Gtk::Button("Update");
    my $cancel = new Gtk::Button("Cancel");
    my $bb = new Gtk::HButtonBox;
    $bb->set_layout('end');
    $bb->pack_start_defaults($ok);
    $bb->pack_start_defaults($cancel);
    $self->action_area->add($bb);

    foreach(sort @{GENDB::contig->fetchall}) {
	$list->append($_->name);
    }

    $cancel->signal_connect('clicked', sub { $self->destroy });
    $ok->signal_connect('clicked', sub { 
	my %old_contigs;
	foreach($list->selection) {
	    my $cname = $list->get_text($_, 0);
	    my $contig = GENDB::contig->init_name($cname);
	    $contig->name($_."_deprecated");
	    $old_contigs{$cname} = $contig;
	    my %orfs = %{$contig->fetchorfs};
	    foreach $orf (values %orfs ) {
		$orf->name($orf->name."_deprecated");
	    }
	}
	$self->hide;
      GENDB::GUI::Import::add_contig(undef, \$bb, sub {
	  my @new_contigs = @_;
	  if(@new_contigs == 0) {
	      foreach(keys %old_contigs) {
		  $old_contigs{$_}->name($_);
	      }
	  } else {
	    GENDB::contig->update_contigs(\%old_contigs, @new_contigs[0]);
	  }

	  $self->destroy;
      }, sub {   
	  foreach (keys %old_contigs) {
	      my $contig = $old_contigs{$_};
	      $contig->name($_);
	      my %orfs = %{$contig->fetchorfs};
	      foreach $orf (values %orfs ) {
		  my $name = $orf->name;
		  $name =~ s/_deprecated//g;
		  $orf->name($name);
	      }
	  }
      });
    });

    $self->set_default_size(400, 300);
    $self->set_position('center');
    
    return $self;
}

1;
