#https://xeiaso.net/talks/asg-2023-nixos/ example
{
  lib,
  config,
  pkgs,
  options,
  azos-utils,
  ...
}: let
  isEnabled =
    config.azos.suites.editor.enable;
in {
  options.azos.suites.editor.enable = azos-utils.mkSuiteEnableOption {};

  imports = [
    ./emacs
  ];

  config = lib.mkIf isEnabled {
    home.packages = [pkgs.azos-tex];
  };
}
