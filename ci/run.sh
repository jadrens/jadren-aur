#!/usr/bin/env bash
# CI entry point: load the AUR key into an agent, then update each package.
# A failing package does not stop the others, but fails the run.
#
# Env: AUR_SSH_PRIVATE_KEY, AUR_SSH_PASSPHRASE (empty if the key has none)
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")/.."

[[ -n ${AUR_SSH_PRIVATE_KEY:-} ]] || { echo "error: AUR_SSH_PRIVATE_KEY secret is not set" >&2; exit 1; }

install -dm700 ~/.ssh
cat > ~/.ssh/known_hosts <<'HOSTS'
aur.archlinux.org ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuBKrPzbawxA/k2g6NcyV5jmqwJ2s+zpgZGZ7tpLIcN
HOSTS

# Separate assignment: eval "$(...)" would hide a failed start and fall through
# to any inherited agent.
agent_env=$(ssh-agent -s)
eval "$agent_env" >/dev/null
trap 'ssh-agent -k >/dev/null' EXIT

askpass=$(mktemp)
printf '#!/bin/sh\nprintf "%%s\\n" "$AUR_SSH_PASSPHRASE"\n' > "$askpass"
chmod 700 "$askpass"
# timeout: ssh-add keeps asking forever when the passphrase is wrong
tr -d '\r' <<< "$AUR_SSH_PRIVATE_KEY" \
  | SSH_ASKPASS=$askpass SSH_ASKPASS_REQUIRE=force timeout 30 ssh-add -q - \
  || { echo "error: could not load AUR_SSH_PRIVATE_KEY; check the key and passphrase" >&2; exit 1; }
rm -f "$askpass"
unset AUR_SSH_PRIVATE_KEY AUR_SSH_PASSPHRASE

git config --global user.name "Jadren"
git config --global user.email "jadren@jadren.dev"

failed=0
for dir in packages/*/; do
  pkg=$(basename "$dir")
  echo "::group::$pkg"
  bash ci/update-package.sh "$pkg" || { echo "::error::$pkg failed"; failed=1; }
  echo "::endgroup::"
done
exit "$failed"
