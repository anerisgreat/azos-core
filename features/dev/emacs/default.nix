{...}: {
  config.flake.overlayPkgs.azos-emacs-dev = pkgs: pkgs.localEmacsPkg ./_pkg.nix;

  config.flake.modules.homeManager.dev = {
    lib,
    config,
    pkgs,
    ...
  }: {
    config = lib.mkIf (config.azos.emacs.enable && config.azos.suites.dev.enable) {
      azos.emacs.pkgs = [pkgs.azos-emacs-dev];
      azos.emacs.enabledSuites = ["azos-emacs-dev"];
    };
  };
}
