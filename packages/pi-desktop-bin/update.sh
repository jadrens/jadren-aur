#!/usr/bin/env bash
# Bump PKGBUILD to the latest stable GitHub release (pre-releases are skipped).
#
# Usage: ./update.sh [-f] [-b] [-c] [-p]
#   -f  force rewrite even if pkgver is already current (resets pkgrel=1)
#   -b  build the package with makepkg afterwards
#   -c  git commit PKGBUILD and .SRCINFO
#   -p  git push to AUR (implies -c)
set -euo pipefail

REPO="vastsa/PI-Desktop"
cd "$(dirname "$(readlink -f "$0")")"

force=0 build=0 commit=0 push=0
while getopts "fbcph" opt; do
  case $opt in
    f) force=1 ;;
    b) build=1 ;;
    c) commit=1 ;;
    p) commit=1; push=1 ;;
    *) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
done

die() { echo "error: $*" >&2; exit 1; }
for cmd in gh makepkg sha256sum curl; do
  command -v "$cmd" >/dev/null || die "$cmd not found"
done

# /releases/latest only returns the newest non-draft, non-prerelease release
tag=$(gh api "repos/$REPO/releases/latest" -q .tag_name)
newver=${tag#v}
[[ $newver =~ ^[0-9A-Za-z._+]+$ ]] || die "tag '$tag' is not a valid pkgver"

oldver=$(sed -n 's/^pkgver=//p' PKGBUILD)
echo "current: $oldver  latest: $newver ($tag)"
if [[ $newver == "$oldver" && $force -eq 0 ]]; then
  echo "already up to date"
  exit 0
fi

# sha256 of a release asset, taken from GitHub's digest field
asset_sha() {
  local name=$1 digest
  digest=$(gh api "repos/$REPO/releases/tags/$tag" \
    -q ".assets[] | select(.name == \"$name\") | .digest")
  [[ -n $digest ]] || die "asset $name not found in $tag"
  [[ $digest == sha256:* ]] || die "unexpected digest for $name: $digest"
  echo "${digest#sha256:}"
}

sha_amd64=$(asset_sha "pi-desktop_${newver}_amd64.deb")
sha_arm64=$(asset_sha "pi-desktop_${newver}_arm64.deb")
sha_license=$(curl -fsSL "https://raw.githubusercontent.com/$REPO/$tag/LICENSE" | sha256sum | cut -d' ' -f1)

sed -i \
  -e "s/^pkgver=.*/pkgver=$newver/" \
  -e "s/^pkgrel=.*/pkgrel=1/" \
  -e "s/^sha256sums=.*/sha256sums=('$sha_license')/" \
  -e "s/^sha256sums_x86_64=.*/sha256sums_x86_64=('$sha_amd64')/" \
  -e "s/^sha256sums_aarch64=.*/sha256sums_aarch64=('$sha_arm64')/" \
  PKGBUILD
makepkg --printsrcinfo > .SRCINFO

git --no-pager diff --stat -- PKGBUILD .SRCINFO 2>/dev/null || true
echo "updated PKGBUILD to $newver-1"

if (( build )); then
  makepkg -f
fi

if (( commit )); then
  git add PKGBUILD .SRCINFO
  git commit -m "Update to $newver-1"
fi

if (( push )); then
  git push origin HEAD
fi
