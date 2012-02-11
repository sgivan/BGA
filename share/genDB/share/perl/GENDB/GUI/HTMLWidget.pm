package HTMLWidget;

($GENDB::GUI::HTMLWidget::VERSION) = ('$Revision: 1.1.1.1 $ ' =~ /([\d\.]+)/g);

use GENDB::GENDB_CONFIG;
use LWP::UserAgent;
use URI;

use vars( qw(@ISA) );
@ISA = qw( Gtk::Window );

my $status;

if(defined $GENDB::GENDB_CONFIG::GENDB_GTKHTML) {
    require $GENDB::GENDB_CONFIG::GENDB_GTKHTML;
}

##############################
###                        ###
### Interface to Gtk::HTML ###
###                        ###
##############################

sub new {
    my( $class, $url ) = @_;
    my $window = $class->SUPER::new( 'toplevel' );
    $status = new Gtk::Statusbar;
    
    # setup LWP user agent + proxy usage
    $ua = new LWP::UserAgent();
    $ua->env_proxy; 

    my $home = 'http://localhost';
    $base = new URI($url || $home);
    @visited = ();
    
    Gtk::Widget->set_default_colormap(Gtk::Gdk::Rgb->get_cmap());
    Gtk::Widget->set_default_visual(Gtk::Gdk::Rgb->get_visual());
    $sw = new Gtk::ScrolledWindow(undef, undef);
    $sw->set_policy('automatic', 'automatic');
    $vb = new Gtk::VBox(0, 0);
    $hb = new Gtk::HBox(0, 0);
    $back = new Gtk::Button( 'Back' );
    $urlentry = new Gtk::Entry;
    $vb->pack_start($hb, 0, 0, 5);
    $hb->pack_start($back, 0, 0, 0);
    $hb->pack_start($urlentry, 1, 1, 5);
    $urlentry->signal_connect('activate', sub {
	&load($html, shift->get_text(), $html->begin)
	});
    $back->signal_connect( 'clicked', sub {
	pop @visited; 
	&load($html, pop(@visited), $html->begin)
	});

    $html = new Gtk::HTML;
    $html->signal_connect('title_changed', sub {$window->set_title($html->get_title())});
    $html->signal_connect('url_requested', \&load_url);
    $html->signal_connect('on_url', sub { $status->push( 0, $_[1] ) });
    $html->signal_connect('link_clicked', sub {
	&load($html, $_[1], $html->begin)
	});
    $vb->add($sw);
    $sw->add($html);
    $vb->pack_end( $status, 0, 0, 0 );
    $window->add($vb);
    $window->set_default_size(500, 400);
    
    &load($html, $base, $html->begin);
    return bless $window;
}

sub load {
    my ($html, $url, $handle) = @_;
    $base = URI->new_abs($url, $base);
    $urlentry->set_text($base);
    push @visited, $base;
    &load_url($html, $base, $handle);
}

sub load_url {
    my ($html, $url, $handle) = @_;
    my $req = new HTTP::Request('GET', new_abs URI($url, $base));
    my $data = $ua->request($req, sub {
	my ($d, $r, $p) = @_;
	Gtk->main_iteration while (Gtk->events_pending);
	if (defined ($d) && length($d)) {
	    $html->write($handle, $d);
	} else {
	    warn "No more data ($handle)?!?\n";
	}
    }, 4096);
    $html->end($handle, $data->is_success?'ok':'error');
}

1;

