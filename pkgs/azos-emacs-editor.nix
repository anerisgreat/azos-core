{
  orgTrivialBuild,
  epkgs,
  pkgs
}:
orgTrivialBuild {
    pname = "azos-emacs-editor";
    version = "0.1.6";
    src = ./elisp/azos-emacs-editor.org;
    packageRequires = with epkgs; [
        pkgs.azos-emacs-base

        graphviz-dot-mode
        markdown-mode
        markdown-toc
        org-present
        pdf-tools
        pandoc-mode
    ];
}
