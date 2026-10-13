{...}: {
  config.flake.modules.homeManager.desktop = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.azos.mail;
    addresses = lib.mapAttrsToList (_: a: a.address) config.accounts.email.accounts;
    # New mail is detected by counting files under every account's Maildir
    # "new" subdirectory before and after the sync -- that's where messages
    # the server hasn't marked seen land, across every configured account at
    # once, with no need to touch mu's index. A rise in that count means mail
    # actually arrived, so only then does it post a desktop notification via
    # notify-send -- intentionally separate from mu4e's own "mbsync -a" (its
    # mu4e-get-mail-command), which doesn't go through this script at all.
    mbsyncSafe = pkgs.writeShellScript "mbsync-safe" ''
      ${lib.optionalString (cfg.presenceCheckCommand != null) ''
        if ! ${cfg.presenceCheckCommand}; then
          exit 0
        fi
      ''}
      before=$(find "$HOME/Maildir" -path '*/new/*' -type f 2>/dev/null | wc -l)
      ${pkgs.isync}/bin/mbsync -a
      after=$(find "$HOME/Maildir" -path '*/new/*' -type f 2>/dev/null | wc -l)
      new=$((after - before))
      if [ "$new" -gt 0 ]; then
        label="new message"
        [ "$new" -ne 1 ] && label="new messages"
        ${pkgs.libnotify}/bin/notify-send "Mail" "$new $label"
      fi
    '';
  in {
    options.azos.mail.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
    options.azos.mail.presenceCheckCommand = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional shell command checked before each sync; if it exits
        non-zero, the sync is skipped silently for that run. For example,
        when mail passwords are retrieved via a GPG smartcard (see
        azos.encryption.yubikey), this avoids a pinentry "please insert
        card" prompt firing on a timer when the card isn't plugged in.

        Leave null (the default) to always sync unconditionally -- e.g.
        when mail passwords aren't gated behind any hardware presence
        check at all.
      '';
    };
    config = lib.mkIf cfg.enable {
      programs = {
        mu.enable = true;
        mbsync.enable = true;
        msmtp.enable = true;
      };
      home.activation.muInit = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ ! -d "$HOME/.cache/mu" ]; then
          $DRY_RUN_CMD ${pkgs.mu}/bin/mu init \
            --maildir="$HOME/Maildir" \
            ${lib.concatMapStringsSep " " (a: "--my-address=${lib.escapeShellArg a}") addresses}
        fi
      '';
      systemd.user.services.mbsync-timer = {
        Unit.Description = "Sync mail via mbsync (skips silently if the presence check fails)";
        Service = {
          Type = "oneshot";
          ExecStart = "${mbsyncSafe}";
        };
      };
      systemd.user.timers.mbsync-timer = {
        Unit.Description = "Periodic mbsync mail sync";
        Timer = {
          OnStartupSec = "2m";
          OnUnitActiveSec = "5m";
        };
        Install.WantedBy = ["timers.target"];
      };
    };
  };
}
