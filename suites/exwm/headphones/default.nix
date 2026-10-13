{...}: {
  config.flake.modules.homeManager.exwm = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.headphones = {
      enable = lib.mkOption {
        default = false;
        example = true;
        type = lib.types.bool;
      };
      devices = lib.mkOption {
        default = [];
        type = lib.types.listOf (lib.types.submodule {
          options = {
            mac = lib.mkOption {type = lib.types.str;};
            name = lib.mkOption {type = lib.types.str;};
          };
        });
        description = "Headphone devices; first entry is the default connect target.";
      };
    };

    config = lib.mkIf config.azos.headphones.enable {
      home.packages = let
        deviceEntries =
          lib.concatMapStrings
          (d: "  ${lib.escapeShellArg "${d.mac} ${d.name}"}\n")
          config.azos.headphones.devices;
        defaultMac =
          if config.azos.headphones.devices == []
          then ""
          else (lib.head config.azos.headphones.devices).mac;
      in [
        (pkgs.writeShellScriptBin "azos-connect-headphones" ''
          DEVICES=(
          ${deviceEntries})

          case "$1" in
            --list)
              printf '%s\n' "''${DEVICES[@]}"
              ;;
            --mac)
              echo "connect $2" | bluetoothctl
              ;;
            *)
              echo "connect ${defaultMac}" | bluetoothctl
              ;;
          esac
        '')
      ];
    };
  };
}
