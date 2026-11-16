{...}: {
  config.flake.modules.homeManager.desktop = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.azos.mail;
    addresses = lib.mapAttrsToList (_: a: a.address) config.accounts.email.accounts;

    # One Elisp plist per account (primary first) for the mu4e setup in
    # suites/desktop/emacs/config.org. builtins.toJSON gives valid Elisp
    # string literals for ordinary text; null values leave their key out.
    accounts = let
      all = lib.partition (a: a.primary) (lib.attrValues config.accounts.email.accounts);
    in
      all.right ++ all.wrong;
    elStr = builtins.toJSON;
    # Older home-manager has a home-relative maildirBasePath.
    maildirBase = let
      base = config.accounts.email.maildirBasePath;
    in
      if lib.hasPrefix "/" base
      then base
      else "~/${base}";
    elPlist = a: let
      m = a.azos.mu4e;
      fields = [
        ["name" (elStr (lib.defaultTo a.name m.contextName))]
        ["address" (elStr a.address)]
        ["real-name" (elStr a.realName)]
        ["maildir" (elStr "/${a.maildir.path}")]
        ["inbox" (elStr a.folders.inbox)]
        ["sent" (elStr a.folders.sent)]
        ["drafts" (elStr a.folders.drafts)]
        ["trash" (elStr a.folders.trash)]
        ["refile" (elStr m.refileFolder)]
        ["spam" (lib.mapNullable elStr m.spamFolder)]
        ["exclude" "(${lib.concatMapStringsSep " " elStr m.excludeFromSearch})"]
        ["key" (lib.mapNullable elStr m.shortcutKey)]
      ];
    in
      "("
      + lib.concatMapStringsSep " " (f: ":${lib.elemAt f 0} ${lib.elemAt f 1}")
      (lib.filter (f: lib.elemAt f 1 != null) fields)
      + ")";
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
    # Extra per-account settings for mu4e, plus the real folder names for
    # Gmail accounts (home-manager's gmail.com flavor sets only the hosts, so
    # its folders would otherwise default to Sent/Drafts/Trash). A Gmail
    # account in another locale (e.g. a trash folder named "Bin") just sets
    # folders.trash itself.
    options.accounts.email.accounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({config, ...}: {
        options.azos.mu4e = {
          contextName = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "mu4e context name; null uses the account's attribute name.";
          };
          shortcutKey = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "w";
            description = "Key (one character) for this account's inbox in mu4e-maildir-shortcuts.";
          };
          refileFolder = lib.mkOption {
            type = lib.types.str;
            default = "Archive";
            description = "Folder mu4e refiles (archives) messages to.";
          };
          spamFolder = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = "Spam";
            description = "Spam folder, left out of the Unread/Today/Week bookmarks.";
          };
          excludeFromSearch = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["Deleted Messages"];
            description = "Extra folders (e.g. an all-mail folder) left out of the Unread/Today/Week bookmarks.";
          };
        };
        config = lib.mkIf (config.flavor == "gmail.com") {
          folders = {
            sent = lib.mkDefault "[Gmail]/Sent Mail";
            drafts = lib.mkDefault "[Gmail]/Drafts";
            trash = lib.mkDefault "[Gmail]/Trash";
          };
          azos.mu4e = {
            refileFolder = lib.mkDefault "[Gmail]/All Mail";
            spamFolder = lib.mkDefault "[Gmail]/Spam";
            excludeFromSearch = lib.mkDefault ["[Gmail]/All Mail"];
          };
        };
      }));
    };
    options.azos.mail.enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
    options.azos.mail.tabBarUnreadCount = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = "Show the number of unread messages across all inboxes in the Emacs tab bar.";
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
      home.file.".emacs.d/extra/azos-mail-accounts.el".text = ''
        ;;; -*- lexical-binding: t; -*-
        ;; Generated by azos-core (suites/desktop/mail) from accounts.email.accounts.
        (setq azos/mail/maildir-base ${elStr maildirBase})
        (setq azos/mail/accounts
              '(${lib.concatMapStringsSep "\n        " elPlist accounts}))

        ${lib.optionalString cfg.tabBarUnreadCount ''
          (with-eval-after-load 'azos-emacs-desktop
            (azos/mail/enable-tab-display))
        ''}'';
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
