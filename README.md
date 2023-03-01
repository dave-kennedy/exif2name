This script renames JPG files according to EXIF data. It can be run like so:

```sh
$ exif2name.sh [--dry-run | -n] [directory]
```

For each file in the specified directory (or the current directory if
unspecified), you will be prompted to select one of the following options:

1. EXIF date and time (original): the contents of the `DateTimeOriginal` tag
1. EXIF date and time: the contents of the `DateTime` tag
1. File created: the result of `stat -c %w`
1. File last modified: the result of `stat -c %y`

Option 1 is usually correct for files created by a digital camera.

If none of the options are satisfactory, you can skip the file or enter the date
and time manually. As long as it isn't skipped, it will be renamed in the format
`%Y-%m-%d_%H-%M-%S.jpg`, followed by a number if another file has the same name.

The only dependency is the
[exif command line utility](https://github.com/libexif/exif), which is most
likely available from your package manager. On Ubuntu and derivatives, it's as
simple as:

```sh
$ sudo apt install exif
```

