#https://xeiaso.net/talks/asg-2023-nixos/ example
{ lib, config, pkgs, azos-utils, ... }:
let
  isEnabled =
    config.azos.direnv.enable && config.azos.suites.dev.enable;
in
{
  options.azos.direnv.enable = (azos-utils.mkFeatureEnableOption {});

  config = lib.mkIf isEnabled {
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
