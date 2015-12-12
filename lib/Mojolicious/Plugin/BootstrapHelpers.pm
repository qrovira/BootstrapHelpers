package Mojolicious::Plugin::BootstrapHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::ByteStream qw/ b /;
use Mojo::Util 'xml_escape';

use List::Util qw/ min /;

use utf8;
our $VERSION = '0.02';

sub register {
    my ($self, $app, $opts) = @_;

    # Loader helpers
    $app->helper( bs_include => \&_cdn_include );

    # Nav bars
    $app->helper( bs_nav => \&_nav );
    $app->helper( bs_nav_item => \&_nav_item );

    # Forms
    $app->helper( bs_form_group => \&_form_group );
    $app->helper( bs_submit => \&_submit );
    $app->helper( bs_button => \&_button );

    foreach my $type ( qw/ url text email date datetime file month number password range search tel time week color / ) {
        $app->helper( "bs_${type}_control" => sub {  _control( shift, $type, @_ ); } )
    }

    # Pager
    $app->helper( bs_pager => \&_pager );

    # Flash message helpers
    $app->helper( bs_alert => \&_alert );
    $app->helper( bs_flash => \&_bs_flash );
    $app->helper( bs_notify => \&_bs_notify );
    $app->helper( bs_flash_to => \&_bs_flash_to );
    $app->helper( bs_all_flashes => \&_bs_all_flashes );
}

sub _cdn_include {
    my $self = shift;
    my %args = @_;
    my $out = '';
    my $version = $args{version} // '3.3.6';
    my $jquery_version = $args{jquery_version} // '2.1.0';
    my $awesome_version = $args{awesome_version} // '4.0.3';

    $out .= $self->stylesheet("//netdna.bootstrapcdn.com/bootstrap/$version/css/bootstrap.min.css")
        if $args{stylesheet} || $args{all};

    $out .= $self->stylesheet("//netdna.bootstrapcdn.com/font-awesome/$awesome_version/css/font-awesome.min.css")
        if $args{awesome} || $args{all};
        
    $out .= $self->javascript("//ajax.googleapis.com/ajax/libs/jquery/$jquery_version/jquery.min.js")
        if $args{jquery} || $args{all};

    $out .= $self->javascript("//netdna.bootstrapcdn.com/bootstrap/$version/js/bootstrap.min.js")
        if $args{javascript} || $args{all};

    return Mojo::ByteStream->new($out);
}


sub _nav_item {
    my $self = shift;
    my $label = shift;
    my $target = pop;
    my %attrs = @_;

    return $self->tag( li => ( class => "divider", role => "separator" ) )
        if $label eq '-';

    # Dropdown
    if( ref $target eq 'CODE' ) {
        $attrs{class} = $attrs{class} ? "$attrs{class} dropdown" : "dropdown";
        return $self->tag(
            li => %attrs,
            sub {
                $self->tag( 'a' => (
                    href            => '#',
                    class           => "dropdown-toggle",
                    "data-toggle"   => "dropdown",
                    role            => "button",
                    "aria-haspopup" => "true",
                    "aria-expanded" => "false",
                ), sub {
                    $label." ".$self->tag('span' => ( class => "caret" ) ).
                    $self->tag( 'ul' => ( class => "dropdown-menu" ) => $target )
                } );
            }
        );
    }
    else {
        my $found = $self->app->routes->lookup( $target );
        if( $found && $self->match->endpoint == $found ) {
            $attrs{class} = $attrs{class} ? "$attrs{class} active" : "active";
        }

        return $self->tag(
            li => %attrs,
            sub { $self->link_to( $label => $target ) }
        );
    }
}

sub _nav {
    my $self = shift;
    my $class = ref($_[0]) ? "nav navbar-nav" : shift;
    my $ret = shift;
    my %args = @_;

    if( $class ) {
        $args{class} = $args{class} ? "$args{class} $class" : $class;
    }

    if( ref $ret eq 'ARRAY' ) {
        my $items = $ret;
        $ret = join '', map { $self->bs_nav_item( @$_ ) } @$items;
    } elsif( ref $ret eq "CODE" ) {
        $ret = $ret->();
    }

    return $self->tag( ul => %args => sub { $ret } );
}


#
# Forms
#

sub _form_group {
    my ($self, $control, %attrs) = @_;
    my ($cname, $ctype, @cargs) = ref($control) eq 'ARRAY' ? @$control : ($control, "text");

    $attrs{class} = $attrs{class} ? "$attrs{class} form-group" : 'form-group';

    if ($self->validation->has_error($cname)) {
        $attrs{class} .= ' has-error';
    }

    my $content = '';
    if( my $label = delete $attrs{label} ) {
        $content .= $self->label_for(
            $cname => ( class => 'control-label' ) => sub { $label }
        );
    }

    $content .= _control(
        $self, $ctype, $cname, @cargs,
        ( $attrs{help} ? ( 'aria-describedby' => "$cname-aria-desc" ) : () )
    );

    if( my $help = delete $attrs{help} ) {
        $content .= $self->tag(
            span => ( class => "help-block", id => "$cname-aria-desc" ) => sub { $help }
        );
    }

    return $self->tag( "div", %attrs, sub { $content } );
}

sub _control {
    my ($self, $type, $name) = (shift, shift, shift);
    my $value = @_ % 1 ? shift : undef;
    my %attrs = @_;

    $attrs{class} = $attrs{class} ? "$attrs{class} form-control" : 'form-control';

    my $helper = $type."_field";
    return $self->$helper( $name, $value // (), %attrs);
}

sub _button {
    my $self = shift;
    my $label = @_ % 2 ? shift : undef;
    my %attrs = @_;

    $attrs{class} = $attrs{class} ? "$attrs{class} btn" : 'btn';
    $attrs{class} .= " btn-default"
        unless $attrs{class} =~ m#btn-(primary|default|info|warning|danger|link)#;

    return $self->tag( "button", %attrs, $label ? sub { $label } : () );
}

sub _submit {
    my $self = shift;
    my $label = @_ % 2 ? shift : undef;
    my %attrs = @_;

    $attrs{class} = $attrs{class} ? "$attrs{class} btn-primary" : 'btn-primary'
        unless $attrs{class} && $attrs{class} =~ m#btn-(primary|default|info|warning|danger|link)#;

    return $self->bs_button( $label // (), %attrs );
}


#
# Pager
#

sub _pager_link {
    my ($self, $i, $current) = @_;
    return $self->tag( li => ( $i == $current ? ( class => "active" ) : () ) => sub {
        $self->link_to( $i => $self->url_with->query( page => $i ) )
    } );
}

sub _pager_ellipsis {
    my ($self) = @_;
    return $self->tag( li => ( class => "disabled" ) => sub {
        $self->tag( a => ( href => '#' ) => '…' )
    } );
}

sub _pagination {
    my ($first, $active, $last, $max) = @_;
    my $side = int(($max - 2) / 3);
    my $center = $max - 2 - 2 * $side;
    my @ret;
    my $i = $first;
    my $d = int($side + $center/1 + 0.5);

    warn "For: $first,$active,$last,$max..($side,$center,$d)\n";

    while( $i <= $last ) {
        push @ret, $i++;

        next if $max >= $last;

        if( $active >= $first + $d && $active <= $last - $d ) {
            if( $i == $first + $side && $first + $side != $active - int( $center/2 ) - 1 ) {
                $i = $active - int( $center/2 );
            }
            elsif( $i == $active + int( $center/2 + 0.5 ) && $last - $side != $active + int( $center/2 + 0.5 ) ) {
                $i = $last - $side + 1;
            }
        }
        elsif( $active < $first + $d && $i == $first + $side + $center + 1) {
            $i = $last - $side + 1;
        }
        elsif( $active > $last - $d && $i == $first + $side ) {
            $i = $last - $side - $center;
        }
    }

    warn "Returned @{[ join ',', @ret ]}\n";

    return @ret;
}

sub _pager {
    my ($self, $pager, %attrs) = @_;
    my $next_prev = delete $attrs{next_prev} // 1;
    my $num_pages = min( delete $attrs{pager_items} // $pager->last_page, $pager->last_page );

    return $self->tag( 'nav' => %attrs => sub {
        $self->tag( 'ul' => ( class => "pagination" ) => sub {
            my $i = 0;
            my $ret = join "\n", map {
                my $ellip = $i + 1 != $_; $i = $_;
                ($ellip ? _pager_ellipsis( $self ) : ()), _pager_link( $self, $_, $pager->current_page )
            } _pagination( $pager->first_page, $pager->current_page, $pager->last_page, $num_pages);

            if( $next_prev ) {
                $ret =
                    $self->tag( li => ( $pager->current_page == $pager->first_page ? ( class => "disabled" ) : () ) => sub {
                        $self->link_to(
                            $self->url_for->query( page => $pager->previous_page // $pager->current_page ) =>
                            ( 'aria-label' => 'Previous' ) =>
                            sub { $self->tag( span => ( 'aria-hidden' => 'true' ) => b('«') ) }
                        )
                    } )
                    . $ret .
                    $self->tag( li => ( $pager->current_page == $pager->last_page ? ( class => "disabled" ) : () ) => sub {
                        $self->link_to(
                            $self->url_for->query( page => $pager->next_page // $pager->current_page ) =>
                            ( 'aria-label' => 'Next' ) =>
                            sub { $self->tag( span => ( 'aria-hidden' => 'true' ) => b('»') ) }
                        )
                    } );
            }

            return $ret;
        } )
    } );
}

#
# Flash and notification helpers
#

sub _alert {
    my ($self, $class) = (shift, shift);
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    my $content = @_ % 2 ? pop : undef;
    my $ct = $cb ? $cb->() : $content ? xml_escape($content) : undef;
    my %attrs = @_;

    if ($attrs{dismissable}) {
        $ct //= '';
        $ct = $self->tag( 'button', type => "button", class => "close", "data-dismiss" => "alert", "aria-hidden" => "true", '×' ).$ct;
        delete $attrs{dismissable};
    }

    $attrs{class} .= $attrs{class} ? " alert alert-$class" : "alert alert-$class";

    return $self->tag( "div", %attrs, defined($ct) ? sub { $ct } : () );
}

sub _bs_flash {
    my ($self, $class, $message) = @_;
    # Ugly hack accessing new_flash directly, to avoid a fetch/reset cycle
    my $current = $self->session->{new_flash}{bs_flashes} //= [];

    push @$current, [ $class => $message ];

    $self->flash( bs_flashes => $current );
}

sub _bs_notify {
    my ($self, $class, $message) = @_;
    my $current = $self->stash('bs_notifications') // [];

    push @$current, [ $class => $message ];

    $self->stash( bs_notifications => $current );
}

sub _bs_flash_to {
    my ($self, $class, $message, @redirect) = @_;

    $self->bs_flash( $class, $message );

    $self->redirect_to( @redirect );
}

sub _bs_all_flashes {
    my ($self, $class, $message, @redirect) = @_;
    my $flashes = $self->flash('bs_flashes') // [];
    my $notifications = $self->stash('bs_notifications') // [];
    my $content = '';

    foreach my $f (@$flashes, @$notifications) {
        $content .= $self->bs_alert( $f->[0], dismissable => 1, $f->[1] );
    }

    return Mojo::ByteStream->new($content);
}


1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::BootstrapHelpers - Helpers to work with Twitter Bootstrap
templates from Mojolicious

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('BootstrapHelpers');

  # Mojolicious::Lite
  plugin 'BootstrapHelpers';

=head1 DESCRIPTION

L<Mojolicious::Plugin::BootstrapHelpers> is a collection of Twitter Bootstrap
helpers for L<Mojolicious>.

=head1 HELPERS

=head2 bs_include

  %= bs_include all => 1
  %= bs_include stylesheet => 1
  %= bs_include jquery => 1
  %= bs_include javascript => 1
  %= bs_include awesome => 1

Include bootstrap or any of the required components using CDN links. Use I<all>
to load all at once.

You can also provide I<version>, I<jquery_version> or I<awesome_version> options
to specify which bootstrap, jquery or font awesome versions to link to,
respectively.

=head2 bs_form_group

  %= bs_form_group 'email' => begin
  %= email_field 'email'
  % end

  %= bs_form_group 'email' => ( label => "e-Mail address" ) => begin
  %= text_field 'email'
  % end

Generate the form-group wrapper for a given field. It will automatically check
the specified param name on the validation for errors and add the "has-error"
classes as needed.

You can also provide a "label" attribute to autogenerate it.

  <div class="form-group">
    <input name="email"type="email" />
  </div>

  <div class="form-group">
    <label for="email" class="control-label">e-Mail address</label>
    <input name="email"type="email" />
  </div>

=head2 bs_alert

  %= bs_alert success => "Operation completed"
  %= bs_alert danger => ( dismissable => 1 ) => begin
    <span>Something went terribly wrong</span>
  % end

Generates a div wrapper with the alert and alert-$class classes.

  <div class="alert alert-success">Operation completed</siv>
  <div class="alert alert-danger">
    <button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button>
    <span>Something went terribly wrong</span>
  </div>

=head2 bs_nav

  <%= bs_nav( "nav nav-pills" => [ [Home => '/'], ['-'], [Other => '/other'] ] ) %>
  <%= bs_nav( [ [Home => '/'], ['-'], [Other => '/other'] ] ) %>
  <%= bs_nav( [ [Home => '/'], ['-'], [Other => '/other'] ], data-smurf => "something" ) %>

  # Or also:
  %= bs_nav "nav nav-pills" => begin
  %= bs_nav_item 'Home' => '/';
  %= bs_nav_item 'Admin' => '/admin';
  % end

Generate a list of link items as a list. Link items are created by calling
L</bs_nav_item> on each of the passed links.

Classes for the list can be provided as a first scalar argument to this helper.

  <ul>
    <li class="active"><a href="/">Home</a></li>
    <li class="separator"></li>
    <li class="custom"><a href="/other">Other</a></li>
  </ul>

=head2 bs_nav_item

  <%= bs_nav_item 'Home' => '/' %>
  <%= bs_nav_item '-' %>
  <%= bs_nav_item 'Other' => ( class => "custom" ) => '/other' %>

Generate a list item with a link, for use inside components. The link will
already have the "active" class set for the current route. Aditional %args
are provided to both the list and link tags.

  <li class="active"><a href="/">Home</a></li>
  <li class="separator"></li>
  <li class="custom"><a href="/other">Other</a></li>

=head1 FLASH AND NOTIFICATION HELPERS

=head2 bs_flash

  $self->bs_flash( warning => "Beware of the dog" );
  $self->bs_flash( danger => "The dog is attqacking you!" );
  $self->bs_flash( success => "The dog killed you!" );

A stacking flash notification helper, similar to the regular flash. It can be
called multiple times, to stack different messages.

=head2 bs_notify

  $self->bs_notify( warning => "Beware of the dog" );
  $self->bs_notify( danger => "The dog is attqacking you!" );
  $self->bs_notify( success => "The dog killed you!" );

Queues notifications for the user using the stash instead of the session.

=head2 bs_flash_to

  $self->bs_flash( warning => "Beware of the dog", '/to/some/action' );

Stacks a flash notification and calls redirect_to(...) with any additional
arguments passed to this helper.

=head2 bs_all_flashes

  <%= b_all_flashes %>

This method will call the bs_alert helper with each notification found,
both on the flashed notifications or the stash ones.

=head1 Basic layout templates

=head2 layouts/bootstrap.html.ep

Base bootstrap template

=head1 METHODS

L<Mojolicious::Plugin::BootstrapHelpers> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut

1;

__DATA__

@@ layouts/bootstrap.html.ep
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><%= $title %></title>

    <%= bs_include stylesheet => 1 %>
    <%= bs_include awesome => 1 %>

    <!-- HTML5 Shim and Respond.js IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>
      <script src="https://oss.maxcdn.com/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>
  <body>
    <div class="container">
      <%= content %>
    </div>

    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <%= bs_include jquery => 1 %>
    <%= bs_include javascript => 1 %>
  </body>
</html>
