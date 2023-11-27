# postarchiv
Searchable Archive for scanned Paper Mail

## Configuration of the Docker Image

You can provide the following Environment Variables to configure the App.  

- `SPHINX_HOST`: Hostname of the Sphinx Server
- `OVERVIEW_LIMIT`: How much *last* items will be shown at StartPage. Default = 18
- `OVERVIEW_ORDER`: SortOrder of the StartPage. Either ASC or DESC. Default = DESC
- `ELDOAR_REMOVE_DELTED_AFTER_DAYS`: Days after when deleted Files will be really removed. Unconfigured means never.

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

# HowTo get your Scanner working

I use a Fujitsu fi-6140 Scanner connected to a RaspberryPi Zero (2 W) which runs Arch Linux ARM.  

This Scanner has a couple of Buttons on its body, which can be used with `scanbd` (Scanner Button Deamon).  

I installed the `scanbd` from the `AUR` Respository using `trizen`.

The scanner did not work in the first place on the `Raspberry Pi Zero 2 W` but had not a single issue on the `Raspberry Pi Zero`.  
This might be because the `Raspberry Pi Zero` runs `ArchLinux ARM 32`, while the `Raspberry Pi Zero 2-W` is powered by `ArchLinux ARM for armv7h`.

The issue on the `RaspberryPi Zero 2-W` was, that the USB Device was installed just for `root`.  
```shell
# lsusb
Bus 001 Device 004: ID 04c5:11f1 Fujitsu, Ltd 
Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub

# ls -lha /dev/bus/usb/001/
total 0
drwxr-xr-x  2 root root        80 Dec  2 19:47 .
drwxr-xr-x  3 root root        60 Jan  1  1970 ..
crw-rw-r--  1 root root    189, 0 Nov 29 13:51 001
crw-rw-r--+ 1 root root    189, 3 Dec  2 19:54 004
```

To fix this, I created a `/etc/udev/rules.d/40-scanner.rules` file with the following content:  
(the `idVendor` and `idProduct` Numbers are taken from the output of the `lsusb` command.)
```
SUBSYSTEMS=="usb", ATTRS{idVendor}=="04c5", ATTRS{idProduct}=="11f1", ENV{libsane_matched}="yes", GROUP="scanner"
```

then I unplugged and re-plugged the scanner and checked the device files again:

```shell
# ls -lha /dev/bus/usb/001/
total 0
drwxr-xr-x  2 root root        80 Dec  2 19:54 .
drwxr-xr-x  3 root root        60 Jan  1  1970 ..
crw-rw-r--  1 root root    189, 0 Nov 29 13:51 001
crw-rw----+ 1 root scanner 189, 4 Dec  2 19:54 005
```

Even without restarting the `scanbd` Service, the buttons worked immediatelly.  


# Further reading

other Sites I found useful Information on.

- [Asela Fernando: Raspberry Pi Scanner Server with ArchLinuxArm](https://www.aselafernando.com/blog/2020/08/23)
- [Sane Project](https://gitlab.com/sane-project)
- [Image Scanner Driver for LinuxUser's Guide](http://origin.pfultd.com/downloads/IMAGE/fi/ubuntu/210/ImageScannerDriver4Linux-UG_SP04.pdf)