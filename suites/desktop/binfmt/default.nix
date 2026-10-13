{...}: {
  config.flake.modules.nixos.desktop = {
    lib,
    config,
    ...
  }: {
    options.azos.binfmt.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    config = lib.mkIf config.azos.binfmt.enable {
      boot.binfmt.emulatedSystems = ["aarch64-linux"];
    };
  };
}
