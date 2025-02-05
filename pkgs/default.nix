{ pkgs } @ args:
let
  inherit args;
  emacs-pkg = pkgs.emacs;
  epkgs = emacs-pkg.pkgs;
  trivialBuild = epkgs.trivialBuild;
  orgTrivialBuild = attrs : (trivialBuild (pkgs.lib.mergeAttrs attrs {
    preBuild = ''
        for file in ./*.org
        do
            emacs --batch --eval "(require 'org)" --eval "(org-babel-tangle-file \"$file\" (concat (file-name-sans-extension \"$file\") \".el\") \"emacs-lisp\")"
        done
        '';
    unpackCmd = ''
        case "$curSrc" in
        *.el | *.org)
            # keep original source filename without the hash
            local filename=$(basename "$curSrc")
            filename="''${filename:33}"
            cp $curSrc $filename
            chmod +w $filename
            sourceRoot="."
            ;;
        *)
            _defaultUnpack "$curSrc"
            ;;
        esac
        '';
  }));
  localEmacsPkg = (src: pkgs.callPackage src { orgTrivialBuild = orgTrivialBuild; epkgs = epkgs; pkgs = pkgs; });
in
{
  azos.emacs.base = localEmacsPkg ./azos-emacs-base.nix;
  azos.emacs.editor = localEmacsPkg ./azos-emacs-editor.nix;
  azos.emacs.dev = localEmacsPkg ./azos-emacs-dev.nix;
  azos.emacs.station = localEmacsPkg ./azos-emacs-station.nix;
  azos.emacs.exwm = localEmacsPkg ./azos-emacs-exwm.nix;
  azos.tex = pkgs.callPackage ./azos-tex.nix { pkgs = pkgs; };
  # azos.fetchmail = pkgs.callPackage ./azos-fetchmail.nix { pkgs = pkgs; };
}
