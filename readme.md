This script renames image files according to exif data if available.
Otherwise, will use the last modified date.

To use this script, first install
[this](https://sourceforge.net/projects/libexif/files/exif/0.6.21/), then run:

```sh
$ exif2name.sh [--dry-run | -n] [directory]
```

If no directory is specified, it will use the current one.

