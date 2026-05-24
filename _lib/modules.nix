{lib, ...}: {
  options.flake.modules = {
    homeManager = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = {};
      description = "Home-manager module groups, keyed by feature name.";
    };
    nixos = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.deferredModule;
      default = {};
      description = "NixOS module groups, keyed by feature name.";
    };
  };
  options.flake.overlayPkgs = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.functionTo lib.types.anything);
    default = {};
    description = "Packages contributed to the addpkgs overlay. Each value is a function pkgs -> drv.";
  };
}
