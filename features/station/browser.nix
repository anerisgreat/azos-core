{...}: {
  config.flake.modules.homeManager.station = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.browser.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    config = lib.mkIf (config.azos.suites.station.enable && config.azos.browser.enable) {
      home.packages = with pkgs; [qutebrowser chromium];
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/http" = "org.qutebrowser.qutebrowser.desktop";
          "x-scheme-handler/https" = "org.qutebrowser.qutebrowser.desktop";
          "text/html" = "org.qutebrowser.qutebrowser.desktop";
        };
      };
    };
  };
}
