{
  orgTrivialBuild,
  epkgs,
  pkgs,
}:
orgTrivialBuild {
  pname = "azos-emacs-dev";
  version = "0.1.6";
  src = ./elisp/azos-emacs-dev.org;
  packageRequires = with epkgs; [
    cmake-mode
    yaml
    yaml-mode
    nix-mode
    python
    rust-mode
    toml-mode
    flycheck-rust
    ein
    ob-async
    flycheck
    irony
    flycheck-irony
    pkgs.azos-emacs-base
    pkgs.azos-emacs-editor
  ];
}
