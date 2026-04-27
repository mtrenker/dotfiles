# Host: serenity — first-generation Framework laptop
{ pkgs, ... }:

{
  imports = [
    ../features/niri.nix
  ];

  home.username = "martin";
  home.homeDirectory = "/home/martin";

  programs.git.settings.user.email = "martin@pacabytes.io";

  home.packages = with pkgs; [
    # Machine-specific packages for serenity go here.
  ];
}
