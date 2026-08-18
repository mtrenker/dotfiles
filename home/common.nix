# Shared Home Manager configuration — imported by every host.
# Host files supply `username` (and optionally `hostname`) via the module system.
{ config, pkgs, hostname, ... }:

let
  englishLocale = "en_US.UTF-8";
  localeVariables = {
    LANG = englishLocale;
    LC_ADDRESS = englishLocale;
    LC_COLLATE = englishLocale;
    LC_CTYPE = englishLocale;
    LC_MEASUREMENT = englishLocale;
    LC_MESSAGES = englishLocale;
    LC_MONETARY = englishLocale;
    LC_NAME = englishLocale;
    LC_NUMERIC = englishLocale;
    LC_PAPER = englishLocale;
    LC_TELEPHONE = englishLocale;
    LC_TIME = englishLocale;
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
    base = englishLocale;
    ctype = englishLocale;
    numeric = englishLocale;
    time = englishLocale;
    collate = englishLocale;
    monetary = englishLocale;
    messages = englishLocale;
    paper = englishLocale;
    name = englishLocale;
    address = englishLocale;
    telephone = englishLocale;
    measurement = englishLocale;
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
