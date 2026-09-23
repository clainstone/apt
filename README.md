# clainstone/apt

An apt repository for [cbirds](https://github.com/clainstone/cbirds), a flock
of birds in your terminal: Debian 12 and later, Ubuntu 22.04 and later, and
their derivatives, on amd64 and arm64.

```
curl -fsSL https://clainstone.com/apt/cbirds.gpg | sudo tee /etc/apt/keyrings/cbirds.gpg >/dev/null
echo "deb [signed-by=/etc/apt/keyrings/cbirds.gpg] https://clainstone.com/apt stable main" | sudo tee /etc/apt/sources.list.d/cbirds.list
sudo apt update && sudo apt install cbirds
```

`sudo apt upgrade` brings new releases. `sudo apt remove cbirds` removes it,
and `sudo rm /etc/apt/sources.list.d/cbirds.list /etc/apt/keyrings/cbirds.gpg`
the repository.

The signing key's fingerprint is
`14C9 356B 6C33 9CDD 5E96 C875 E1F8 E445 46C1 D91D`.

## How it is made

Everything is built by the `publish` workflow and served by GitHub Pages:

- `build-deb.sh` builds the package from the release tarball named in
  `cbirds.env`, with its checksum checked and its tests run, on Debian 12 so
  that it runs on every newer system, once on amd64 and once on arm64.
- `publish.sh` lays out the repository and signs it with the key in the
  `APT_SIGNING_KEY` secret.
- `test-install.sh` then installs it on clean Debian and Ubuntu systems, on
  both architectures, exactly as above, runs it and removes it.

A new cbirds release is a new `VERSION` and `SHA256` in `cbirds.env`.
