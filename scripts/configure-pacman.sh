#!/usr/bin/env bash
# Enable our shared preference without owning repositories or distro defaults.
set -euo pipefail

config=$(readlink -e -- "${1:-/etc/pacman.conf}")
[[ -f "$config" ]] || { echo 'pacman.conf must be an existing file.' >&2; exit 1; }
if awk '
  /^[[:space:]]*\[/ {
    options = ($0 ~ /^[[:space:]]*\[options\][[:space:]]*(#.*)?$/)
  }
  options && /^[[:space:]]*ILoveCandy[[:space:]]*(#.*)?$/ { enabled = 1 }
  END { exit !enabled }
' "$config"; then
  echo 'pacman: ILoveCandy already enabled.'
  exit 0
fi

staging=$(mktemp "${config}.XXXXXXXX")
trap 'rm -f -- "$staging"' EXIT
# Preserve ownership, permissions and other metadata when replacing the file.
cp --preserve=all -- "$config" "$staging"
awk '
  { print }
  !found && /^[[:space:]]*\[options\][[:space:]]*(#.*)?$/ {
    print "ILoveCandy"
    found = 1
  }
  END { if (!found) exit 1 }
' "$config" > "$staging" || {
  echo 'Could not configure pacman: expected an [options] section.' >&2
  exit 1
}
cp --preserve=all -- "$config" "$config.dotfiles.bak"
mv -f -- "$staging" "$config"
printf 'pacman: enabled ILoveCandy (backup: %s.dotfiles.bak).\n' "$config"
