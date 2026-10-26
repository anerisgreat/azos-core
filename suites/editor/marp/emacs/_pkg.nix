{
  orgTrivialBuild,
  epkgs,
  pkgs,
}:
orgTrivialBuild {
  pname = "azos-emacs-marp";
  version = "0.1.0";
  src = ./config.org;
  packageRequires = with epkgs; [
    pkgs.azos-emacs-base
    markdown-mode
  ];
}
