{
  inputs = {
    cabata = {
      url = "github:anerisgreat/cabata";
    };
    nix-search-cli = {
      url = "github:peterldowns/nix-search-cli";
    };
  };

  outputs = {
    self,
    nixpkgs,
    cabata,
    nix-search-cli,
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
      inherit cabata nix-search-cli;
    };
  };
}
