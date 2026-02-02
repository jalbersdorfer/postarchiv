#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use File::Find;
use Time::Local;

# Database connection (same pattern as dancerApp.pl:14)
my $sphinx_host = $ENV{'SPHINX_HOST'} || '127.0.0.1';
my $sphinx_port = $ENV{'SPHINX_PORT'} || '9306';
my $dbh = DBI->connect(
    "dbi:mysql:database=;host=$sphinx_host;port=$sphinx_port",
    "", "",
    {mysql_no_autocommit_cmd => 1}
) or die "Cannot connect to Sphinx: $DBI::errstr\n";

# Step 1: Clear existing index
print "Clearing existing index...\n";
$dbh->do("DELETE FROM testrt WHERE id > 0");

# Step 2: Find all PDF files
my $home = $ENV{'ELDOAR_HOME'} || '/app';
my @pdf_files;
find(sub {
    push @pdf_files, $File::Find::name if /\.pdf$/ && ! /\.deleted$/;
}, "$home/data/files");

print "Found " . scalar(@pdf_files) . " PDF files\n";

# Step 3: Process each PDF
my $indexed = 0;
foreach my $pdf_path (@pdf_files) {
    # Extract date from filename
    my ($year, $month, $day) = extract_date($pdf_path);

    # Calculate base timestamp (milliseconds)
    my $base_ts = date_to_ms_timestamp($year, $month, $day);

    # Find free ID starting from base timestamp
    my $id = find_free_id($dbh, $base_ts);

    # Read text content from .pdf.txt
    my $txt_path = $pdf_path . '.txt';
    my $content = '';
    if (-e $txt_path) {
        if (open my $fh, '<', $txt_path) {
            $content = do { local $/; <$fh> };
            close $fh;
        } else {
            warn "Cannot read $txt_path: $!\n";
        }
    } else {
        warn "Missing text file: $txt_path\n";
    }

    # Extract relative path for title (match pattern in dancerApp.pl:115)
    my $title = $pdf_path;
    if ($pdf_path =~ m/(data\/files.*)$/) {
        $title = $1;
    }

    # Insert into Sphinx
    my $sth = $dbh->prepare(
        'INSERT INTO testrt (id, gid, title, content) VALUES (?,?,?,?)'
    );
    $sth->execute($id, $id, $title, $content);

    $indexed++;
    if ($indexed % 50 == 0) {
        print "Progress: $indexed documents indexed...\n";
    }
}

print "\nReindex complete: $indexed documents indexed\n";

$dbh->disconnect();

# Helper functions
sub extract_date {
    my ($path) = @_;
    # Try to extract YYYY-MM-DD from filename
    if ($path =~ /(\d{4})-(\d{2})-(\d{2})/) {
        return ($1, $2, $3);
    }
    # Fallback: use directory YYYY/MM and day 1
    if ($path =~ m|/(\d{4})/(\d{2})/|) {
        return ($1, $2, '01');
    }
    # Ultimate fallback: current date
    my @now = localtime();
    return ($now[5]+1900, sprintf("%02d", $now[4]+1), sprintf("%02d", $now[3]));
}

sub date_to_ms_timestamp {
    my ($year, $month, $day) = @_;
    # Convert to Unix timestamp (seconds) then multiply by 1000
    my $ts = timegm(0, 0, 0, $day, $month-1, $year-1900);
    return $ts * 1000;
}

sub find_free_id {
    my ($dbh, $base_ts) = @_;
    my $id = $base_ts;
    my $max_range = 86400000; # 1 day in milliseconds

    while ($id < $base_ts + $max_range) {
        my $sth = $dbh->prepare("SELECT id FROM testrt WHERE id = ?");
        $sth->execute($id);
        return $id unless $sth->fetchrow_array(); # ID is free
        $id++;
    }

    # If we exhaust the day range, continue anyway
    return $id;
}
