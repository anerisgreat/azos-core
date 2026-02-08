{inputs, ...}: {
  addpkgs = final: _prev: import ../pkgs {inherit inputs; pkgs = final.pkgs;};
  qutebrowserdrm = final: _prev: {
    qutebrowser = _prev.qutebrowser.override {enableWideVine = true;};
  };
}
