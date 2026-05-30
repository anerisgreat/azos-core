{azosCoreInputs, ...}: {
  config.flake.overlayPkgs.evil-hl-line = pkgs:
    azosCoreInputs.evil-hl-line.packages.${pkgs.stdenv.hostPlatform.system}.default;

  config.flake.overlayPkgs.azos-emacs-orgTrivialBuild = pkgs: let
    epkgs = pkgs.emacs.pkgs;
    trivialBuild = epkgs.trivialBuild;
  in
    attrs:
      trivialBuild (pkgs.lib.mergeAttrs attrs {
        preBuild = ''
          for file in ./*.org
          do
              emacs --batch --eval "(require 'org)" --eval "(org-babel-tangle-file \"$file\" \"${attrs.pname}.el\" \"emacs-lisp\")"
          done
        '';
        unpackCmd = ''
          case "$curSrc" in
          *.el | *.org)
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
      });

  config.flake.overlayPkgs.localEmacsPkg = pkgs: src:
    pkgs.callPackage src {
      orgTrivialBuild = pkgs.azos-emacs-orgTrivialBuild;
      epkgs = pkgs.emacs.pkgs;
      inherit pkgs;
    };

  config.flake.overlayPkgs.azos-emacs-base = pkgs:
    pkgs.callPackage ./_pkg.nix {
      orgTrivialBuild = pkgs.azos-emacs-orgTrivialBuild;
      epkgs = pkgs.emacs.pkgs;
      inherit pkgs;
      evil-hl-line = pkgs.evil-hl-line;
    };

  config.flake.modules.homeManager.base = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.emacs.enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Enables EMACS installation.";
    };
    options.azos.emacs.emacspkg = lib.mkOption {
      type = lib.types.package;
      default = pkgs.emacs;
      description = "The base package to use for Emacs.";
    };
    options.azos.emacs.pkgs = lib.mkOption {
      default = [];
      description = "List of packages for Emacs.";
    };
    options.azos.emacs.enabledSuites = lib.mkOption {
      default = [];
      description = "List of enabled suite names for Emacs.";
    };

    config = lib.mkIf (config.azos.emacs.enable && config.azos.suites.base.enable) {
      azos.emacs.pkgs = [pkgs.azos-emacs-base];
      azos.emacs.enabledSuites = ["azos-emacs-base"];

      home.sessionVariables = {
        EDITOR = "emacsclient -t -a emacs";
        VISUAL = "emacsclient -c -a emacs";
      };

      services.emacs = lib.mkIf (!config.azos.suites.exwm.enable) {
        enable = true;
      };

      programs.emacs = {
        enable = true;
        package =
          (pkgs.emacsPackagesFor config.azos.emacs.emacspkg).emacsWithPackages
          config.azos.emacs.pkgs;
        extraConfig =
          (lib.strings.concatStringsSep "\n"
            (builtins.map (s: "(require '" + s + ")\n")
              config.azos.emacs.enabledSuites))
          + ''
            (use-package load-dir
              :config (setq load-dirs (concat user-emacs-directory "extra/")))
          '';
      };
    };
  };
}
