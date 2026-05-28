{...}: {
  config.flake.modules.homeManager.exwm = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.suites.exwm.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
    config = lib.mkIf config.azos.suites.exwm.enable {
      azos.suites.base.enable = lib.mkDefault true;
      azos.suites.station.enable = lib.mkDefault true;

      home.packages = with pkgs; [ffmpeg-full imv];
      xdg.mimeApps.defaultApplications = {"image/gif" = "imv.desktop";};
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
        executable = true;
      };
    };
  };

  config.flake.modules.nixos.exwm = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.suites.exwm.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
    config = lib.mkMerge [
      (lib.mkIf config.azos.suites.exwm.enable {
        services.udisks2.enable = true;
      })
      {
        warnings = lib.optionals (!config.azos.suites.exwm.enable) (
          lib.concatLists (lib.mapAttrsToList
            (user: userCfg:
              lib.optional userCfg.azos.suites.exwm.enable
              "azos.suites.exwm is enabled for home-manager user '${user}' but disabled at the NixOS level. udisks2 will not be available.")
            config.home-manager.users)
        );
      }
    ];
  };
}
