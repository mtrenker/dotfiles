{
  description = "Home Manager dotfiles — multi-host Linux configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Build a homeManagerConfiguration for a given host.
      # Each host file at home/hosts/<hostname>.nix must define:
      #   username   = "your-unix-username";
      #   hostname   = "<hostname>";  (optional, for reference)
      #   and any host-specific home-manager options.
      mkHome = hostname:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            ./home/common.nix
            ./home/hosts/${hostname}.nix
          ];
          extraSpecialArgs = { inherit hostname; };
        };
    in
    {
      # Add / remove hosts here.
      # Apply with: home-manager switch --flake .#<hostname>
      homeConfigurations = {
        work = mkHome "work";
        home = mkHome "home";
      };

      # Convenience: `nix fmt` formats all .nix files
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
