{...}: {
  config.flake.modules.homeManager.dev = {
    lib,
    config,
    ...
  }: {
    options.azos.suites.dev.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
  };
}
