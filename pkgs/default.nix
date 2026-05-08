{
  pkgs,
  inputs,
} @ args: let
  inherit args;
  emacs-pkg = pkgs.emacs;
  epkgs = emacs-pkg.pkgs;
  trivialBuild = epkgs.trivialBuild;
  orgTrivialBuild = attrs: (trivialBuild (pkgs.lib.mergeAttrs attrs {
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
  localEmacsPkg = src:
    pkgs.callPackage src {
      orgTrivialBuild = orgTrivialBuild;
      epkgs = epkgs;
      pkgs = pkgs;
    };
  customCommand = commandName: command:
    pkgs.stdenv.mkDerivation rec {
      pname = commandName;
      version = "1.0";

      src = pkgs.writeText "${commandName}-script" ''
        #!${pkgs.bash}/bin/bash
        ${command}
      '';

      # Define the installation phase
      installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/mycommand
        chmod +x $out/bin/mycommand
      '';

      phases = ["installPhase"];
    };
  evil-hl-line = trivialBuild {
    pname = "evil-hl-line";
    version = "0.1.0";
    src = inputs.evil-hl-line;
    packageRequires = with epkgs; [evil];
  };
in {
  azos-emacs-orgTrivialBuild = orgTrivialBuild;
  azos-emacs-base = pkgs.callPackage ./azos-emacs-base.nix {
    orgTrivialBuild = orgTrivialBuild;
    epkgs = epkgs;
    pkgs = pkgs;
    evil-hl-line = evil-hl-line;
  };
  azos-emacs-editor = localEmacsPkg ./azos-emacs-editor.nix;
  azos-emacs-dev = localEmacsPkg ./azos-emacs-dev.nix;
  azos-emacs-station = localEmacsPkg ./azos-emacs-station.nix;
  azos-emacs-exwm = localEmacsPkg ./azos-emacs-exwm.nix;
  azos-tex = pkgs.callPackage ./azos-tex.nix {pkgs = pkgs;};
  localEmacsPkg = localEmacsPkg;
  customCommand = customCommand;
  cabata = inputs.cabata.packages.${pkgs.stdenv.hostPlatform.system}.default;
}
