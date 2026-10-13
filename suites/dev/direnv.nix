{...}: {
  config.flake.modules.homeManager.dev = {
    lib,
    config,
    ...
  }: {
    options.azos.direnv.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    config = lib.mkIf (config.azos.direnv.enable && config.azos.suites.dev.enable) {
      programs.direnv = {
        enable = true;
        enableBashIntegration = true;
        nix-direnv.enable = true;
      };
    };
  };
}
