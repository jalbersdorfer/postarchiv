#!/usr/bin/env perl
use Dancer2;
use DBI;
use File::Path qw(make_path);
use File::Copy;
use POSIX qw(strftime);
 
# my $dsn = "DBI:mysql:database=$database;host=localhost;port=9306";
# my $dbh = DBI->connect($dsn, $user, $password);
 
get '/' => sub {
    my $limit = $ENV{'OVERVIEW_LIMIT'} || "18";
    my $order = $ENV{'OVERVIEW_ORDER'} || "DESC";
    my $dbh = DBI->connect("dbi:mysql:database=;host=$ENV{'SPHINX_HOST'};port=$ENV{'SPHINX_PORT'}", "", "",
	{mysql_no_autocommit_cmd => 1});

    my %query_parameters = params('query');
    if (query_parameters->get('search'))
    {
    # return query_parameters->get('q');
	my $sth = $dbh->prepare(
	    "SELECT * FROM testrt WHERE MATCH(?) ORDER BY id $order LIMIT $limit;")
        or die "prepare statement failed: $dbh->errstr()";
    $sth->execute(query_parameters->get('search')) or die "execution failed: $dbh->errstr()";
    
    template 'index.tt', { search => query_parameters->get('search'), cnt => $sth->rows, docs => $sth->fetchall_arrayref({}) };
    } else {
	my $sth = $dbh->prepare(
	    "SELECT * FROM testrt ORDER BY id $order LIMIT $limit;")
        or die "prepare statement failed: $dbh->errstr()";
    $sth->execute() or die "execution failed: $dbh->errstr()";
    
# template 'index.tt', { };
        template 'index.tt', { search => "Last $limit", cnt => $sth->rows, docs => $sth->fetchall_arrayref({}) };
    }
    # return $sth->rows . " Documents found.\n";
    # return 'Hello World!';
};

get '/file/**' => sub {
    # my $file = route_parameters->get('name');
    my ( $file ) = splat;
    my @foo = @{$file};
    my $filename = "" . join("/", @foo);
    debug $filename;
    
    # return send_file( $filename, system_path => 1, streaming => 0 );
    return send_file( $filename );

    # return 'You want to download :"' . $sfoo . '"';
};

del '/file/:id' => sub {
    debug 'delete /file/' . route_parameters->get('id');
    my $dbh = DBI->connect("dbi:mysql:database=;host=$ENV{'SPHINX_HOST'};port=$ENV{'SPHINX_PORT'}", "", "", {mysql_no_autocommit_cmd => 1});
    # $dbh->trace(5);
    # my $sth = $dbh->prepare('SELECT * FROM testrt WHERE id = ?;')
    #     or die "prepare statement failed: $dbh->errstr()";
    # my @params = (123);
    # $sth->execute(int(route_parameters->get('id'))) or die "execute failed: $dbh->errstr()";
    # $sth->execute(@params) or die "execute failed: $dbh->errstr()";
    # debug $sth->fetchall_arrayref({});
    my $id = int(route_parameters->get('id'));
    my $rv = $dbh->selectall_arrayref( "SELECT * FROM testrt WHERE id = $id" ) or die "execute failed: $dbh->errstr()";
    # -v-v-v- THE CODE below WORKS! -v-v-v- : It is commented to prevent unintended delete until a 2nd Questions is impmented"
    my $rows = $dbh->do("DELETE FROM testrt WHERE id = $id") or die "delete failed: $dbh->errstr()";
    debug "DELETED $rows Rows(s)";
    my @arv = @{$rv};
    debug @arv;
    my $dbid = $rv->[0]->[0];
    my $dbtim = $rv->[0]->[1];
    my $dbpath = $rv->[0]->[2];
    "Would have deleted File id: $dbid, timestamp: $dbtim, path: $dbpath";
    # Move the Files to a "Recycle Bin"
    move("$dbpath", "$dbpath.deleted");
    move("$dbpath.jpg", "$dbpath.jpg.deleted");
    move("$dbpath.txt", "$dbpath.txt.deleted");
};

# Upload a File via CURL
# $ curl -F 'foo=@path/to/local/file' http://foo.bar/upload
# Upload multiple Files via CURL
# $ curl -F 'foo=@path/to/file' -F 'bar=@/path/to/file2' foo.bar/upload
# Upload an Array of Files (is not yet supported)
# $ curl -F 'foo[]=@path/to/file' -F 'foo[]=@path/to/file2' foo.bar/upload 
post '/upload' => sub {
    debug '/upload';
    my $dbh = DBI->connect("dbi:mysql:database=;host=$ENV{'SPHINX_HOST'};port=$ENV{'SPHINX_PORT'}", "", "",
	{mysql_no_autocommit_cmd => 1});
    my $i = 1;
    my $all_uploads = request->uploads;
    my $home = $ENV{'ELDOAR_HOME'} || '/app';
    my $path = strftime "data/files/%Y/%m/", localtime;
    make_path("$home/" . $path, {verbose => 1});
    foreach (values %{$all_uploads}) {
        my $filepath = "$home/" . $path . $_->filename;
        debug 'Save upload to ' . $filepath;
        $_->copy_to($filepath);

        my $txtfilepath = $filepath . '.txt';
        my $cmd = "pdf2txt '$filepath' | sed 's/\\x27/ /g' | tee '$txtfilepath'";
        debug $cmd;
        my $content = `$cmd`;
	my $contentlen = length $content;
	if ($contentlen < 10)
	{
            `ocrmypdf -l deu -dc $filepath $filepath`;
	    $content = `$cmd`;
	}
        my $sth = $dbh->prepare(
	    'INSERT INTO testrt (id, gid, title, content) VALUES (?,?,?,?)'
        ) or die "prepare statement failed: $dbh->errstr()";
        my $pk = time() * 1000 + $i++;
        $sth->execute(
            $pk, $pk, $path . $_->filename, $content
        ) or die "execution failed: $dbh->errstr()";
        my $firstpagefp = $filepath . '[0]';
        my $jpgfilepath = $filepath . '.jpg';
        $cmd = "convert -background white -alpha remove -alpha off '$firstpagefp' '$jpgfilepath'";
        debug $cmd;
        my $output = `$cmd`;
    };
    # redirect to index
    redirect uri_for('/');
};

get '/upload' => sub {
    template 'upload.tt'
};
 
start;

