{...}: {
  config.flake.modules.nixos.desktop = {
    lib,
    config,
    ...
  }: {
    options.azos.bluetooth.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    config = lib.mkIf config.azos.bluetooth.enable {
      services.blueman.enable = true;
      hardware.bluetooth.enable = true;
      environment.etc."bluetooth/input.conf" = lib.mkForce {
        text = ''
          [General]
          ClassicBondedOnly=false
        '';
      };
    };
  };
}
