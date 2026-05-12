{
  lib,
  config,
  pkgs,
  ...
}: let
  isEnabled =
    config.azos.suites.exwm.enable;
in {
  options.azos.suites.exwm.enable = lib.mkOption {
    default = false;
    example = true;
    type = lib.types.bool;
  };

  config = lib.mkMerge [
    (lib.mkIf isEnabled {
      services.udisks2.enable = true;
    })
    {
      warnings = lib.optionals (!isEnabled) (
        lib.concatLists (lib.mapAttrsToList
          (user: userCfg:
            lib.optional userCfg.azos.suites.exwm.enable
            "azos.suites.exwm is enabled for home-manager user '${user}' but disabled at the NixOS level. udisks2 will not be available.")
          config.home-manager.users)
      );
    }
  ];
}
