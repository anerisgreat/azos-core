#https://xeiaso.net/talks/asg-2023-nixos/ example
{
  lib,
  config,
  pkgs,
  options,
  azos-utils,
  ...
}: let
  isEnabled =
    config.azos.suites.base.enable;
in {
  options.azos.suites.base.enable = azos-utils.mkSuiteEnableOption {};

  imports = [
    ./emacs
    ./python
    ./gpg-agent
    ./git
    ./name.nix
  ];

  options.azos = {
        name = lib.mkOption {
            default = "YOUR NAME HERE";
            type = lib.types.str;
            description = "Your full name.";
        };
        enableBashInstall = lib.mkOption {
            default = true;
            type = lib.types.bool;
            description = "Whether to enable bash install.";
        };
  };
  config = lib.mkIf isEnabled {
    fonts.fontconfig.enable = true;
    programs.bash.enable = config.azos.enableBashInstall; #Bash enabling
    home.packages = with pkgs; [
      wget
      curl

      #fonts
      liberation_ttf
      font-awesome
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      liberation_ttf
      fira-code
      fira-code-symbols
      mplus-outline-fonts.githubRelease
      dina-font
    ];
  };
}
