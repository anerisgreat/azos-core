{
  lib,
  config,
  pkgs,
  options,
  azos-utils,
  ...
}: {
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
          command = "${pkgs.tuigreet}/bin/tuigreet --time --user-menu --cmd \"/home/\$(whoami)/.login.sh\"";
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
