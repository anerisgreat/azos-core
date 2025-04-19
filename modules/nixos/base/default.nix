{ lib, config, pkgs, options, azos-utils, ... }:
{
  config = {

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
                command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --user-menu --cmd ${pkgs.xorg.xinit}/bin/startx";
                user = "greeter";
            };
        };
    };

    environment.systemPackages = with pkgs; [
        xorg.xinit
        greetd.tuigreet
        xlayoutdisplay
        xorg.xrandr
        xorg.xcbutil
        xorg.libxcb
    ];

  };
}
