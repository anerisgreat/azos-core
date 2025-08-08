{
  orgTrivialBuild,
  epkgs,
  pkgs,
}:
orgTrivialBuild {
  pname = "azos-emacs-station";
  version = "0.1.6";
  src = ./elisp/azos-emacs-station.org;
  packageRequires = with epkgs; [
    pkgs.azos-emacs-base

    notmuch #TODO CHECK, ALSO FOR THIS CONFIGURE ALL PACKAGES N STUFF
    elfeed #PROBABLY ALSO BUILT IN
    elfeed-tube
    pass
    scad-mode
    kubernetes
  ];
}
