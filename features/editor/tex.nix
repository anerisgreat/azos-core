{...}: {
  config.flake.overlayPkgs.azos-tex = pkgs:
    pkgs.callPackage ./_pkg.nix {inherit pkgs;};

  config.flake.modules.homeManager.editor = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.tex.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    config = lib.mkIf (config.azos.tex.enable && config.azos.suites.editor.enable) {
      home.packages = [pkgs.azos-tex];
    };
  };
}
