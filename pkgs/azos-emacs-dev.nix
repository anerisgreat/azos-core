{
  orgTrivialBuild,
  epkgs,
  pkgs
}:
orgTrivialBuild {
    pname = "azos-emacs-dev";
    version = "0.1.6";
    src = ./elisp/azos-emacs-dev.org;
    packageRequires = with epkgs; [
        flycheck
        cmake-mode
        yaml
        yaml-mode
        nix-mode
        python
        rust-mode
        ein
        ob-async
        pkgs.azos.emacs.base
        pkgs.azos.emacs.editor
    ];
}
