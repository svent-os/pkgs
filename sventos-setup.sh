#!/bin/sh
set -eu
KEY_URL="https://apt.zirov.net/svent-archive-keyring.gpg"
KEYRING="/usr/share/keyrings/svent-archive-keyring.gpg"
SOURCE="/etc/apt/sources.list.d/svent.sources"

[ "$(id -u)" = "0" ] || { echo "run this as root (sudo)" >&2; exit 1; }

if ! command -v curl >/dev/null 2>&1; then
  apt-get update && apt-get install -y curl
fi

curl -fsSL "$KEY_URL" -o "$KEYRING"
cat > "$SOURCE" <<SRC
Types: deb
URIs: https://apt.zirov.net
Suites: rolling
Components: main
Signed-By: $KEYRING
SRC
apt-get update
printf '[+] Installation completed successfully.\n'
