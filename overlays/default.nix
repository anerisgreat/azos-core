{inputs, ...}: {
  addpkgs = final: _prev: import ../pkgs {pkgs = final;};
}
