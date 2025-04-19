#https://xeiaso.net/talks/asg-2023-nixos/ example
#https://gist.github.com/rycee/1ad8654856ce8519f2270b18d27b76d5
{ lib, config, pkgs, options, azos-utils, ... }:
let
  isEnabled =
    config.azos.suites.exwm.enable;
in
{
  options.azos.suites.exwm.enable = (azos-utils.mkSuiteEnableOption {});

  imports = [
    ./emacs
  ];

  #TODO shutdown reboot commands
  config = lib.mkIf isEnabled {
    home.packages = with pkgs; [ ];
    home.file.".xinitrc" = {text = ''
exec emacs --start-exwm
'' ; };

  };
}
