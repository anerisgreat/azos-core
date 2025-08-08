{lib, ...}: {
  mkFeatureEnableOption = {...} @ attrs:
    lib.mkOption (lib.mergeAttrs attrs {
      default = true;
      example = true;
      type = lib.types.bool;
    });

  mkSuiteEnableOption = {...} @ attrs:
    lib.mkOption (lib.mergeAttrs attrs {
      default = false;
      example = true;
      type = lib.types.bool;
    });

  trivialFromOrg = {...} @ attrs: (
    lib.mergeAttrs attrs {
      preBuild = ''
        for file in ./*.org
        do
            emacs --batch --eval "(require 'org)" --eval "(org-babel-tangle-file \"$file\" (concat (file-name-sans-extension \"$file\") \".el\") \"emacs-lisp\")"
        done
      '';
      unpackCmd = ''
        case "$curSrc" in
          *.el)
            # keep original source filename without the hash
            local filename=$(basename "$curSrc")
            filename="''${filename:33}"
            cp $curSrc $filename
            chmod +w $filename
            sourceRoot="."
            ;;
          *.org)
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
    }
  );
}
