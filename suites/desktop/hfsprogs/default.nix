{...}: {
  config.flake.modules.nixos.desktop = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.hfsprogs.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };
    config = lib.mkIf config.azos.hfsprogs.enable {
      environment.systemPackages = with pkgs; [hfsprogs];
    };
  };
}
