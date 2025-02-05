{ lib, config, pkgs, azos-utils, ... }:
let
  isEnabled =
    config.azos.emacs.enable && config.azos.suites.dev.enable;
  emacspkgs = config.azos.emacs.emacspkg.pkgs;
  localPkgName = "azos-emacs-dev";
in
{
  #Set config
  config = lib.mkIf isEnabled {

    #Base emacs suite definition
    azos.emacs.pkgs = [pkgs.azos.emacs.dev];

    azos.emacs.enabledSuites = [localPkgName];
  };
}
