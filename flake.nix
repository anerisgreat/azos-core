{
  inputs = {
    cabata = {
      url = "github:anerisgreat/cabata";
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;
  in rec {
    overlays = import ./overlays {inherit inputs;};
    nixosModules = rec {
      homeManagerModules = import ./modules/home-manager;
      nixosModules = import ./modules/nixos;
    };

  };
}
