{
  lib,
  config,
  pkgs,
  azos-utils,
  ...
}: let
  isEnabled =
    config.azos.git.enable
    && config.azos.suites.base.enable;
in {
  options.azos.git.enable = azos-utils.mkFeatureEnableOption {};

  config = lib.mkIf isEnabled {
    programs.git.enable = true;
  };
}
