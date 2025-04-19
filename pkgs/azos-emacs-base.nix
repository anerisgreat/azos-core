{
  orgTrivialBuild,
  epkgs,
  pkgs
}:
orgTrivialBuild {
    pname = "azos-emacs-base";
    version = "0.1.6";
    src = ./elisp/azos-emacs-base.org;
    packageRequires = with epkgs; [
        evil
        evil-collection
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
        dashboard
        vterm
        load-dir
    ];
}
