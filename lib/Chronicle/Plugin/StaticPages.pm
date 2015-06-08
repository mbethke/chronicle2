

=head1 NAME

Chronicle::Plugin::StaticPages - Generate non-blog pages.

=head1 DESCRIPTION

If your blog-post contains a "C<page: 1>" header then it will
treat the post as a non-blog static page.

This contains all the methods to handle the storing and generating of
non-blog pages.

* on_db_create: creates a table within the blog database to store the pages.
* on_insert: inserts new and updated pages.
* on_generate: generates the page.
=cut

=head1 METHODS

Now follows documentation on the available methods.

=cut

package Chronicle::Plugin::StaticPages;


use strict;
use warnings;

=head1 doc

=head2 on_db_create

Create a table for the static-pages.

=cut

sub on_db_create
{
    my ( $self, %args ) = (@_);

    #
    #  Create the "pages" table
    #
    my $dbh = $args{ 'dbh' };

    $dbh->do(
        "CREATE TABLE pages (id INTEGER PRIMARY KEY, filename, title, content, template) "
    );
}


=head2 on_insert

Don't generate a blog/tag/archive entry if we have a "C<page: 1>" header,
instead insert the post into the static-page table.

=cut

sub on_insert
{
    my ( $self, %args ) = (@_);

    #
    #  The post data, DB-handle and config.
    #
    my $data   = $args{ 'data' };
    my $dbh    = $args{ 'dbh' };
    my $config = $args{ 'config' };
    #
    #  Is this a page?
    #
    my $page = $data->{ 'page' };
    if ($page)
    {
        $config->{ 'verbose' } &&
          print "Treating page as static $data->{'file'}\n";

        # if there has been no template supplied, then use the default
        $data->{ 'template' } = 'page.tmpl'
          unless defined $data->{ 'template' };

        # because of the blog template having a default value we need to
        # strip this and use the page default
        $data->{ 'template' } = 'page.tmpl'
          if $data->{ 'template' } eq 'entry.tmpl';

        #
        #  Insert into the static-pages
        #
        my $sql = $dbh->prepare(
            "INSERT INTO pages (title,filename,content,template) VALUES( ?, ?, ?, ? )"
          ) or
          die "Failed to prepare";

        $sql->execute( $data->{ 'title' },
                       $data->{ 'link' },
                       $data->{ 'body' },
                       $data->{ 'template' }
          ) or
          die "Failed to insert";
        $sql->finish();

        #
        #  Don't allow this to be treated as normal.
        #
        return undef;
    }

    # if its not a page carry on
    else
    {
        #
        #  Allow proceeding as normal
        #
        return ($data);
    }
}

=head2 on_generate

Generates the static page if a "C<page: 1>"
 header is present. The Page is processed
 then removed from futher processing, to avoid
 being treated as a blog post.

=cut

sub on_generate
{
    my ( $self, %args ) = (@_);

    #
    #  The post data, DB-handle and config.
    #
    my $dbh    = $args{ 'dbh' };
    my $config = $args{ 'config' };

    #
    #  Retrive all the page data for building
    #
    my $pages =
      $dbh->prepare("SELECT filename,title,content,template FROM pages") or
      die "Failed to find static-pages";
    $pages->execute() or die "Failed to execute query";


    my ( $filename, $content, $title, $template );
    $pages->bind_columns( undef, \$filename, \$title, \$content, \$template );

    #
    #   Fetach and build the files one by one
    #

    while ( my $page = $pages->fetch() )
    {

        $config->{ 'verbose' } &&
          print "Writing Title:$title -> $config->{'output'}/$filename\n";

        my $c = Chronicle::load_template($template);
        $c->param( top => $config->{ 'top' } );
        $c->param( { content => $content, title => $title } );

        open( my $handle, ">:encoding(UTF-8)",
              $config->{ 'output' } . "/" . $filename ) or
          die "Failed to open";
        print $handle $c->output();
        close($handle);
    }

    $pages->finish();
}

sub _order
{

    return 1001;

}

1;
