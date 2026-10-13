{...}: {
  config.flake.overlayPkgs.azos-emacs-desktop = pkgs: pkgs.localEmacsPkg ./_pkg.nix;

  config.flake.modules.homeManager.desktop = {
    lib,
    config,
    pkgs,
    ...
  }: {
    config = lib.mkIf (config.azos.emacs.enable && config.azos.suites.desktop.enable) {
      azos.emacs.enabledSuites = ["azos-emacs-desktop"];
      azos.emacs.pkgs = [pkgs.azos-emacs-desktop];
    };
  };
}
