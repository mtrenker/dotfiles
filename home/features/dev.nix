{ pkgs, ... }:

{
  imports = [
    ../programs/neovim.nix
  ];

  home.packages = with pkgs; [
    # Go / Charmbracelet development
    go
    gopls
    delve
    golangci-lint
  ];
}
