{
  inputs = {
    cabata = {
      url = "github:anerisgreat/cabata";
    };
    evil-hl-line = {
      url = "github:anerisgreat/evil-hl-line";
      flake = true;
    };
  };

  outputs = {
    self,
    nixpkgs,
    cabata,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;
  in rec {
    overlays = import ./overlays {inherit inputs;};
    nixosModules = rec {
      homeManagerModules = import ./modules/home-manager;
      nixosModules = import ./modules/nixos;
    };
    specialArgs = {
      inherit cabata;
    };
  };
}
