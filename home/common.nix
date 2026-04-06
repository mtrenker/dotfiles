# Shared Home Manager configuration — imported by every host.
# Host files supply `username` (and optionally `hostname`) via the module system.
{ config, pkgs, hostname, ... }:

{
  imports = [
    ./programs/bash.nix
    ./programs/git.nix
    ./programs/neovim.nix
    ./programs/packages.nix
  ];

  # username and homeDirectory are set per-host (see home/hosts/*.nix)
  home.stateVersion = "24.11";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # XDG base dirs
  xdg.enable = true;

  # Prettier diffs / less pager
  home.sessionVariables = {
    EDITOR  = "nvim";
    PAGER   = "less -FRX";
    MANPAGER = "nvim +Man!";
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
  };

  # Make npm-global binaries available on PATH
  home.sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];
}
