#https://xeiaso.net/talks/asg-2023-nixos/ example
{ lib, config, pkgs, options, azos-utils, ... }:
{
  options.azos.suites.base.enable = (azos-utils.mkSuiteEnableOption {});

  imports = [
    ./emacs
    ./python
    ./gpg-agent
    ./git
    ./name.nix
  ];

  options.azos.name = lib.mkOption{
    default = "YOUR NAME HERE";
    type = lib.types.str;
    description = "Your full name.";
    };

  config.home.packages = with pkgs; [
    liberation_ttf
    font-awesome
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    mplus-outline-fonts.githubRelease
    dina-font
    proggyfonts
  ];
}
