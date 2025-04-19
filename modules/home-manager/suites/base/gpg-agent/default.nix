{ lib, config, pkgs, azos-utils, ... }:
let
  isEnabled =
    config.azos.gpgagent.enable &&
    config.azos.suites.base.enable;
in
{
  options.azos.gpgagent.enable = (azos-utils.mkFeatureEnableOption {});

  config = lib.mkIf isEnabled {
    home.packages =  [ pkgs.gnupg ];
    home.file.".gnupg/gpg-agent.conf".source = ./gpg-agent.conf;
  };
}
