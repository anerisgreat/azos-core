{
  orgTrivialBuild,
  epkgs,
  pkgs,
  evil-hl-line,
}:
orgTrivialBuild {
  pname = "azos-emacs-base";
  version = "0.1.7";
  src = ./config.org;
  packageRequires = with epkgs; [
    evil
    evil-collection
    evil-hl-line
    magit
    undo-tree
    ivy
    ivy-hydra
    ivy-avy
    counsel
    counsel-tramp
    counsel-projectile
    swiper
    projectile
    which-key
    yasnippet
    evil-nerd-commenter
    company
    olivetti #FLYCHECK PANDOC
    dired-subtree
    peep-dired
    dashboard
    vterm
    with-editor
    load-dir
    direnv
    csv-mode
  ];
}
