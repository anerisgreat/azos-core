{azosCoreInputs, ...}: {
  config.flake.overlayPkgs.cabata = pkgs:
    azosCoreInputs.cabata.packages.${pkgs.stdenv.hostPlatform.system}.default;

  config.flake.modules.homeManager.base = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.suites.base.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
    options.azos.name = lib.mkOption {
      default = "YOUR NAME HERE";
      type = lib.types.str;
      description = "Your full name.";
    };
    options.azos.enableBashInstall = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = "Whether to enable bash install.";
    };
    config = lib.mkIf config.azos.suites.base.enable {
      fonts.fontconfig.enable = true;
      programs.bash.enable = config.azos.enableBashInstall;
      home.packages = with pkgs; [
        wget
        curl
        liberation_ttf
        font-awesome
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        fira-code
        fira-code-symbols
        mplus-outline-fonts.githubRelease
        dina-font
        zip
        cabata
        nix-search-cli
      ];
    };
  };
}
