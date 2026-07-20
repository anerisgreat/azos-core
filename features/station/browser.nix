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
      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "x-scheme-handler/http" = "chromium-browser.desktop";
          "x-scheme-handler/https" = "chromium-browser.desktop";
          "text/html" = "chromium-browser.desktop";
        };
      };
    };
  };
}
