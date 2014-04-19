package Mojolicious::Plugin::BootstrapHelpers;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::ByteStream;

our $VERSION = '0.01';

sub register {
  my ($self, $app) = @_;

  $app->helper( form_group => \&_form_group );
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

=head2 form_group

  %= form_group 'email' => begin
  %= email_field 'email'
  % end

  %= form_group 'email' => ( label => "e-Mail address" ) => begin
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
    <label for="email">e-Mail address</label>
    <input name="email"type="email" />
  </div>

=head1 METHODS

L<Mojolicious::Plugin::BootstrapHelpers> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
