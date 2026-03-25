{
  lib,
  config,
  pkgs,
  ...
}: let
  isEnabled =
    config.azos.suites.station.enable;
  browserEnabled =
    config.azos.browser.enable;
in {
  options.azos.browser.enable = lib.mkOption {
    default = true;
    type = lib.types.bool;
  };

  config = lib.mkIf (isEnabled && browserEnabled) {
    home.packages = with pkgs; [
      qutebrowser
      chromium
    ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = "qutebrowser.desktop";
        "x-scheme-handler/https" = "qutebrowser.desktop";
        "text/html" = "qutebrowser.desktop";
      };
    };
  };
}
