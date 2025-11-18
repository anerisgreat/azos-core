{inputs, ...}: {
  addpkgs = final: _prev: import ../pkgs {pkgs = final.pkgs;};
  qutebrowserdrm = final: _prev: {
    qutebrowser = _prev.qutebrowser.override {enableWideVine = true;};
  };
  overrideEmacsPackages = (import ./overrideEmacsPackages.nix);
}
