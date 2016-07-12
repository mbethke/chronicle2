

=head1 NAME

Chronicle::Plugin::FTS - Set up a full text search table in the database

=head1 DESCRIPTION

For online site search, grepping through static HTML files is not a viable
approach. Fortunately, we have a database of our content already and SQLite is
capable of full text search, so a CGI script that runs the necessary queries
and displays links to relevant content is trivial if we copy the database to
the web server, too.

This plugin sets up the necessary tables. Technically that's quite some
suplicated content because SQLite requires a separate table for full text
search, so it would be possible to use a separate database and only copy that
to the web server.

=cut

=head1 METHODS

=cut

package Chronicle::Plugin::FTS;

use strict;
use warnings;

our $VERSION = "0.0.1";


=head2 on_db_create

Here we set up the necessary tables.

=cut

sub on_db_create
{
    my ( $self, %args ) = (@_);

    $args{ dbh }->do("CREATE VIRTUAL TABLE search USING FTS4(title, body, link)");
}



sub on_insert {
    my $data = $args{ data };

    $args{ dbh }->do("INSERT INTO search VALUES(?,?,?)", {},
        $data->{ title },
        $data->{ body },
        $data->{ link },
      ) or
      die "Failed to insert into search table";
}

1;


=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the terms of either:

a) the GNU General Public License as published by the Free Software
Foundation; either version 2, or (at your option) any later version,
or

b) the Perl "Artistic License".

=cut

=head1 AUTHOR

Matthias Bethke <matthias@towiski.de>

=cut
