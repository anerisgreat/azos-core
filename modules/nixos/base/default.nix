{
  lib,
  config,
  pkgs,
  options,
  azos-utils,
  ...
}: let
   isEnabled =
        config.azos.nixos.greetd-startx.enable;
in {
  options.azos.nixos.greetd-startx.enable = azos-utils.mkFeatureEnableOption {};

  config = lib.mkIf isEnabled {
    services.xserver = {
      enable = true;
      autorun = false;
      exportConfiguration = true;
      # layout = "gb";
      displayManager.startx.enable = true;
    };
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --user-menu --cmd ${pkgs.xorg.xinit}/bin/startx";
          user = "greeter";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      xdg-utils
      xorg.xinit
      tuigreet
      xlayoutdisplay
      xorg.xrandr
      xorg.xcbutil
      xorg.libxcb
      xorg.libxcb.dev
    ];
  };
}
