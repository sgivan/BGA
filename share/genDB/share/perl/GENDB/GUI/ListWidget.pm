package GENDB::GUI::ListWidget;

# generic widget to create lists

# $Id: ListWidget.pm,v 1.1.1.1 2005/02/22 18:05:36 givans Exp $

# $Log: ListWidget.pm,v $
# Revision 1.1.1.1  2005/02/22 18:05:36  givans
#
#
# Revision 1.1  2002/04/15 14:06:13  blinke
# Initial revision
#


use vars qw (@ISA);
use strict;

use Gtk;

@ISA=qw(Gtk::VBox);

1;

# main list creator
#
# creates a vbox with a list widget and several buttons
#
# parameters: titles
#             elements       array of list elements
#             callback       callback used when filling the list
#                            with elements
#
#             buttons        array of hash containing a description of buttons
#                            (key = button name, value = callback
#                             to invoke when button is pressed)
#
# returns:    gtk widget 
#
sub new {
    my ($class, $homogeneous, $spacing, $titles, $elements, $callback, $buttons) = @_;

    my $self = $class->SUPER::new($homogeneous, $spacing);

    # create the list
    my $list_widget = Gtk::CList->new_with_titles(@$titles);
    foreach (@$elements) {
	$list_widget->append(@$_);
    }
    $list_widget->set_selection_mode('single');
    $list_widget->signal_connect('select_row', sub {
	my( $list, $row, $col, $event, @data) = @_;
	if( $event->{'type'} eq '2button_press' ) {
	    my $orf_name =  $list->get_text( $row, 0 );
	    &$callback($orf_name);
	}
	return 1;
    });
    $self->pack_start_defaults($list_widget);

    # create the buttons
    my $buttonbox=Gtk::HButtonBox->new;
    foreach (@$buttons) {
	my $button = Gtk::Button->new($_->{name});
	$button->signal_connect('clicked', $_->{callback});
	$buttonbox->add($button);
    }
    $self->pack_end_defaults($buttonbox);
    $self->show_all;
    return $self;
}
