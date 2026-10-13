{...}: {
  config.flake.overlayPkgs.emacs-lichess = pkgs: let
    epkgs = pkgs.emacs.pkgs;
  in
    epkgs.trivialBuild {
      pname = "lichess";
      version = "1.0";
      src = pkgs.fetchFromGitHub {
        owner = "tmythicator";
        repo = "lichess.el";
        rev = "572a6a353e2113c8a95564b9bea1f2896e6d3dab";
        sha256 = "1d87qjmdpizggkrzq39i9vqgvbpjf5mv97vm7zy28ksbqxmfasqa";
      };
      # trivialBuild's installPhase only installs *.el/*.elc; the piece SVGs
      # under assets/ must be copied alongside so the default
      # lichess-board-gui-asset-path (relative to the installed .el file) resolves.
      postInstall = ''
        cp -r assets $out/share/emacs/site-lisp/
      '';
    };

  config.flake.modules.homeManager.editor = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.chess.enable = lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
    };

    config = lib.mkIf config.azos.chess.enable {
      azos.emacs.pkgs = [pkgs.azos-emacs-chess];
      azos.emacs.enabledSuites = ["azos-emacs-chess"];
    };
  };
}
