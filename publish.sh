#!/bin/sh
# Lays out a signed apt repository in SITE from the .deb files in DEBS:
#     publish.sh DEBS SITE
# The signing key comes from APT_SIGNING_KEY, an armoured private key.
set -eu
debs=$(cd "$1" && pwd)
mkdir -p "$2"
site=$(cd "$2" && pwd)
here=$(cd "$(dirname "$0")" && pwd)

export GNUPGHOME=$(mktemp -d)
trap 'rm -rf "$GNUPGHOME"' EXIT
printf '%s\n' "$APT_SIGNING_KEY" | gpg --batch --import 2>/dev/null
key=$(gpg --batch --list-secret-keys --with-colons | awk -F: '/^fpr/ {print $10; exit}')

mkdir -p "$site/pool/main/c/cbirds"
cp "$debs"/*.deb "$site/pool/main/c/cbirds/"
cd "$site"
archs=""
for arch in amd64 arm64; do
    dir="dists/stable/main/binary-$arch"
    mkdir -p "$dir"
    dpkg-scanpackages --arch "$arch" pool/ > "$dir/Packages" 2>/dev/null
    gzip -9kn "$dir/Packages"
    [ -s "$dir/Packages" ] && archs="$archs $arch"
done

cd dists/stable
{
    echo "Origin: clainstone"
    echo "Label: cbirds"
    echo "Suite: stable"
    echo "Codename: stable"
    echo "Date: $(date -Ru)"
    echo "Architectures:$archs"
    echo "Components: main"
    echo "Description: cbirds, a flock of birds in your terminal"
    echo "SHA256:"
    for f in main/binary-*/Packages*; do
        printf ' %s %16d %s\n' "$(sha256sum "$f" | cut -d' ' -f1)" "$(wc -c < "$f")" "$f"
    done
} > Release
gpg --batch --yes --default-key "$key" --clearsign -o InRelease Release
gpg --batch --yes --default-key "$key" -abs -o Release.gpg Release
cd "$site"

gpg --batch --export "$key" > cbirds.gpg
gpg --batch --armor --export "$key" > cbirds.asc
cp "$here/index.html" index.html
