#!/usr/bin/env perl
use DBI;
use File::Basename;
use File::Path qw(make_path);
use POSIX qw(strftime);
 
my $dbh = DBI->connect("dbi:mysql:database=;host=127.0.0.1;port=9306", "", "",
	{mysql_no_autocommit_cmd => 1});
# Upload a File via CURL
# $ curl -F 'foo=@path/to/local/file' http://foo.bar/upload
# Upload multiple Files via CURL
# $ curl -F 'foo=@path/to/file' -F 'bar=@/path/to/file2' foo.bar/upload
# Upload an Array of Files (is not yet supported)
# $ curl -F 'foo[]=@path/to/file' -F 'foo[]=@path/to/file2' foo.bar/upload 
foreach $filepath(@ARGV) {
    my $txtfilepath = $filepath . '.txt';
    my $cmd = "pdf2txt '$filepath' | sed 's/\\x27/ /g' | tee '$txtfilepath'";
    printf $cmd;
    my $content = `$cmd`;
    my $sth = $dbh->prepare(
        'INSERT INTO testrt (id, gid, title, content) VALUES (?,?,?,?)'
    ) or die "prepare statement failed: $dbh->errstr()";
    my $pk = time() * 1000 + $i++;
    $filepath =~ m/data\/files.*$/;
    $sth->execute(
        $pk, $pk, $&, $content
    ) or die "execution failed: $dbh->errstr()";
    my $firstpagefp = $filepath . '[0]';
    my $jpgfilepath = $filepath . '.jpg';
    $cmd = "convert '$firstpagefp' '$jpgfilepath'";
    printf $cmd;
    my $output = `$cmd`;
};

