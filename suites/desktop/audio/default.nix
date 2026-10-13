{...}: {
  config.flake.modules.homeManager.desktop = {
    lib,
    config,
    ...
  }: {
    options.azos.home-audio.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    config = lib.mkIf config.azos.home-audio.enable {};
  };

  config.flake.modules.nixos.desktop = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.hardware-audio.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    config = lib.mkIf config.azos.hardware-audio.enable {
      services = {
        pipewire = {
          enable = true;
          audio.enable = true;
          pulse.enable = true;
          alsa = {
            enable = true;
            support32Bit = true;
          };
          jack.enable = true;
        };
      };
      environment.systemPackages = with pkgs; [pavucontrol];
      musnix.enable = true;
    };
  };
}
