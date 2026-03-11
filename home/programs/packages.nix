{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    # ── Shell tools ──────────────────────────────────────────────────────
    bat          # better cat (also used by neovim MANPAGER)
    eza          # better ls
    fd           # better find
    ripgrep      # better grep
    fzf          # fuzzy finder
    zoxide       # smarter cd (use with `z` command)
    starship     # cross-shell prompt

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
    direnv       # per-directory env vars
    nixpkgs-fmt  # Nix formatter

    # ── Misc ─────────────────────────────────────────────────────────────
    fastfetch    # system info
    tldr         # quick man pages
    tokei        # code statistics
  ];

  # zoxide — smarter `cd`
  programs.zoxide = {
    enable            = true;
    enableFishIntegration = true;
  };

  # starship prompt
  programs.starship = {
    enable            = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol   = "[❯](bold red)";
      };
      nix_shell.disabled = false;
    };
  };

  # direnv — auto-load .envrc / shell.nix / flake.nix
  programs.direnv = {
    enable            = true;
    nix-direnv.enable = true;
  };
}
