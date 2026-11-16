{...}: {
  config.flake.overlayPkgs.azos-emacs-tailscale = pkgs: pkgs.localEmacsPkg ./_pkg.nix;
}
