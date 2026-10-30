#!/usr/bin/env sh
set -e
MIRROR=https://github.com/coder/coder/releases/download
DIR=$(mktemp -d)
trap 'rm -rf "$DIR"' EXIT

dl() {
    local app=$1
    local ver=$2
    local lchecksums=$3
    local os=$4
    local arch=$5
    local archive_type=${6:-tar.gz}
    local platform="${os}_${arch}"
    local file="${app}_${ver}_${platform}.${archive_type}"
    local url="$MIRROR/v$ver/$file"
    local sum
    sum=$(awk -v f="$file" '$2 == f {print $1}' "$lchecksums")
    if ! printf '%s' "$sum" | grep -Eq '^[0-9a-f]{64}$'
    then
        echo "bad or missing checksum for $file: '$sum'" >&2
        exit 1
    fi
    printf "    # %s\n" "$url"
    printf "    %s: sha256:%s\n" "$platform" "$sum"
}

dl_ver() {
    local app=$1
    local ver=$2
    # https://github.com/coder/coder/releases/download/v0.13.6/coder_0.13.6_checksums.txt
    local url="$MIRROR/v$ver/${app}_${ver}_checksums.txt"
    local lchecksums="$DIR/${app}_${ver}_checksums.txt"
    curl -fsSL --proto '=https' --tlsv1.2 -o "$lchecksums" "$url"

    printf "  # %s\n" "$url"
    printf "  '%s':\n" "$ver"

    dl "$app" "$ver" "$lchecksums" darwin amd64 zip
    dl "$app" "$ver" "$lchecksums" darwin arm64 zip
    dl "$app" "$ver" "$lchecksums" linux amd64
    dl "$app" "$ver" "$lchecksums" linux arm64
    dl "$app" "$ver" "$lchecksums" linux armv7
    dl "$app" "$ver" "$lchecksums" windows amd64 zip
    dl "$app" "$ver" "$lchecksums" windows arm64 zip
}

dl_ver coder "${1:-2.38.4}"
