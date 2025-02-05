{
  pkgs
}:
(pkgs.texlive.combine {
          inherit (pkgs.texlive)
            scheme-small
            collection-binextra
            collection-fontsextra

            #Org PDF stuff
            dvisvgm dvipng # for preview and export as html
            wrapfig amsmath ulem hyperref capt-of

            #Hebrew
            bidi babel-hebrew cjhebrew hebrew-fonts

            #Others
            zref #Page numbering
            transparent #Transparency

            #Exporting
            latexmk
            minted braket
            fontawesome
            pygmentex;
        })
