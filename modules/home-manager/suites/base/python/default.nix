{
  lib,
  config,
  pkgs,
  azos-utils,
  ...
}: let
  isEnabled =
    config.azos.python.enable && config.azos.suites.base.enable;
  pythonpkgs = config.azos.python.pythonpkg.pkgs;
in {
  options.azos.python.enable = azos-utils.mkFeatureEnableOption {};

  options.azos.python.pythonpkg = lib.mkOption {
    type = lib.types.package;
    default = pkgs.python3;
  };

  options.azos.python.pkgs = lib.mkOption {
    default = [];
    description = "List of packages for python.";
  };

  config = lib.mkIf isEnabled {
    home.packages = with pkgs; [
      (config.azos.python.pythonpkg.withPackages (python-pkgs: config.azos.python.pkgs))
    ];
  };

  imports = [
  ];
}
