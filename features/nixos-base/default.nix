{...}: {
  config.flake.modules.nixos.base = {
    lib,
    config,
    pkgs,
    ...
  }: {
    config = {
      services.xserver = {
        enable = true;
        autorun = false;
        exportConfiguration = true;
        displayManager.startx.enable = true;
      };
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --user-menu --cmd '/home/$(whoami)/.login.sh'";
            user = "greeter";
          };
        };
      };
      environment.systemPackages = with pkgs; [
        xdg-utils
        xinit
        tuigreet
        xlayoutdisplay
        xrandr
        libxcb-util
        libxcb
        libxcb.dev
      ];
    };
  };
}
