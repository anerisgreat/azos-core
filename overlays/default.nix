{inputs, ...}: {
  addpkgs = final: _prev: import ../pkgs {pkgs = _prev; };
  qutebrowserdrm = final: _prev: {
    qutebrowser = _prev.qutebrowser.override { enableWideVine = true; }; };
}
