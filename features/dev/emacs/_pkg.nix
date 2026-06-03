{
  orgTrivialBuild,
  epkgs,
  pkgs,
}:
orgTrivialBuild {
  pname = "azos-emacs-dev";
  version = "0.1.7";
  src = ./config.org;
  packageRequires = with epkgs; [
    cmake-mode
    package-lint
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
    pyvenv-auto
    pet
    flymake-ruff
    pkgs.azos-emacs-base
    pkgs.azos-emacs-editor
  ];
}
