{
  lib,
  config,
  pkgs,
  ...
}: let
  isEnabled =
    config.azos.suites.station.enable;
in {
  config = lib.mkIf isEnabled {
    home.packages = with pkgs; [
      libreoffice
    ];
  };
}
