{
  orgTrivialBuild,
  epkgs,
  pkgs,
}: let
  pcap-mode = epkgs.callPackage epkgs.trivialBuild {
    pname = "pcap-mode";
    version = "0.2";
    src = pkgs.fetchFromGitHub {
      owner = "apconole";
      repo = "pcap-mode";
      rev = "52780669af0ade136f84d73f21b4dbb7ab655416";
      sha256 = "sha256-SMt7hLCzerqzTJDqC5ztFqHRgxei/pUBU8NjoCVDQew=";
    };
  };
in
  orgTrivialBuild {
    pname = "azos-emacs-dev";
    version = "0.1.8";
    src = ./config.org;
    packageRequires =
      [
        pcap-mode
      ]
      ++ (with epkgs; [
        cmake-mode
        package-lint
        yaml
        yaml-mode
        nix-mode
        python
        rust-mode
        toml-mode
        flycheck-rust
        ein
        ob-async
        flycheck
        irony
        flycheck-irony
        pyvenv-auto
        pet
        flymake-ruff
        pkgs.azos-emacs-base
        pkgs.azos-emacs-editor
      ]);
  }
