{...}: {
  config.flake.modules.homeManager.base = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.git.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    config = lib.mkIf (config.azos.git.enable && config.azos.suites.base.enable) {
      programs.git.enable = true;
    };
  };
}
