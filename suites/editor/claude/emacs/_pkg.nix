{
  orgTrivialBuild,
  epkgs,
  pkgs,
}: let
  # Not on MELPA/nixpkgs: the Claude Code CLI in a vterm buffer, bridged to
  # Emacs over MCP (diagnostics, xref, ediff diffs, selection).
  claude-code-ide = epkgs.callPackage epkgs.trivialBuild {
    pname = "claude-code-ide";
    version = "0.3.0";
    src = pkgs.fetchFromGitHub {
      owner = "manzaltu";
      repo = "claude-code-ide.el";
      rev = "50a3d55262805d7207889ed429ff30da96fbf68b";
      hash = "sha256-u+87PjLh0Mc7C8nvDG758rdgpmjED8G/hO+FE1tj7DU=";
    };
    preBuild = "rm -f claude-code-ide-tests.el";
    packageRequires = with epkgs; [
      websocket
      transient
      web-server
      vterm
    ];
  };
in
  orgTrivialBuild {
    pname = "azos-emacs-claude";
    version = "0.1.0";
    src = ./config.org;
    packageRequires = with epkgs; [
      pkgs.azos-emacs-base
      pkgs.azos-emacs-editor

      agent-shell
      claude-code-ide
    ];
  }
