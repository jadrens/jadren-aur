#!/usr/bin/env bash
# Clone one AUR package, bump it with its update.sh, and push only if the new
# version builds. Dependencies are not installed: the build just repackages a
# prebuilt .deb, so makepkg runs with -d.
#
# Usage: ci/update-package.sh PKGNAME
set -euo pipefail

pkg=$1
root=$(dirname "$(readlink -f "$0")")/..
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

git clone -q "ssh://aur@aur.archlinux.org/$pkg.git" "$work/$pkg"
# Stays untracked: AUR repos ignore everything but the packaging files
cp "$root/packages/$pkg/update.sh" "$work/$pkg/"
cd "$work/$pkg"

./update.sh
[[ -n $(git status --porcelain -- PKGBUILD .SRCINFO) ]] || exit 0

makepkg -fd --noconfirm

ver=$(sed -n 's/^\tpkgver = //p' .SRCINFO)
rel=$(sed -n 's/^\tpkgrel = //p' .SRCINFO)
git add PKGBUILD .SRCINFO
git commit -qm "Update to $ver-$rel"
git push origin HEAD
