{...}: {
  config.flake.overlayPkgs.azos-emacs-chess = pkgs: pkgs.localEmacsPkg ./_pkg.nix;
}
