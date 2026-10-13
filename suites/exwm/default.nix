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

      # EDNC (Emacs Desktop Notification Center) runs as the notification
      # daemon instead — see azos-core/suites/exwm/emacs/config.org.
      services.dunst.enable = lib.mkForce false;

      # libnotify's notify-send is the standard way for arbitrary scripts
      # (not just Emacs itself) to post to the org.freedesktop.Notifications
      # bus that EDNC serves -- without it nothing outside Emacs has a
      # straightforward way to raise a desktop notification.
      # playerctl is what desktop-environment's music commands shell out to
      # (see the XF86Audio{Play,Stop,Prev,Next} bindings in
      # exwm/emacs/config.org) -- Spotify's Linux client exposes an MPRIS
      # D-Bus interface, so playerctl drives it the same as any other player.
      home.packages = with pkgs; [ffmpeg-full imv xkb-switch libnotify playerctl];
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
