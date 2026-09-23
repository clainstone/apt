#!/bin/sh
# Builds cbirds_<version>-<revision>_<arch>.deb in the current directory from
# the release tarball named in cbirds.env, for the architecture it runs on.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
. "$here/cbirds.env"

arch=$(dpkg --print-architecture)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

curl -fsSL -o "$work/src.tar.gz" \
    "https://github.com/clainstone/cbirds/archive/refs/tags/v$VERSION.tar.gz"
echo "$SHA256  $work/src.tar.gz" | sha256sum -c -
tar -xzf "$work/src.tar.gz" -C "$work"
src="$work/cbirds-$VERSION"
root="$work/root"

make -C "$src" test
make -C "$src" install DESTDIR="$root" PREFIX=/usr
bin="$root/usr/bin/cbirds"
strip "$bin"

share="$root/usr/share"
install -d "$share/bash-completion/completions" "$share/zsh/vendor-completions" \
    "$share/fish/vendor_completions.d" "$share/doc/cbirds"
"$bin" --completion bash > "$share/bash-completion/completions/cbirds"
"$bin" --completion zsh > "$share/zsh/vendor-completions/_cbirds"
"$bin" --completion fish > "$share/fish/vendor_completions.d/cbirds.fish"
{
    echo "Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/"
    echo "Upstream-Name: cbirds"
    echo "Source: https://github.com/clainstone/cbirds"
    echo
    echo "Files: *"
    echo "Copyright: $(grep -m1 '^Copyright' "$src/LICENSE" | sed 's/^Copyright (c) //')"
    echo "License: MIT"
    sed -e 's/^$/./' -e 's/^/ /' "$src/LICENSE"
} > "$share/doc/cbirds/copyright"
find "$root" -type d -exec chmod 0755 {} +
find "$share" -type f -exec chmod 0644 {} +

# The newest glibc symbol the binary uses is the oldest libc it runs on.
glibc=$(objdump -T "$bin" | grep -o 'GLIBC_[0-9.]*' | sed 's/GLIBC_//' | sort -V | tail -1)
install -d "$root/DEBIAN"
cat > "$root/DEBIAN/control" <<EOF
Package: cbirds
Version: $VERSION-$REVISION
Architecture: $arch
Maintainer: Alessandro Palliccia <115735120+clainstone@users.noreply.github.com>
Installed-Size: $(du -sk "$root/usr" | cut -f1)
Depends: libc6 (>= $glibc)
Section: games
Priority: optional
Homepage: https://github.com/clainstone/cbirds
Description: flock of birds in your terminal
 Craig Reynolds' boids, drawn as sprites over the Kitty graphics protocol in
 Kitty and Ghostty, and as braille in every other terminal. Hawks, several
 flocks, a second sky, trails, and GIF and asciinema recording, in one C99
 program with no dependencies.
EOF

dpkg-deb --build --root-owner-group "$root" "cbirds_${VERSION}-${REVISION}_${arch}.deb"
