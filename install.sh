#!/bin/sh
set -eu
motion_expected='0fc466d0e1aa6ed5f46c4764acfd0427903222055b0a24c40c2fcd9cf69782ed'
motion_url='https://raw.githubusercontent.com/TiagoMagero/omori-terminal/main/Omori-Motion-Terminal.tar.gz'
motion_root=${XDG_DATA_HOME:-${HOME:?}/.local/share}/omori-motion-terminal
motion_archive=
while [ "$#" -gt 0 ]; do
    case "$1" in
        --archive) shift; motion_archive=${1:?Missing archive path} ;;
        --install-root) shift; motion_root=${1:?Missing installation path} ;;
        *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
    shift
done
if command -v cygpath >/dev/null 2>&1; then
    motion_root=$(cygpath -u "$motion_root")
    if [ -n "$motion_archive" ]; then motion_archive=$(cygpath -u "$motion_archive"); fi
fi
motion_version=$motion_root/packages/$(printf '%s' "$motion_expected" | cut -c1-16)
motion_package=$motion_version/motion-portable
if [ ! -f "$motion_package/motion" ]; then
    mkdir -p "$motion_root"
    if [ -z "$motion_archive" ]; then
        motion_archive=$motion_root/banner-$(date '+%Y%m%d%H%M%S')-$$.tar.gz
        printf '%s\n' 'Downloading the Omori Motion banner...'
        if command -v curl >/dev/null 2>&1; then
            curl -fLsS --proto '=https' --tlsv1.2 "$motion_url" -o "$motion_archive"
        elif command -v wget >/dev/null 2>&1; then
            wget --https-only -q "$motion_url" -O "$motion_archive"
        else
            printf '%s\n' 'curl or wget is required to download the banner.' >&2
            exit 1
        fi
    fi
    if command -v sha256sum >/dev/null 2>&1; then
        motion_actual=$(sha256sum < "$motion_archive" | awk '{print $1}')
    elif command -v shasum >/dev/null 2>&1; then
        motion_actual=$(shasum -a 256 < "$motion_archive" | awk '{print $1}')
    else
        printf '%s\n' 'A SHA-256 checker is required.' >&2
        exit 1
    fi
    if [ "$motion_actual" != "$motion_expected" ]; then
        printf '%s\n' 'SHA-256 mismatch; installation stopped.' >&2
        exit 1
    fi
    if [ -e "$motion_version" ]; then
        printf '%s\n' 'Incomplete version folder already exists; files preserved.' >&2
        exit 1
    fi
    mkdir -p "$motion_version"
    tar -xzf "$motion_archive" -C "$motion_version"
fi
sh "$motion_package/instalar-unix.sh"
if [ -t 1 ]; then sh "$motion_package/motion" --animate; fi
