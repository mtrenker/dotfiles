# Host: home — home desktop / personal machine configuration
{ pkgs, ... }:

{
  home.username    = "martin";         # TODO: change to your actual username
  home.homeDirectory = "/home/martin"; # TODO: adjust if different

  # Host-specific git identity (overrides common.nix defaults)
  programs.git.settings.user.email = "martin@pacabytes.io"; # TODO: set personal email

  # Home-specific packages
  home.packages = with pkgs; [
    # e.g. mpv, obs-studio, discord …
  ];
}
