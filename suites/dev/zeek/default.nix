{...}: {
  config.flake.modules.homeManager.dev = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.zeek.enable = lib.mkOption {
      default = true;
      example = false;
      type = lib.types.bool;
    };
    config = lib.mkIf (config.azos.zeek.enable && config.azos.suites.dev.enable) {
      home.packages = with pkgs; [zeek];
    };
  };
}
