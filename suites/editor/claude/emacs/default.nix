{...}: {
  config.flake.overlayPkgs.azos-emacs-claude = pkgs: pkgs.localEmacsPkg ./_pkg.nix;
}
