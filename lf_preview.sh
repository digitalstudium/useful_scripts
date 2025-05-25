#!/usr/bin/env bash

MIME=$(mimetype --all --brief "$1")
#echo "$MIME"

case "$MIME" in
    # .pdf
    *application/pdf*)
        pdftotext "$1" -
        ;;
    # .jpeg, png etc.
    *image/*)
        chafa -f sixel -s "$2x$3" "$1" --polite on
        ;;
    # .7z
    *application/x-7z-compressed*)
        7z l "$1"
        ;;
    # .tar .tar.Z
    *application/x-tar*)
        tar -tvf "$1"
        ;;
    # .tar.*
    *application/x-compressed-tar*|*application/x-*-compressed-tar*)
        tar -tvf "$1"
        ;;
    # .rar
    *application/vnd.rar*)
        unrar l "$1"
        ;;
    # .zip
    *application/zip*)
        unzip -l "$1"
        ;;
    *text/markdown*)
        pandoc $1 > /tmp/lf_preview.html && cutycapt --url=file:///tmp/lf_preview.html --out=/tmp/lf_preview.png && chafa -s "$2x$3" -f sixel /tmp/lf_preview.png --polite on
	;;
    # any plain text file that doesn't have a specific handler
    *text/plain*)
        # return false to always repaint, in case terminal size changes
        batcat --force-colorization --paging=never --style=changes,numbers \
            --terminal-width $(($2 - 3)) "$1" && false
        ;;
    *)
        echo "unknown format"
        ;;
esac
