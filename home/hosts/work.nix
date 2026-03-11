# Host: work — work laptop configuration
{ pkgs, ... }:

{
  home.username    = "martin";
  home.homeDirectory = "/home/martin";

  # Host-specific git identity (overrides common.nix defaults)
  programs.git.userEmail = "martin@pacabytes.io";

  # Work-specific packages
  home.packages = with pkgs; [
    # e.g. kubectl, awscli2, docker-compose, terraform …
  ];
}
