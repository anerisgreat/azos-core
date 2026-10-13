{
  orgTrivialBuild,
  epkgs,
  pkgs,
}:
orgTrivialBuild {
  pname = "azos-emacs-chess";
  version = "0.1.0";
  src = ./config.org;
  packageRequires = with epkgs; [
    pkgs.azos-emacs-base
    pkgs.emacs-lichess
  ];
}
