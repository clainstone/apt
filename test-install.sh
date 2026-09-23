#!/bin/sh
# Installs cbirds on a clean Debian or Ubuntu the way the README says, runs it,
# and removes it. As root, so without the sudo the README has.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
. "$here/cbirds.env"
url=https://clainstone.com/apt

apt-get update
apt-get install -y --no-install-recommends curl ca-certificates

install -d -m 0755 /etc/apt/keyrings
curl -fsSL "$url/cbirds.gpg" | tee /etc/apt/keyrings/cbirds.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/cbirds.gpg] $url stable main" |
    tee /etc/apt/sources.list.d/cbirds.list

# Pages can take a minute or two to serve what was just deployed.
tries=0
until apt-get update >/dev/null && apt-cache policy cbirds | grep -q "Candidate: $VERSION-$REVISION"; do
    tries=$((tries + 1))
    [ "$tries" -lt 20 ] || { apt-cache policy cbirds; exit 1; }
    sleep 15
done

apt-get install -y cbirds
cbirds --version | grep -x "cbirds $VERSION"
cbirds --bench 30 | grep -q fps
test -s /usr/share/bash-completion/completions/cbirds
test -s /usr/share/zsh/vendor-completions/_cbirds
test -s /usr/share/fish/vendor_completions.d/cbirds.fish

apt-get remove -y cbirds
if command -v cbirds; then exit 1; fi
echo "installed, ran and removed cbirds $VERSION-$REVISION"
