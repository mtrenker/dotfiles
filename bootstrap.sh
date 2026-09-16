#!/usr/bin/env bash
# Local entry point. Clone the repo first; never reset an existing checkout.
set -euo pipefail

HOST="${1:-}"
case "$HOST" in
  defiant|voyager|serenity|work) shift ;;
  *) printf 'Usage: %s <defiant|voyager|serenity|work> [mise bootstrap flags]\n' "$0" >&2; exit 2 ;;
esac
command -v pacman >/dev/null || { echo 'This setup currently supports Arch/CachyOS with pacman.' >&2; exit 1; }
command -v mise >/dev/null || { echo 'Install mise first: sudo pacman -Syu --needed mise git curl' >&2; exit 1; }
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
# Explicit host selection; no hostname guessing or persistent MISE_ENV setting.
# Skip broad tool installation. Our bootstrap task installs only Claude/Codex/Herdr.
# For a phase-specific --only invocation, use mise directly rather than this wrapper.
exec env MISE_ENV="$HOST" mise bootstrap --skip tools "$@"
