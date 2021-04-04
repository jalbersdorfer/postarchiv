# postarchiv
Searchable Archive for scanned Paper Mail

## Featuers / Ideas

Indexing:

- Extract Text from PDF via `pdf2txt`
- Save Text along with original pdf - separate path or just nameOfThe.pdf.txt
- Extract Image/Thumbnail of first Page via `convert` Utility
- Save Thumbnail along with original pdf - separate path or just nameOfThe.pdf.jpg
- Index full Path to the Pdf and Content with `sphinx`
- Index Title and Tags from the PDF File Meta Data (extracted using `exiftool`)
- Maybe Extract Date and Time from Filename in bulk indexer
- Store Date in the search index for later sorting
- POST API to add new Files to the Index
- PATCH API to update Title and Tags
- GET API to download/get the stored files by 'key'

Searching:

- Build a WebApp using Dancer Perl Web Framework
- Just like Google, just one single input field
- Display Thumbnails of Search Results
- maybe plus Text Excerpts
- maybe option to sort by document date (from filename)

Additional Information

- Option to edit Title and Tags of the PDF Files (PDF File Metadata - using exiftool)

# Components
Which Components are used

- Raspberry Pi 4
- [Sphinx Search Engine - v2.3.2-beta](http://sphinxsearch.com)
- [Dancer2 Perl Web Framework](http://perldancer.org/)
- [pdf2txt](https://linux.die.net/man/1/pdftotext)
- [convert](https://linux.die.net/man/1/convert)
- [exiftool](https://exiftool.org/) `sudo apt install libimage-exiftool-perl`

## Sphinx
Building/Compiling and installation

```bash
wget http://sphinxsearch.com/files/sphinx-2.3.2-beta.tar.gz
tar -xzf sphinx-2.3.2-beta.tar.gz
cd sphinx-2.3.2-beta
./configure
make
sudo make install
```

sphinx.conf - `/usr/local/etc/sphinx.conf`
```
#
# Minimal Sphinx configuration sample (clean, simple, functional)
#

index testrt
{
        type                    = rt
        rt_mem_limit            = 128M

        path                    = /var/data/testrt

        rt_field                = content
        rt_attr_uint            = gid
        rt_attr_string          = title

        expand_keywords         = 1
}



indexer
{
        mem_limit               = 128M
}


searchd
{
        listen                  = 9312
        listen                  = 9306:mysql41
        log                     = /var/log/searchd.log
        query_log               = /var/log/query.log
        read_timeout            = 5
        max_children            = 30
        pid_file                = /var/log/searchd.pid
        seamless_rotate         = 1
        preopen_indexes         = 1
        unlink_old              = 1
        workers                 = threads # for RT to work
        binlog_path             = /var/data
}
```

Start searchd
```bash
sudo searchd
```

Stop searchd
```bash
sudo searchd --stop
```

Search - via mysql
```bash
$sudo mysql -h 127.0.0.1 -P 9306
> SELECT * FROM testrt WHERE MATCH ('stadtwerke');
+------------+------------+-----------------------------------------------------------------------------------+
| id         | gid        | title                                                                             |
+------------+------------+-----------------------------------------------------------------------------------+
|         29 |         29 | /root/ocred/scan_2020-01-31_075034.pdf                                            |
| 1589537221 | 1589537221 | /media/myCloudDrive/ncdata/ncp/files/Documents/2020/01/scan_2020-01-31_075034.pdf |
| 1589537109 | 1589537109 | /media/myCloudDrive/ncdata/ncp/files/Documents/scan_2019-06-06_181038.pdf         |
| 1589537147 | 1589537147 | /media/myCloudDrive/ncdata/ncp/files/Documents/scan_2019-07-07_090424.pdf         |
+------------+------------+-----------------------------------------------------------------------------------+
4 rows in set (0.002 sec)
```

## Perl CPAN Modules

Install DBI

```bash
$ sudo apt-get install libdbd-mysql-perl
```

Install Dancer2

```bash
$ cpan Dancer2
```

## Exiftool

To Read and Modify **Title** and **Tags** of the PDF File

```bash
$ exiftool -Title="This is a really greate Title" -Keywords="This, Are, Some, Really, Greate, Tags" scan_2020-01-31_075034.pdf
    1 image files updated
pi@pi:~ $ exiftool -Title -Keywords scan_2020-01-31_075034.pdf
Title      : This is a really greate Title
Keywords   : This, Are, Some, Really, Greate, Tags
```

# Further reading

other Sites I found useful Information on.

- [Asela Fernando: Raspberry Pi Scanner Server with ArchLinuxArm](https://www.aselafernando.com/blog/2020/08/23)
