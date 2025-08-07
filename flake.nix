{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;
  in
    {

      nixosModules = rec {
        homeManagerModules = import ./modules/home-manager;
        nixosModules = import ./modules/nixos;
      };

      overlays = import ./overlays {inherit inputs;};
    };
}
