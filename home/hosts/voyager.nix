# Host: voyager — maxed-out Framework desktop
{ pkgs, ... }:

{
  imports = [
    ../features/dev.nix
    ../features/niri.nix
  ];

  home.username = "martin";
  home.homeDirectory = "/home/martin";

  programs.git.settings.user.email = "martin@pacabytes.io";

  home.packages = with pkgs; [
    # Machine-specific packages for voyager go here.
  ];
}
