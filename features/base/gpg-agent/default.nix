{...}: {
  config.flake.modules.homeManager.base = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.gpgagent.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    config = lib.mkIf (config.azos.gpgagent.enable && config.azos.suites.base.enable) {};
  };
}
