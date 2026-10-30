# jadren-aur

Keeps my AUR packages up to date. Every 6 hours a GitHub Actions run bumps each
package in `packages/`, checks that it builds, and pushes to the AUR.

## Adding a package

Add `packages/<pkgname>/update.sh`. It runs inside a fresh clone of the AUR repo
and should rewrite `PKGBUILD` and `.SRCINFO` when a new version exists, leaving
them untouched otherwise. Committing and pushing are handled by `ci/`. The build
runs with `makepkg -d`, so dependencies are not installed; this suits repackaged
binaries, not packages that compile from source.

`pi-desktop-git` is not included: it builds from the latest commit on the user's
machine, so it does not need a push for each upstream change.

## Secrets

- `AUR_SSH_PRIVATE_KEY`: private key registered on the AUR account
- `AUR_SSH_PASSPHRASE`: its passphrase; leave unset if it has none

```sh
gh secret set AUR_SSH_PRIVATE_KEY < ~/.ssh/KEY_FILE
gh secret set AUR_SSH_PASSPHRASE
```

Run it by hand with `gh workflow run update.yml`.
