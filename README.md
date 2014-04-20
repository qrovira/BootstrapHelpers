# NAME

Mojolicious::Plugin::BootstrapHelpers - Helpers to work with Twitter Bootstrap
templates from Mojolicious

# SYNOPSIS

    # Mojolicious
    $self->plugin('BootstrapHelpers');

    # Mojolicious::Lite
    plugin 'BootstrapHelpers';

# DESCRIPTION

[Mojolicious::Plugin::BootstrapHelpers](https://metacpan.org/pod/Mojolicious::Plugin::BootstrapHelpers) is a collection of Twitter Bootstrap
helpers for [Mojolicious](https://metacpan.org/pod/Mojolicious).

# HELPERS

## bs\_include

    %= bs_include all => 1
    %= bs_include stylesheet => 1
    %= bs_include jquery => 1
    %= bs_include javascript => 1
    %= bs_include awesome => 1

Include bootstrap or any of the required components using CDN links. Use _all_
to load all at once.

You can also provide _version_, _jquery\_version_ or _awesome\_version_ options
to specify which bootstrap, jquery or font awesome versions to link to,
respectively.

## bs\_form\_group

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

## bs\_alert

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

## bs\_nav

    <%= bs_nav( "nav nav-pills" => [ [Home => '/'], ['-'], [Other => '/other'] ] ) %>
    <%= bs_nav( [ [Home => '/'], ['-'], [Other => '/other'] ] ) %>
    <%= bs_nav( [ [Home => '/'], ['-'], [Other => '/other'] ], data-smurf => "something" ) %>

    # Or also:
    %= bs_nav "nav nav-pills" => begin
    %= bs_nav_item 'Home' => '/';
    %= bs_nav_item 'Admin' => '/admin';
    % end

Generate a list of link items as a list. Link items are created by calling
["bs\_nav\_item"](#bs_nav_item) on each of the passed links.

Classes for the list can be provided as a first scalar argument to this helper.

    <ul>
      <li class="active"><a href="/">Home</a></li>
      <li class="separator"></li>
      <li class="custom"><a href="/other">Other</a></li>
    </ul>

## bs\_nav\_item

    <%= bs_nav_item 'Home' => '/' %>
    <%= bs_nav_item '-' %>
    <%= bs_nav_item 'Other' => ( class => "custom" ) => '/other' %>

Generate a list item with a link, for use inside components. The link will
already have the "active" class set for the current route. Aditional %args
are provided to both the list and link tags.

    <li class="active"><a href="/">Home</a></li>
    <li class="separator"></li>
    <li class="custom"><a href="/other">Other</a></li>

# FLASH AND NOTIFICATION HELPERS

## bs\_flash

    $self->bs_flash( warning => "Beware of the dog" );
    $self->bs_flash( danger => "The dog is attqacking you!" );
    $self->bs_flash( success => "The dog killed you!" );

A stacking flash notification helper, similar to the regular flash. It can be
called multiple times, to stack different messages.

## bs\_notify

    $self->bs_notify( warning => "Beware of the dog" );
    $self->bs_notify( danger => "The dog is attqacking you!" );
    $self->bs_notify( success => "The dog killed you!" );

Queues notifications for the user using the stash instead of the session.

## bs\_flash\_to

    $self->bs_flash( warning => "Beware of the dog", '/to/some/action' );

Stacks a flash notification and calls redirect\_to(...) with any additional
arguments passed to this helper.

## bs\_all\_flashes

    <%= b_all_flashes %>

This method will call the bs\_alert helper with each notification found,
both on the flashed notifications or the stash ones.

# Basic layout templates

## layouts/bootstrap.html.ep

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

# METHODS

[Mojolicious::Plugin::BootstrapHelpers](https://metacpan.org/pod/Mojolicious::Plugin::BootstrapHelpers) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [http://mojolicio.us](http://mojolicio.us).
