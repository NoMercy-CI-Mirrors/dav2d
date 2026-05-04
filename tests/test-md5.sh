#!/bin/bash

set -e

: ${OPTIONS:=--threads=1}

DAV2D="$1"
if [ ! -e "$DAV2D" ]; then
    echo $0 path/to/dav2d
    exit 1
fi

SRC_PATH="$(dirname "$0")/.."

for file in "$SRC_PATH"/media/*.obu; do
    base="$(basename "$file")"
    a_md5=$(cat "$file.md5")
    $WRAP "$DAV2D" -i "$file" -o tmp.md5 $OPTIONS --quiet --muxer=md5 --filmgrain=1
    d_md5=$(cat tmp.md5)
    rm -f tmp.md5
    if [[ "$a_md5" == "$d_md5" ]]; then
        echo $base "[OK] md5:$a_md5"
    else
        echo $base "[FAILED!]"
        diff <(echo "$a_md5") <(echo "$d_md5")
    fi
done
