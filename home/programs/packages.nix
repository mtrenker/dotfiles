{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # ── Shell tools ──────────────────────────────────────────────────────
    bat          # better cat (also used by neovim MANPAGER)
    eza          # better ls
    fd           # better find
    ripgrep      # better grep

    # ── File / archive ───────────────────────────────────────────────────
    unzip
    zip
    p7zip
    xz

    # ── Network ──────────────────────────────────────────────────────────
    curl
    wget
    httpie       # friendly HTTP client

    # ── System monitoring ────────────────────────────────────────────────
    htop
    bottom       # btm — nicer htop
    dust         # dust — intuitive du
    duf          # better df

    # ── Dev utilities ────────────────────────────────────────────────────
    jq           # JSON processor
    yq-go        # YAML/JSON/TOML processor
    gh           # GitHub CLI
    git-lfs
    lazygit      # TUI git client
    nixpkgs-fmt  # Nix formatter

    # ── Runtimes ─────────────────────────────────────────────────────────
    nodejs_22    # Node.js LTS
    nodePackages.pnpm  # pnpm package manager
    (dotnetCorePackages.combinePackages [
      dotnetCorePackages.sdk_8_0
      dotnetCorePackages.sdk_9_0
      dotnetCorePackages.sdk_10_0
    ])

    # ── Misc ─────────────────────────────────────────────────────────────
    fastfetch    # system info
    tldr         # quick man pages
    tokei        # code statistics
  ];
}
