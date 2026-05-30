{
  config,
  lib,
  ...
}: {
  config.flake.overlays.addpkgs = final: _prev:
    lib.mapAttrs (_: f: f final) config.flake.overlayPkgs;

  config.flake.overlays.qutebrowserdrm = _final: prev: {
    qutebrowser = prev.qutebrowser.override {enableWideVine = true;};
  };
}
