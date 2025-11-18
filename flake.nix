{
  inputs = {
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;
  in {
    nixosModules = rec {
      homeManagerModules = import ./modules/home-manager;
      nixosModules = import ./modules/nixos;
    };

    overlays = import ./overlays {inherit inputs;};
  };
}
