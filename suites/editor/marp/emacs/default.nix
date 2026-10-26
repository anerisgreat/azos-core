{...}: {
  config.flake.overlayPkgs.azos-emacs-marp = pkgs: pkgs.localEmacsPkg ./_pkg.nix;
}
