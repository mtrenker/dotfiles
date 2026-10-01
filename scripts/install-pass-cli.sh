#!/usr/bin/env bash
# Official Linux x86_64 binary, pinned from:
# https://proton.me/download/pass-cli/versions.json
set -euo pipefail
if [[ $(uname -s) != Linux || $(uname -m) != x86_64 ]]; then
  echo "This installer supports Linux x86_64 only." >&2
  exit 1
fi
version=2.4.1
sha256=f4188430466e0a3d668b56791a8b430162cb20ceb108fed4fdbfcfe77d3080e6
target="$HOME/.local/bin/pass-cli"
# Leave an already verified installation untouched.
if [[ -f "$target" && -x "$target" ]] && printf '%s  %s\n' "$sha256" "$target" | sha256sum --check --status; then
  exit 0
fi
mkdir -p "$HOME/.local/bin"
staging=$(mktemp -d "$HOME/.local/bin/.pass-cli.XXXXXXXX")
trap 'rm -rf -- "$staging"' EXIT
curl --fail --location --show-error --silent --proto '=https' --proto-redir '=https' \
  "https://proton.me/download/pass-cli/$version/pass-cli-linux-x86_64" \
  --output "$staging/pass-cli"
printf '%s  %s\n' "$sha256" "$staging/pass-cli" | sha256sum --check --status
chmod 755 "$staging/pass-cli"
mv -fT -- "$staging/pass-cli" "$target"
printf 'Installed %s. Sign in with: pass-cli login\n' "$target"
