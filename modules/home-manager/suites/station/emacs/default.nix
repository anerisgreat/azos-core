{ lib, config, pkgs, azos-utils, ... }:
let
  isEnabled =
    config.azos.emacs.enable && config.azos.suites.station.enable;
  emacspkgs = config.azos.emacs.emacspkg.pkgs;

  localPkgName = "azos-emacs-station";
in
{
  #Set config
  config = lib.mkIf isEnabled {

    azos.emacs.enabledSuites = [localPkgName];

    azos.emacs.pkgs = [pkgs.azos.emacs.station];
  };

}
