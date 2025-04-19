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

    eachDefaultEnvironment = f:
      flake-utils.lib.eachDefaultSystem
      (
        system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
              # You likely (but not necessarily) want the default overlay from your flake here
              # overlays = [self.overlays.default];
            };
          }
      );
  in

    # # Per system outputs:
    # eachDefaultEnvironment ({ system, pkgs }: {
    #   azos-packages = ((import ./pkgs) {pkgs = pkgs ;} );
    # });


    # Generic outputs:
    {

      nixosModules = rec {
        homeManagerModules = import ./modules/home-manager;
        nixosModules = import ./modules/nixos;
      };

      # azos-pkgs-overlay = final: _prev: import ./pkgs {pkgs = final;};
      overlays = import ./overlays {inherit inputs;};

      # overlays = rec {
      #   azos-pkgs = import ./pkgs;
      #   default = final: prev:
      #     lib.composeManyExtensions [ azos-pkgs ] final prev;
      # };
    };
}
