{
  orgTrivialBuild,
  epkgs,
  pkgs,
}:
orgTrivialBuild {
  pname = "azos-emacs-jinja";
  version = "0.1.0";
  src = ./config.org;
  packageRequires = with epkgs; [
    pkgs.azos-emacs-base

    jinja2-mode
    flycheck
  ];
}
