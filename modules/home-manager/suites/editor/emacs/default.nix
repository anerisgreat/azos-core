{ lib, config, pkgs, azos-utils, ... }:
let
  isEnabled =
    config.azos.emacs.enable && config.azos.suites.dev.enable;
  emacspkgs = config.azos.emacs.emacspkg.pkgs;
  pythonpkgs = config.azos.python.pythonpkg.pkgs;
  localPkgName = "azos-emacs-editor";
in
{
  #Set config
  config = lib.mkIf isEnabled {

    #Base emacs suite definition
    azos.emacs.pkgs = [pkgs.azos.emacs.base];

    azos.emacs.enabledSuites = [localPkgName];

    azos.python.pkgs = with pythonpkgs; [ graphviz pygments ];
  };

}
