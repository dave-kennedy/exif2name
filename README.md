This script renames image files according to EXIF data.

The only dependency is the
[exif command line utility](https://github.com/libexif/exif), which is most
likely available from your package manager. On Ubuntu and derivatives, it's as
simple as:

```sh
$ sudo apt install exif
```

To rename all image files in a directory, run:

```sh
$ exif2name.sh [--dry-run | -n] [directory]
```

For each file in the specified directory (or the current directory if
unspecified), you will be prompted to select or enter the date. The file will
be renamed in the format `%Y-%m-%d_%H-%M-%S.jpg`.

