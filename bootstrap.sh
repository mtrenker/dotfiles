#!/usr/bin/env bash
# bootstrap.sh — set up a fresh Linux machine from scratch.
# Usage: bash bootstrap.sh <hostname>
#   hostname must match a key in flake.nix homeConfigurations (e.g. "work" or "home")

set -euo pipefail

DOTFILES_REPO="https://github.com/mtrenker/dotfiles" # TODO: update
DOTFILES_DIR="$HOME/.dotfiles"
HOST="${1:-}"

# ── Helpers ───────────────────────────────────────────────────────────────────
info()  { printf '\033[1;34m[info]\033[0m  %s\n' "$*"; }
ok()    { printf '\033[1;32m[ ok ]\033[0m  %s\n' "$*"; }
die()   { printf '\033[1;31m[err ]\033[0m  %s\n' "$*" >&2; exit 1; }

[[ -n "$HOST" ]] || die "Usage: bash bootstrap.sh <hostname>  (e.g. work | home)"

# ── 1. Install Nix (Determinate Systems installer) ────────────────────────────
if [[ ! -d /nix ]]; then
  info "Installing Nix via Determinate Systems installer…"
  curl --proto '=https' --tlsv1.2 -sSfL https://install.determinate.systems/nix \
    | sudo sh -s -- install --no-confirm
  [[ -d /nix ]] || die "Nix install failed — /nix was not created."
  ok "Nix installed"
fi

# Make nix available in the current shell — the profile script may not exist yet
# right after a fresh install, so extend PATH directly.
NIX_PROFILE="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
if [[ -f "$NIX_PROFILE" ]]; then
  # shellcheck disable=SC1090
  source "$NIX_PROFILE"
else
  export PATH="/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:$PATH"
  export NIX_SSL_CERT_FILE="/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt"
fi

command -v nix &>/dev/null || die "nix binary not found after install — try opening a new shell and re-running."
ok "Nix $(nix --version)"

# ── 2. Clone dotfiles ─────────────────────────────────────────────────────────
if [[ -d "$DOTFILES_DIR" ]]; then
  info "Dotfiles already present at $DOTFILES_DIR — syncing to remote…"
  git -C "$DOTFILES_DIR" fetch origin
  git -C "$DOTFILES_DIR" reset --hard origin/HEAD
else
  info "Cloning dotfiles to $DOTFILES_DIR…"
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# ── 3. Back up any pre-existing dotfiles that home-manager will conflict with ──
for f in "$HOME/.gitconfig"; do
  if [[ -f "$f" && ! -L "$f" ]]; then
    info "Backing up $f → $f.bak"
    mv "$f" "$f.bak"
  fi
done

# ── 4. Apply Home Manager configuration ──────────────────────────────────────
info "Running home-manager switch for host: $HOST"
nix run nixpkgs#home-manager -- switch \
  --flake "$DOTFILES_DIR#$HOST" \
  --extra-experimental-features "nix-command flakes" \
  -b backup

ok "Done! Open a new terminal (or run: exec fish) to enjoy your new environment."
