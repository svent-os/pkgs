#!/bin/sh
# Build Svent OS component packages and import them into the reprepro repo.
# Run from the pkgs repo. Sibling component repos must sit next to this one.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)
labdeb="$root/svent-infra/bin/lab-build-deb"
out="$here/incoming"
mkdir -p "$out"

# Generated assets produced before packaging
python3 "$root/svent-login/bin/gen-background" >/dev/null 2>&1 || true
sh "$root/svent-artwork/bin/stage-assets" "$root/svent-artwork/staging" >/dev/null 2>&1 || true

for c in svent-core svent-artwork svent-xfce svent-bspwm svent-boot svent-login; do
  echo "building $c"
  if command -v dpkg-buildpackage >/dev/null 2>&1; then
    ( cd "$root/$c" && dpkg-buildpackage -b -us -uc )
    mv "$root"/*.deb "$out"/ 2>/dev/null || true
  else
    sh "$labdeb" "$root/$c" "$out"
  fi
done

# Tool group metapackages, generated from the catalog
echo "generating tool group metapackages"
python3 "$root/svent-infra/bin/gen-metapackages" >/dev/null
for m in "$root"/svent-infra/metapackages/svent-tools-*; do
  [ -d "$m" ] || continue
  echo "building $(basename "$m")"
  sh "$labdeb" "$m" "$out"
done

# Svent maintained tool packages (built only when a full build env is present)
if command -v dpkg-buildpackage >/dev/null 2>&1; then
  for t in "$root"/svent-infra/tools/*; do
    [ -f "$t/get-orig-source.sh" ] || continue
    echo "building $(basename "$t") from upstream source"
    ( cd "$t" && sh get-orig-source.sh && dpkg-buildpackage -b -us -uc ) || \
      echo "skip $(basename "$t"): build failed or needs build-deps"
    mv "$root"/svent-infra/tools/*.deb "$out"/ 2>/dev/null || true
  done
fi

if command -v reprepro >/dev/null 2>&1; then
  for deb in "$out"/*.deb; do
    reprepro -b "$here" includedeb rolling "$deb"
  done
  echo "repo built under $here/dists and $here/pool"
else
  echo "reprepro not installed; built .deb files are in $out"
fi
