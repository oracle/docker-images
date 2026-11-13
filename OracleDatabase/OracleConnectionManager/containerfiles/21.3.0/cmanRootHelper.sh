#!/bin/bash
set -eu

case "${1:-}" in
    append-hosts)
        [ "$#" -eq 1 ] || exit 2
        cat >> /etc/hosts
        ;;
    replace-hosts)
        [ "$#" -eq 1 ] || exit 2
        cat > /etc/hosts
        ;;
    replace-resolv)
        [ "$#" -eq 3 ] || exit 2
        printf 'search %s\nnameserver %s\n' "$2" "$3" > /etc/resolv.conf
        ;;
    *)
        exit 2
        ;;
esac
