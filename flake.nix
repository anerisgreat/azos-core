{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    cabata = {
      url = "github:anerisgreat/cabata";
    };
    evil-hl-line = {
      url = "github:anerisgreat/evil-hl-line";
      flake = true;
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./_lib/modules.nix
        ./overlays/default.nix
        (inputs.import-tree ./features)
        {_module.args.azosCoreInputs = inputs;}
      ];

      flake.flakeModules.default = {
        imports = [
          ./_lib/modules.nix
          ./overlays/default.nix
          (inputs.import-tree ./features)
          {_module.args.azosCoreInputs = inputs;}
        ];
      };
    };
}
