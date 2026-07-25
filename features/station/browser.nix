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
      home.packages = with pkgs; [qutebrowser];
      programs.chromium = {
        enable = true;
        package = pkgs.chromium;
        extensions = [
          {id = "hfjbmagddngcpeloejdejnfgbamkjaeg";} # Vimium-C
        ];
      };
      xdg.desktopEntries.chromium-app = {
        name = "Chromium (App Mode)";
        exec = "chromium --app=%u";
        icon = "chromium";
        categories = ["Network" "WebBrowser"];
        mimeType = ["x-scheme-handler/http" "x-scheme-handler/https" "text/html"];
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/http" = "chromium-app.desktop";
          "x-scheme-handler/https" = "chromium-app.desktop";
          "text/html" = "chromium-app.desktop";
        };
      };
    };
  };
}
