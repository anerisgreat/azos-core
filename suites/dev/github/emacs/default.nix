{...}: {
  config.flake.overlayPkgs.azos-emacs-github = pkgs: pkgs.localEmacsPkg ./_pkg.nix;
}
