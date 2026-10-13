{...}: {
  config.flake.overlayPkgs.azos-emacs-exwm = pkgs: pkgs.localEmacsPkg ./_pkg.nix;

  config.flake.modules.homeManager.exwm = {
    lib,
    config,
    pkgs,
    ...
  }: {
    config = lib.mkIf (config.azos.emacs.enable && config.azos.suites.exwm.enable) {
      azos.emacs.enabledSuites = ["azos-emacs-exwm"];
      azos.emacs.pkgs = [pkgs.azos-emacs-exwm];
    };
  };
}
