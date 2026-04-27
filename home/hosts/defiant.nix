# Host: defiant — beefy main PC
{ pkgs, ... }:

{
  imports = [
    ../features/dev.nix
  ];

  home.username = "martin";
  home.homeDirectory = "/home/martin";

  programs.git.settings.user.email = "martin@pacabytes.io";

  home.packages = with pkgs; [
    # Machine-specific packages for defiant go here.
  ];
}
