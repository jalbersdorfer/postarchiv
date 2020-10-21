#!/usr/bin/perl

my $filepath = "data/files/2020/07/scan_2020-07-27_090231.pdf";
my $cmd = "pdf2txt '$filepath'";
my $content = `$cmd`;
my $len = length $content;
printf $len;
if ($len <= 10)
{
    `ocrmypdf $filepath $filepath`;
    $content = `$cmd`;
    $len = length $content;
}

printf $len;
