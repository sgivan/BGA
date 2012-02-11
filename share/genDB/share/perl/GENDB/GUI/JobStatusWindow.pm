package GENDB::GUI::JobStatusWindow;

$VERSION = 1.1;

use strict;
use Gtk;
use GENDB::orfstate;
use vars qw (@ISA);

# this is a separate window
@ISA = qw(Gtk::Window);

1;

##########################################
# this window shows a summary about jobs #
##########################################
my $timeout_default=120000;
 
sub new {
    my ($class, $timeout) = @_;
    my $self = $class->SUPER::new;
    $self->set_title("Job Summary");
    $self->set_position("mouse");
    
    my $table = new Gtk::HBox (0,0);
    my $labels = new Gtk::VBox (0,0);
    my $values = new Gtk::VBox (0,0);
    $table->pack_start($labels, 1, 1, 0);
    $table->pack_end($values, 1, 1, 0);
    
    my $newlabel=new Gtk::Label ('Jobs pending: ');
    $newlabel->set_justify('left');
    $labels->pack_start($newlabel, 1, 1, 0);
    my $newlabel=new Gtk::Label ('Jobs executing: ');
    $newlabel->set_justify('left');
    $labels->pack_start($newlabel, 1, 1, 0);
    my $newlabel=new Gtk::Label ('Jobs finished:');
    $newlabel->set_justify('left');
    $labels->pack_start($newlabel, 1, 1, 0);
    my $newlabel=new Gtk::Label ('Total number of jobs: ');
    $newlabel->set_justify('left');
    $labels->pack_start($newlabel, 1, 1, 0);
    
    $self->{'pending'}= new Gtk::Label (GENDB::orfstate::number_of_unfinished_jobs);
    $self->{'pending'}->set_justify('fill');
    $values->pack_start($self->{'pending'}, 1, 1, 0);

    $self->{'executing'}= new Gtk::Label (GENDB::orfstate::number_of_executing_jobs);
    $self->{'executing'}->set_justify('fill');
    $values->pack_start($self->{'executing'}, 1, 1, 0);

    $self->{'finished'}= new Gtk::Label (GENDB::orfstate::number_of_finished_jobs);
    $self->{'finished'}->set_justify('fill');
    $values->pack_start($self->{'finished'}, 1, 1, 0);

    $self->{'total'}= new Gtk::Label (GENDB::orfstate::number_of_jobs);
    $self->{'total'}->set_justify('fill');
    $values->pack_start($self->{'total'}, 1, 1, 0);

    $self->add($table);
    $self->{'timer'}=Gtk->timeout_add(($timeout) ? $timeout : $timeout_default,
				      \&jobs_update, $self);
    $self->signal_connect('delete_event', \&disable_timer, $self);
    $self->set_policy(0, 0, 1);
    bless $self;

    return $self;
};


sub jobs_update {
    my ($self) = @_;
    $self->{'pending'}->set_text(GENDB::orfstate::number_of_unfinished_jobs); 
    $self->{'executing'}->set_text(GENDB::orfstate::number_of_executing_jobs);
    $self->{'finished'}->set_text(GENDB::orfstate::number_of_finished_jobs);
    $self->{'total'}->set_text(GENDB::orfstate::number_of_jobs);

    return 0;
};


sub disable_timer {
    my ($self) = @_;
    Gtk->timeout_remove($self->{'timer'}); 
};
