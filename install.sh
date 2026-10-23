#!/bin/sh
set -eu

PREFIX=${PREFIX:-/usr/local/lib/ftpkit-shlib}
SOURCE_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

case $PREFIX in
    /*) ;;
    *) printf '%s
' "PREFIX must be absolute" >&2; exit 2 ;;
esac

umask 022
mkdir -p "$PREFIX/lib"
for file in "$SOURCE_DIR"/ftpkit.sh "$SOURCE_DIR"/lib/*.sh; do
    case $file in
        */ftpkit.sh) cp "$file" "$PREFIX/ftpkit.sh" ;;
        *) cp "$file" "$PREFIX/lib/$(basename "$file")" ;;
    esac
done
chmod 0644 "$PREFIX/ftpkit.sh" "$PREFIX"/lib/*.sh
printf '%s
' "Installed ftpkit-shlib 1.0.0 to $PREFIX"
