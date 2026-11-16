{...}: {
  config.flake.overlayPkgs.azos-emacs-mermaid = pkgs: pkgs.localEmacsPkg ./_pkg.nix;
}
