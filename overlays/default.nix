{inputs, ...}: {
  addpkgs = final: _prev: import ../pkgs {pkgs = final;};
  qutebrowserdrm = final: _prev: {
    qutebrowser = _prev.qutebrowser.override { enableWideVine = true; }; };
}
