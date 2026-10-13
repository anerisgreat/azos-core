{
  orgTrivialBuild,
  epkgs,
  pkgs,
}: let
  ghgptel = epkgs.callPackage epkgs.trivialBuild {
    pname = "gptel";
    version = "0.9.9.3";
    src = pkgs.fetchFromGitHub {
      owner = "karthink";
      repo = "gptel";
      rev = "273c0f93958c1ffa85e396717b504903eda36bce";
      sha256 = "sha256-5sdjIiIOJEYzDN9o+iIz0AYdmtbEgbd8uec05BeQhb0=";
    };
  };

  latex-to-svg-backend = epkgs.callPackage epkgs.trivialBuild {
    pname = "latex-to-svg-backend";
    version = "0.8.3";
    src = pkgs.fetchFromGitHub {
      owner = "alberti42";
      repo = "latex-to-svg-backend";
      rev = "bbc7f921aa45716feade13e83bfd562fab219161";
      sha256 = "sha256-OLa6gt/dAAXRC0sUjbvXAk1MXofwZhXWHNEkcy2AqMg=";
    };
  };

  agent-shell-math-renderer = epkgs.callPackage epkgs.trivialBuild {
    pname = "agent-shell-math-renderer";
    version = "0.9.1";
    src = pkgs.fetchFromGitHub {
      owner = "alberti42";
      repo = "agent-shell-math-renderer";
      rev = "d35fb02d2a10cad7fee5fe101f7ca3f4396919fe";
      sha256 = "sha256-LYFpnN5VjJTPIOTeY5Uo+UJ1g86oCpYtU+aWX5ZVE9Q=";
    };
    buildInputs = [
      epkgs.agent-shell
      latex-to-svg-backend
    ];
  };
in
  orgTrivialBuild {
    pname = "azos-emacs-editor";
    version = "0.1.8";
    src = ./config.org;
    packageRequires =
      [
        pkgs.azos-emacs-base
        ghgptel
      ]
      ++ (with epkgs; [
        auctex
        graphviz-dot-mode
        markdown-mode
        markdown-toc
        org-present
        org-roam
        pdf-tools
        pandoc-mode
        agent-shell
        latex-to-svg-backend
        agent-shell-math-renderer
        markdown-table-wrap
        (epkgs.callPackage epkgs.trivialBuild {
          pname = "gptel-autocomplete";
          version = "2025-06-18";
          src = pkgs.fetchFromGitHub {
            owner = "JDNdeveloper";
            repo = "gptel-autocomplete";
            rev = "8ace326a6e7b8a3a4df7a6e80272b472e7fbd167";
            sha256 = "sha256-gVgdFLi6RGUCD3ZXzOIo5XpTNmP/9lMAO5nyWu1zVlM=";
          };
          buildInputs = with epkgs; [
            ghgptel
          ];
        })
      ]);
  }
