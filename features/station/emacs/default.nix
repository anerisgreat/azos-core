{...}: {
  config.flake.overlayPkgs.azos-emacs-station = pkgs: pkgs.localEmacsPkg ./_pkg.nix;

  config.flake.modules.homeManager.station = {
    lib,
    config,
    pkgs,
    ...
  }: {
    config = lib.mkIf (config.azos.emacs.enable && config.azos.suites.station.enable) {
      azos.emacs.enabledSuites = ["azos-emacs-station"];
      azos.emacs.pkgs = [pkgs.azos-emacs-station];
    };
  };
}
