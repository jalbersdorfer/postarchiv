#!/usr/bin/env perl
use Dancer2;
use DBI;
use File::Path qw(make_path);
use File::Copy;
use POSIX qw(strftime);
use Time::Local qw(timegm);
use JSON::PP qw(encode_json);

my $version = "1.0.0";

# my $dsn = "DBI:mysql:database=$database;host=localhost;port=9306";
# my $dbh = DBI->connect($dsn, $user, $password);
 
get '/' => sub {
    my $limit = $ENV{'OVERVIEW_LIMIT'} || "18";
    my $order = $ENV{'OVERVIEW_ORDER'} || "DESC";
    my $dbh = DBI->connect("dbi:mysql:database=;host=$ENV{'SPHINX_HOST'};port=$ENV{'SPHINX_PORT'}", "", "", {mysql_no_autocommit_cmd => 1}) or return error "Cannot connect to Sphinx: $DBI::errstr";

    my %query_parameters = params('query');
    if (query_parameters->get('search'))
    {
    # return query_parameters->get('q');
	my $sth = $dbh->prepare(
	    "SELECT * FROM testrt WHERE MATCH(?) ORDER BY id $order LIMIT $limit;")
        or die "prepare statement failed: $dbh->errstr()";
    $sth->execute(query_parameters->get('search')) or die "execution failed: $dbh->errstr()";
    
    template 'index.tt', { search => query_parameters->get('search'), cnt => $sth->rows, docs => $sth->fetchall_arrayref({}), version => $version };
    } else {
	my $sth = $dbh->prepare(
	    "SELECT * FROM testrt ORDER BY id $order LIMIT $limit;")
        or die "prepare statement failed: $dbh->errstr()";
    $sth->execute() or die "execution failed: $dbh->errstr()";
    
# template 'index.tt', { };
        template 'index.tt', { search => "Last $limit", cnt => $sth->rows, docs => $sth->fetchall_arrayref({}), version => $version };
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
    my $dbh = DBI->connect("dbi:mysql:database=;host=$ENV{'SPHINX_HOST'};port=$ENV{'SPHINX_PORT'}", "", "", {mysql_no_autocommit_cmd => 1}) or return error "Cannot connect to Sphinx: $DBI::errstr";
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
    my $home = $ENV{'ELDOAR_HOME'} || '/app';
    move("$home/$dbpath", "$home/$dbpath.deleted");
    move("$home/$dbpath.jpg", "$home/$dbpath.jpg.deleted");
    move("$home/$dbpath.txt", "$home/$dbpath.txt.deleted");
};

# Upload a File via CURL
# $ curl -F 'foo=@path/to/local/file' http://foo.bar/upload
# Upload multiple Files via CURL
# $ curl -F 'foo=@path/to/file' -F 'bar=@/path/to/file2' foo.bar/upload
# Upload an Array of Files (is not yet supported)
# $ curl -F 'foo[]=@path/to/file' -F 'foo[]=@path/to/file2' foo.bar/upload 
post '/upload' => sub {
    debug '/upload';
    my $dbh = DBI->connect("dbi:mysql:database=;host=$ENV{'SPHINX_HOST'};port=$ENV{'SPHINX_PORT'}", "", "", {mysql_no_autocommit_cmd => 1}) or return error "Cannot connect to Sphinx: $DBI::errstr";
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

# Admin dashboard
get '/admin' => sub {
    my $dbh = DBI->connect(
        "dbi:mysql:database=;host=$ENV{'SPHINX_HOST'};port=$ENV{'SPHINX_PORT'}",
        "", "",
        {mysql_no_autocommit_cmd => 1}
    ) or die "Cannot connect to Sphinx: $DBI::errstr";

    my $sth = $dbh->prepare("SELECT COUNT(*) as count FROM testrt");
    $sth->execute();
    my $row = $sth->fetchrow_hashref();

    template 'admin.tt', {
        doc_count => $row->{count} || 0
    };
};

# Reindex trigger
post '/admin/reindex' => sub {
    my $home = $ENV{'ELDOAR_HOME'} || '/app';
    debug 'Starting reindex...';

    # Execute reindex script
    my $output = `cd $home && perl reindex.pl 2>&1`;
    debug "Reindex output: $output";

    # Redirect back to admin page
    redirect uri_for('/admin');
};

put '/file/:id' => sub {
    my $old_id   = int(route_parameters->get('id'));
    my $new_date = body_parameters->get('date');
    return status(400) unless $new_date && $new_date =~ /^(\d{4})-(\d{2})-(\d{2})$/;
    my ($y, $m, $d) = ($1, $2, $3);

    my $dbh = DBI->connect(
        "dbi:mysql:database=;host=$ENV{'SPHINX_HOST'};port=$ENV{'SPHINX_PORT'}",
        "", "", {mysql_no_autocommit_cmd => 1}
    ) or return error "Cannot connect to Sphinx: $DBI::errstr";

    my $row = $dbh->selectrow_hashref("SELECT * FROM testrt WHERE id = $old_id");
    return status(404) unless $row;

    # Write ELDOAR-DATE header to .txt file so reindex preserves this correction
    my $home    = $ENV{'ELDOAR_HOME'} || '/app';
    my $txtpath = "$home/$row->{title}.txt";
    if (-f $txtpath) {
        my $txt = '';
        {
            local $/;
            open my $fh, '<', $txtpath or die "Cannot read $txtpath: $!";
            $txt = <$fh>;
            close $fh;
        }
        $txt =~ s/^ELDOAR-DATE:.*\n//;
        $txt = "ELDOAR-DATE: $new_date\n$txt";
        open my $fh, '>', $txtpath or die "Cannot write $txtpath: $!";
        print $fh $txt;
        close $fh;
    }

    # Find a free ID in the new date range
    my $base = date_to_base_id($y, $m, $d);
    my $existing = $dbh->selectall_arrayref(
        "SELECT id FROM testrt WHERE id >= $base AND id < " . ($base + 86_400_000)
    );
    my %taken = map { $_->[0] => 1 } @$existing;
    my $new_id = $base;
    $new_id++ while $taken{$new_id};

    my $content = $row->{content} // '';
    $content =~ s/^ELDOAR-DATE:.*\n//;

    $dbh->do("DELETE FROM testrt WHERE id = $old_id");
    my $sth = $dbh->prepare('INSERT INTO testrt (id, gid, title, content) VALUES (?,?,?,?)');
    $sth->execute($new_id, $new_id, $row->{title}, $content);

    content_type 'application/json';
    return encode_json({ new_id => "$new_id" });
};

sub date_to_base_id {
    my ($year, $month, $day) = @_;
    return timegm(0, 0, 0, $day, $month - 1, $year - 1900) * 1000;
}

start;

