{
  orgTrivialBuild,
  epkgs,
  pkgs,
}:
orgTrivialBuild {
  pname = "azos-emacs-station";
  version = "0.1.6";
  src = ./config.org;
  packageRequires = with epkgs; [
    pkgs.azos-emacs-base

    mu4e
    elfeed #PROBABLY ALSO BUILT IN
    elfeed-tube
    pass
    scad-mode
    kubernetes
    wttrin
  ];
}
