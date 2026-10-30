# aur-pi-desktop

Keeps the `pi-desktop-bin` and `pi-desktop-beta-bin` AUR packages on the latest
[PI-Desktop](https://github.com/vastsa/PI-Desktop) releases. Every 6 hours a
GitHub Actions run bumps each package, checks that it builds, and pushes to the AUR.

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
