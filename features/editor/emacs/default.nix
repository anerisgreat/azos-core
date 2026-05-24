{...}: {
  config.flake.overlayPkgs.azos-emacs-editor = pkgs: pkgs.localEmacsPkg ./_pkg.nix;

  config.flake.modules.homeManager.editor = {
    lib,
    config,
    pkgs,
    ...
  }: {
    config = lib.mkIf (config.azos.emacs.enable && config.azos.suites.dev.enable) {
      azos.emacs.pkgs = [pkgs.azos-emacs-base];
      azos.emacs.enabledSuites = ["azos-emacs-editor"];
      azos.python.pkgs = with config.azos.python.pythonpkg.pkgs; [graphviz pygments];
    };
  };
}
