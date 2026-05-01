# Shared Home Manager configuration — imported by every host.
# Host files supply `username` (and optionally `hostname`) via the module system.
{ config, pkgs, hostname, ... }:

{
  imports = [
    ./programs/bash.nix
    ./programs/git.nix
    ./programs/packages.nix
  ];

  # username and homeDirectory are set per-host (see home/hosts/*.nix)
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # XDG base dirs
  xdg.enable = true;

  # User locale. On non-NixOS this affects Home Manager sessions and Nix-built
  # applications; the system locale is still owned by the host distro.
  home.language = {
    base = "de_DE.UTF-8";
    ctype = "de_DE.UTF-8";
    numeric = "de_DE.UTF-8";
    time = "de_DE.UTF-8";
    collate = "de_DE.UTF-8";
    monetary = "de_DE.UTF-8";
    messages = "de_DE.UTF-8";
    paper = "de_DE.UTF-8";
    name = "de_DE.UTF-8";
    address = "de_DE.UTF-8";
    telephone = "de_DE.UTF-8";
    measurement = "de_DE.UTF-8";
  };

  # Prettier diffs / less pager
  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less -FRX";
    MANPAGER = "nvim +Man!";

    # Keep npm globals separate from the Nix-managed Node installation.
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";

    # pnpm v10 expects an explicit global bin dir (or PNPM_HOME).
    PNPM_HOME = "${config.xdg.dataHome}/pnpm";
  };

  # Make npm and pnpm global binaries available on PATH
  home.sessionPath = [
    "${config.home.homeDirectory}/.npm-global/bin"
    "${config.xdg.dataHome}/pnpm"
  ];
}
