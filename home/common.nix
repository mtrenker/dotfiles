# Shared Home Manager configuration — imported by every host.
# Host files supply `username` (and optionally `hostname`) via the module system.
{ config, pkgs, hostname, ... }:

let
  germanLocale = "de_DE.UTF-8";
  localeVariables = {
    LANG = germanLocale;
    LC_ADDRESS = germanLocale;
    LC_COLLATE = germanLocale;
    LC_CTYPE = germanLocale;
    LC_MEASUREMENT = germanLocale;
    LC_MESSAGES = germanLocale;
    LC_MONETARY = germanLocale;
    LC_NAME = germanLocale;
    LC_NUMERIC = germanLocale;
    LC_PAPER = germanLocale;
    LC_TELEPHONE = germanLocale;
    LC_TIME = germanLocale;
  };
in
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
    base = germanLocale;
    ctype = germanLocale;
    numeric = germanLocale;
    time = germanLocale;
    collate = germanLocale;
    monetary = germanLocale;
    messages = germanLocale;
    paper = germanLocale;
    name = germanLocale;
    address = germanLocale;
    telephone = germanLocale;
    measurement = germanLocale;
  };

  # Make the same locale visible to apps launched by systemd user services,
  # including the Niri session on non-NixOS hosts.
  systemd.user.sessionVariables = localeVariables;

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
