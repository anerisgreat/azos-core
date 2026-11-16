{...}: {
  config.flake.overlayPkgs.azos-emacs-jinja = pkgs: pkgs.localEmacsPkg ./_pkg.nix;
}
