#!/usr/bin/perl
package DB;
use strict;
use warnings;
use DBI;
use Try::Tiny;

sub new {
    my ($class, $dsn) = @_;
    return bless { dsn => $dsn }, $class;
}

sub query {
    my ($self, $qname, @query) = @_;
    defined $self->{dbh} or $self->_connect;
    my $sth = $self->{queries}{$qname};
    my $res = try {
        print "QUERY: @query\n";
         $sth->execute(@query);
         $sth->fetchall_arrayref({});
    } catch {
        undef $self->{dbh};
        die $_;
    };
    return @$res;
}

sub _connect {
    my ($self) = @_;
    my $dbh = $self->{dbh} = DBI->connect($self->{dsn}, "", "",
        { AutoCommit => 1, RaiseError => 1, sqlite_unicode => 1 }
    ) or die "Error connecting to database\n";
    $self->{queries} = {
        articles => $dbh->prepare(<<EOF),
SELECT * FROM search WHERE title MATCH ?
UNION
SELECT * FROM search WHERE body MATCH ?
EOF
    };
}

package main;
use Mojolicious::Lite;

my $DBNAME = "$ENV{BLOG_DB_DIR}/blog.db";
my $db = DB->new("dbi:SQLite:dbname=$DBNAME");

get '/' => sub {
    my $c = shift;
    my $query = $c->param('q') // return;
    $c->stash('results', [ $db->query('articles', $query, $query) ]);
    $c->render(template => 'default');
};

app->start;

__DATA__
@@ default.html.ep
<!doctype html>
<html lang="de">
  <head>
    <meta http-equiv="Content-type" content="text/html; charset=utf-8">
    <meta name="viewport" content="width=device-width">
    <title>Suchergebnisse</title>
    <link rel="shortcut icon" type="image/png" href="/favicon.png">
    <link rel="alternate" type="application/rss+xml" title="RSS" href="/index.rss">
    <link rel="stylesheet" href="/css/bootstrap.css">
    <link rel="stylesheet" href="/css/mezzanine.css">
    <link rel="stylesheet" href="/css/bootstrap-responsive.css">
    <link rel="stylesheet" href="/css/towiski.css">
    <script type="text/javascript" src="/js/jquery-1.12.3.min.js"></script>
    <script type="text/javascript" src="/js/bootstrap.js"></script>
    <script type="text/javascript" src="/js/bootstrap-extras.js"></script>
  </head>
  <body id="body">
    <div class="navbar navbar-fixed-top">
      <div class="navbar-inner">
        <div class="container">
          <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
            <span class="icon-bar"></span>
          </a>
          <a class="brand" href="/">blog.towiski.de</a>
          <div class="nav-collapse collapse">
            <form action="https://www.google.de/" class="navbar-search pull-right input-append">
              <input type="hidden" name="q" value="site:blog.towiski.de">
              <input class="search-query" placeholder="Suche" type="text" name="q" value="">
              <input type="submit" class="btn" value="Los!">
            </form>
            <ul class="nav pull-right">
              <li class="dropdown" id="dropdown-menu-home"><a href="/">Home</a></li>
              <li class="dropdown" id="dropdown-menu-tags"><a href="/tags/">Tags</a></li>
              <li class="dropdown" id="dropdown-menu-archive"><a href="/archive/">Archiv</a></li>
              <li class="divider-vertical"></li>
            </ul>
          </div>
        </div>
      </div>
    </div>
    <div class="container">
      <div class="row">
        <div class="span9 middle">
<% foreach my $r (@$results) {
my @paragraphs = $r->{body} =~ m!(<p>[[:alnum:]].*?</p>)!ms;
%>
<div id="searchresult">
<h1><a href="<%== $r->{link} %>"><%= $r->{title} %></a></h1>
<%== $paragraphs[0] // '' %>
</div>
<% } %>
        </div>
      </div>
    </div>
  </body>
</html>
