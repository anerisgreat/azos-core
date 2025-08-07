{ lib, config, pkgs, azos-utils, ... }:
let
  isEnabled =
    config.azos.emacs.enable && config.azos.suites.exwm.enable;
  emacspkgs = config.azos.emacs.emacspkg.pkgs;
  localPkgName = "azos-emacs-exwm";
in
{
  #Set config
  config = lib.mkIf isEnabled {

    azos.emacs.enabledSuites = [localPkgName];

    #Base emacs suite definition
    azos.emacs.pkgs = [pkgs.azos-emacs-exwm];

    # home.file.".xinitrc".text = ''exec emacs'';
  };
}
