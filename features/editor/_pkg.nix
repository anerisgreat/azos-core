{pkgs}:
pkgs.texliveSmall.withPackages (ps:
  with ps; [
    collection-binextra
    collection-fontsextra
    #Org PDF stuff
    dvisvgm
    dvipng # for preview and export as html
    wrapfig
    amsmath
    ulem
    hyperref
    capt-of
    #Hebrew
    bidi
    babel-hebrew
    cjhebrew
    hebrew-fonts
    #Others
    silence
    algorithm2e
    appendix
    chngcntr
    cleveref
    csquotes
    enumitem
    footmisc
    gensymb
    ntheorem
    titling
    tocbibind
    zref #Page numbering
    transparent #Transparency

    #Exporting
    latexmk
    minted
    braket
    fontawesome
    pygmentex
  ])
