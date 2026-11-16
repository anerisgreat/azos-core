{
  orgTrivialBuild,
  epkgs,
  pkgs,
}:
orgTrivialBuild {
  pname = "azos-emacs-github";
  version = "0.1.0";
  src = ./config.org;
  packageRequires = with epkgs; [
    pkgs.azos-emacs-base

    magit
    forge
    ghub
    pr-review
  ];
}
