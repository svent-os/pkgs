#!/bin/sh
# Publish the built repo (dists/ pool/ and the public key) to the gh-pages
# branch, for GitHub Pages hosting at apt.zirov.net. Run from the pkgs repo
# after reprepro has built dists/ and pool/. Needs git push access.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
[ -d "$here/dists" ] || { echo "no dists/; run build-repo.sh or reprepro first" >&2; exit 1; }
domain="${1:-apt.zirov.net}"
wt="$here/.gh-pages"

# Free the gh-pages branch from any leftover worktree, then prune
git -C "$here" worktree list --porcelain 2>/dev/null \
  | awk '/^worktree /{p=substr($0,10)} /^branch refs\/heads\/gh-pages$/{print p}' \
  | while read -r w; do git -C "$here" worktree remove --force "$w" 2>/dev/null || true; done
rm -rf "$wt"
git -C "$here" worktree prune

git -C "$here" worktree add -B gh-pages "$wt"
find "$wt" -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
cp -a "$here/dists" "$here/pool" "$wt/"
[ -f "$here/svent-archive-keyring.gpg" ] && cp "$here/svent-archive-keyring.gpg" "$wt/"
[ -f "$here/add-apt-sventOS.sh" ] && cp "$here/add-apt-sventOS.sh" "$wt/"
printf '%s\n' "$domain" > "$wt/CNAME"
: > "$wt/.nojekyll"

git -C "$wt" add -A
git -C "$wt" commit -m "Publish Svent APT repo" >/dev/null || true
git -C "$wt" push -f origin gh-pages
git -C "$here" worktree remove --force "$wt"

echo "Pushed gh-pages. Now set Pages Source branch to gh-pages (Settings -> Pages)."
