# Expire old home-manager generations by age, then garbage-collect the store.
# By age rather than "keep the last N": a burst of switches while fixing
# something shouldn't push out the generation from yesterday that worked.
# The current generation is never removed, however old it is.
{...}: {
  config.flake.modules.homeManager.base = {
    lib,
    config,
    ...
  }: let
    cfg = config.azos.auto-expire;
  in {
    options.azos.auto-expire = {
      enable = lib.mkOption {
        default = false;
        example = true;
        type = lib.types.bool;
        description = "Periodically expire old home-manager generations.";
      };
      olderThan = lib.mkOption {
        type = lib.types.str;
        default = "-14 days";
        example = "-30 days";
        description = "Generations older than this (a `date -d` expression) are removed.";
      };
      frequency = lib.mkOption {
        type = lib.types.str;
        default = "weekly";
        example = "daily";
        description = "How often to expire, as a systemd OnCalendar expression.";
      };
      storeCleanup = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Run nix-collect-garbage afterwards, so the space is actually freed.
          On NixOS this only frees what the user's own generations held;
          system generations need nix.gc.
        '';
      };
    };

    config = lib.mkIf cfg.enable {
      services.home-manager.autoExpire = {
        enable = true;
        timestamp = cfg.olderThan;
        inherit (cfg) frequency;
        store.cleanup = cfg.storeCleanup;
      };
    };
  };
}
