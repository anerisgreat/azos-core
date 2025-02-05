#https://xeiaso.net/talks/asg-2023-nixos/ example
{ lib, config, pkgs, options, azos-utils, ... }:
{
  options.azos.suites.dev.enable = (azos-utils.mkSuiteEnableOption {});

  imports = [
    ./emacs
  ];
}
