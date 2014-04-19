package Mojolicious::Plugin::BootstrapHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::ByteStream;
use Mojo::Util 'xml_escape';

our $VERSION = '0.01';

sub register {
  my ($self, $app) = @_;

  # Tag generators
  $app->helper( bs_form_group => \&_form_group );
  $app->helper( bs_alert => \&_alert );

  # Flash message helpers
  $app->helper( bs_flash => \&_bs_flash );
  $app->helper( bs_notify => \&_bs_notify );
  $app->helper( bs_flash_to => \&_bs_flash_to );
  $app->helper( bs_all_flashes => \&_bs_all_flashes );
}


sub _form_group {
    my ($self, $name) = (shift, shift);

    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

    my $content = @_ % 2 ? pop : undef;

    my %attrs = @_;

    $attrs{class} .= $attrs{class} ? ' form-group' : 'form-group';

    if ($self->validation->has_error($name)) {
        $attrs{class} .= ' has-error';
    }

    my $ct = $cb ? $cb->() : $content ? xml_escape($content) : undef;

    if ($attrs{label}) {
        $ct //= '';
        $ct = $self->label_for( $name => ( class => 'control-label' ) => sub { $attrs{label} } ) . $ct;
        delete $attrs{label};
    }

    return $self->tag( "div", %attrs, defined($ct) ? sub { $ct } : () );
}

sub _alert {
    my ($self, $class) = (shift, shift);

    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

    my $content = @_ % 2 ? pop : undef;

    my $ct = $cb ? $cb->() : $content ? xml_escape($content) : undef;

    my %attrs = @_;

    if ($attrs{dismissable}) {
        $ct //= '';
        $ct = $self->button( class => "close", "data-dismiss" => "alert", "aria-hidden" => "true", '&times;' );
        $ct .= $ct;
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
        $content .= $self->bs_alert( @$f );
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

=head1 METHODS

L<Mojolicious::Plugin::BootstrapHelpers> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
