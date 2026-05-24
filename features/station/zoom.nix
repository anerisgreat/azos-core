{...}: {
  config.flake.modules.homeManager.station = {
    lib,
    config,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.azos.suites.station.enable {
      home.packages = with pkgs; [zoom-us];
    };
  };
}
