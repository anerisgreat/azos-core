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

  config.home.packages = [
    pkgs.liberation_ttf
    pkgs.font-awesome
  ];
}
