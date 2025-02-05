{ lib, config, pkgs, options, azos-utils, ... }:
let
  isEnabled = config.azos.suites.station.enable && config.azos.mail.enable;
in
{
  options.azos.mail.enable = (azos-utils.mkFeatureEnableOption {
    description = "Enables Mail installation.";});

  options.azos.mail.accounts = lib.mkOption{
    default = [];
    type = lib.types.list;
    description = "List of accounts.";
  };


  imports = [
  ];

  config = lib.mkIf isEnabled {
    home.packages = with pkgs; [pkgs pkgs];
    # home.packages = [#TODO THIS];
  };

}
