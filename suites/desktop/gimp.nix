{...}: {
  config.flake.modules.homeManager.desktop = {
    lib,
    config,
    pkgs,
    ...
  }: {
    config = lib.mkIf config.azos.suites.desktop.enable {
      home.packages = with pkgs; [gimp3];
    };
  };
}
