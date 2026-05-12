#https://xeiaso.net/talks/asg-2023-nixos/ example
#https://gist.github.com/rycee/1ad8654856ce8519f2270b18d27b76d5
{
  lib,
  config,
  pkgs,
  options,
  azos-utils,
  ...
}: let
  isEnabled =
    config.azos.suites.exwm.enable;
in {
  options.azos.suites.exwm.enable = azos-utils.mkSuiteEnableOption {};

  imports = [
    ./emacs
  ];

  #TODO shutdown reboot commands
  config = lib.mkIf isEnabled {
    home.packages = with pkgs; [ffmpeg-full imv];

    xdg.mimeApps.defaultApplications = {
      "image/gif" = "imv.desktop";
    };

    services.udiskie = {
      enable = true;
      tray = "never";
    };

    home.file.".xinitrc" = {
      text = ''
        systemctl --user import-environment DISPLAY XAUTHORITY
        exec emacs
      '';
    };

    home.file.".login.sh" = {
      text = ''
        #!/usr/bin/env bash
        ${pkgs.xinit}/bin/startx
      '';
      #Make executable
      executable = true;
    };
  };
}
