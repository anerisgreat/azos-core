{
  orgTrivialBuild,
  epkgs,
  pkgs,
}:
let ghgptel = (epkgs.callPackage epkgs.trivialBuild {
      pname = "gptel";
      version = "0.9.9.3";
      src = pkgs.fetchFromGitHub {
        owner = "karthink";
        repo = "gptel";
        rev = "273c0f93958c1ffa85e396717b504903eda36bce"; # Use a specific commit hash for reproducibility
        sha256 = "sha256-gVgdFLi6RGUCD3ZXzOIo5XpTNmP/9xMAO5nyWu1zVlM=";
      };
    });
in orgTrivialBuild {
  pname = "azos-emacs-editor";
  version = "0.1.6";
  src = ./elisp/azos-emacs-editor.org;
  packageRequires = with epkgs; [
    pkgs.azos-emacs-base

    graphviz-dot-mode
    markdown-mode
    markdown-toc
    org-present
    pdf-tools
    pandoc-mode
    ghgptel
    (epkgs.callPackage epkgs.trivialBuild {
      pname = "gptel-autocomplete";
      version = "2025-06-18";
      src = pkgs.fetchFromGitHub {
        owner = "JDNdeveloper";
        repo = "gptel-autocomplete";
        rev = "8ace326a6e7b8a3a4df7a6e80272b472e7fbd167"; # Use a specific commit hash for reproducibility
        sha256 = "sha256-gVgdFLi6RGUCD3ZXzOIo5XpTNmP/9lMAO5nyWu1zVlM=";
      };
      buildInputs = with epkgs; [
        ghgptel
      ];
    })
    (epkgs.callPackage epkgs.trivialBuild {
      pname = "gptel-agent";
      version = "0.0.1";
      src = pkgs.fetchFromGitHub {
        owner = "karthink";
        repo = "gptel-agent";
        rev = "8ba9056da2341468192e6417d47cb50e26636e97"; # Use a specific commit hash for reproducibility
        sha256 = "sha256-M2J/K3UHoAbDWQjYPD8ZdL6uHBggvPh+ZvJ+xnbXJuo=";
      };
      buildInputs = with epkgs; [
        ghgptel
      ];
    })
  ];
}
