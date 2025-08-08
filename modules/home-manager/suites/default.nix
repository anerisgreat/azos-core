#https://xeiaso.net/talks/asg-2023-nixos/ example
{
  lib,
  config,
  pkgs,
  options,
  azos-utils,
  ...
}: {
  _module.args.azos-utils = import ./utils.nix {lib = lib;};

  imports = [
    ./base
    ./station
    ./dev
    ./editor
    ./exwm
  ];
}
