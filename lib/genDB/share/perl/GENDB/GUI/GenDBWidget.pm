package GenDBWidget;

($GENDB::GUI::GenDBWidget::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use Gtk;
use vars qw(@ISA);

@ISA = qw(Gtk::VBox);

#########################################
###                                   ###
### superclass for main gendb-widgets ###
### handels progressbar update        ###
###                                   ###
#########################################

sub new {
    my($class) = @_;
    my $self = $class->SUPER::new(0,0);
    bless $self, $class;

    return $self;
}

sub scroll {}

sub set_progress {
    my($self, $progressbar) = @_;
    my $cl = ref $self;
    $self->{'progressbar'} = $progressbar;
    foreach(@{$self->{'progress_childs'}}) {
	my $cl2 = ref $_;
	$_->set_progress($progressbar);
    }
}

sub add_child {
    my($self, $child) = @_;
    my $cl1 = ref $self;
    my $cl2 = ref $child;
    
    if(!defined $self->{'progressbar'}) {
	push(@{$self->{'progress_childs'}}, $child);
    } else {
	$child->set_progress($self->{'progressbar'});
    }
}

sub set_progress_cursor {
    my($self, $cursor) = @_;
    my $toplevel = $self->get_toplevel;
    if(defined $self->window) {
	$self->window->set_cursor(Gtk::Gdk::Cursor->new($cursor));
    }
    if(defined $toplevel->window) {
	$toplevel->window->set_cursor(Gtk::Gdk::Cursor->new($cursor));
	foreach($toplevel->children) {
	    $_->window->set_cursor(Gtk::Gdk::Cursor->new($cursor));
	}
    }
}

sub init_progress {
    my($self, $value) = @_;
    $self->set_progress_cursor(150);
    $self->{'progressbar'}->set_adjustment(new Gtk::Adjustment(0, 0, $value || 1, 0, 0, 0));
    $self->{'progressbar'}->set_show_text(1);
}

sub update_progress {
    my($self, $value) = @_;
    Gtk->main_iteration while(Gtk->events_pending);
    $self->{'progressbar'}->set_value($value);
}

sub end_progress {
    my($self) = @_;
    Gtk->main_iteration while(Gtk->events_pending);
    $self->{'progressbar'}->set_value(0);
    $self->{'progressbar'}->set_show_text(0);
    $self->set_progress_cursor(68);
}
