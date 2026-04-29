{
  lib,
  config,
  pkgs,
  azos-utils,
  outputs,
  ...
}: let
  isEnabled =
    config.azos.emacs.enable && config.azos.suites.base.enable;
  emacspkgs = config.azos.emacs.emacspkg.pkgs;
  localPkgName = "azos-emacs-base";
  # This is because of problems with package versions, remove when you can
  # emacsPackageOverrideOverlay = self: super:
  #   {
  #       emacsPackages = super.emacsPackages // {
  #           org = super.org.override {
  #               elpaBuild = args: super.elpaBuild (args // {
  #                   version = "9.27.37";
  #                   src = super.fetchurl {
  #                       url = "https://elpa.gnu.org/packages/org-9.7.37.tar";
  #                       sha256 = "HXugakRVPZ9gWvFHVDlgbrhGrcf1DQT5iJ28wHnIedk";
  #                   };
  #               });
  #           };
  #           exwm = super.exwm.override {
  #               elpaBuild = args: super.elpaBuild (args // {
  #                   version = "0.34";
  #                   src = super.fetchurl {
  #                       url = "https://elpa.gnu.org/packages/exwm-0.34.tar";
  #                       sha256 = "33R9rEiis2HbZefibaLdVUcGv7Fn9HLEEcYuw1K04sI";
  #                   };
  #               });
  #           };
  #       };
  #   };
in {
  options.azos.emacs.enable = azos-utils.mkFeatureEnableOption {
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
    description =
      "List of enabled suite names for Emacs. Used to enable the "
      + "custom packages in init.el.";
  };

  #Set config
  config = lib.mkIf isEnabled {
    #Base emacs suite definition
    azos.emacs.pkgs = [pkgs.azos-emacs-base];

    azos.emacs.enabledSuites = [localPkgName];

    # Use emacsclient as the default editor.
    # In terminal contexts (EDITOR) open a TUI frame; in GUI contexts (VISUAL) open a GUI frame.
    # Falls back to starting a standalone emacs if no server is available.
    home.sessionVariables = {
      EDITOR = "emacsclient -t -a emacs";
      VISUAL = "emacsclient -c -a emacs";
    };

    # Run emacs as a persistent daemon so emacsclient can always connect.
    # When EXWM is active, emacs is the X session itself and calls server-start
    # directly, so no separate daemon is needed.
    services.emacs = lib.mkIf (!config.azos.suites.exwm.enable) {
      enable = true;
    };

    #Global instantiation of Emacs
    programs.emacs = {
      enable = true;
      # package = (pkgs.emacsPackagesFor config.azos.emacs.emacspkg).emacsWithPackages (
      #   config.azos.emacs.pkgs
      # );
      package =
        (
          pkgs.emacsPackagesFor config.azos.emacs.emacspkg
        ).emacsWithPackages (
          config.azos.emacs.pkgs
        );

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
}
