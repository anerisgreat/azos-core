# Bluetooth headphones: azos-connect-headphones (quick connect), and
# optionally hands-free Claude Code dictation and an AVRCP reconnect fix.
#
# Dictation: a media key taps Space in the Claude terminal (see "Claude
# dictation key" in ../emacs/config.org). While the mic is recording the
# headset is in HFP, PipeWire reports a call as active, and the touch pad
# becomes call controls: swipes send nothing, and a double tap sends
# AT+CHUP (hang up). PipeWire has no modem to hand it to, so it only logs
# "modem not available: AT+CHUP" (a warning, so it is in the journal at the
# default log level). The hang-up watcher turns that line into another Space
# tap, but only while Claude itself is capturing audio, so a double tap in a
# real call never reaches Claude.
{...}: {
  config.flake.modules.homeManager.exwm = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.azos.headphones;

    # Swipes reach Emacs through bluez's "<name> (AVRCP)" input device. After
    # some reconnects the AVRCP link drops ~15 s in and stays down (seen
    # 2026-11-16 on the WH-1000XM6); ConnectProfile alone drops again, but a
    # full disconnect/connect keeps it. Done only while nothing records from
    # the headset, and at most every 10 minutes per device.
    avrcpFix = pkgs.writeShellApplication {
      name = "azos-headphones-avrcp-fix";
      runtimeInputs = [pkgs.bluez pkgs.wireplumber pkgs.gnugrep pkgs.gnused pkgs.coreutils];
      text = ''
        state="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/azos-headphones-avrcp"
        mkdir -p "$state"
        for mac in ${lib.concatMapStringsSep " " (d: lib.escapeShellArg d.mac) cfg.devices}; do
          info=$(bluetoothctl info "$mac" 2>/dev/null) || continue
          grep -q 'Connected: yes' <<<"$info" || continue
          name=$(sed -n 's/^\s*Name: //p' <<<"$info")
          grep -qF "Name=\"$name (AVRCP)\"" /proc/bus/input/devices && continue
          # Recording (or a call) in progress: don't cut it off.
          wpctl status | grep -qE "< $name:capture" && continue
          stamp="$state/''${mac//:/_}"
          if [[ -e $stamp && $(( $(date +%s) - $(stat -c %Y "$stamp") )) -lt 600 ]]; then
            continue
          fi
          touch "$stamp"
          echo "$name: AVRCP input missing, reconnecting"
          bluetoothctl disconnect "$mac" >/dev/null
          sleep 3
          bluetoothctl connect "$mac" >/dev/null
        done
      '';
    };

    # .claude-wrapped is the process name of nixpkgs' claude-code wrapper;
    # if the package's wrapper changes, check that it still matches.
    hangupWatch = pkgs.writeShellApplication {
      name = "azos-headphones-hangup-watch";
      runtimeInputs = [pkgs.systemd pkgs.gnugrep pkgs.wireplumber];
      text = ''
        journalctl --user -u wireplumber -f -n 0 -o cat \
          | grep --line-buffered -F 'modem not available: AT+CHUP' \
          | while read -r _; do
              if wpctl status | grep -qF '.claude-wrapped'; then
                emacsclient -e "(azos/claude/dictate #'ignore)" >/dev/null || true
              fi
            done
      '';
    };
  in {
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
      claudeDictation = {
        enable = lib.mkOption {
          default = false;
          example = true;
          type = lib.types.bool;
          description = ''
            Hands-free Claude Code dictation: `key` taps Space in the visible
            (else most recent) Claude Code session, falling back to the key's
            usual command without one, and a headset double tap (an HFP
            hang-up while Claude records) taps it again to stop. Needs
            azos.claude.ide.enable; pair it with azos.claude.voice.enable
            (voice mode tap).
          '';
        };
        key = lib.mkOption {
          default = "<XF86AudioNext>";
          example = "<XF86AudioPlay>";
          type = lib.types.str;
          description = ''
            Key (`kbd` syntax) that dictates. The default is next track,
            which a swipe forward on the Sony WH-1000XM6 sends.
          '';
        };
      };
      avrcpReconnect = lib.mkOption {
        default = false;
        example = true;
        type = lib.types.bool;
        description = ''
          Workaround for headsets whose AVRCP link (media buttons, touch
          controls) sometimes drops ~15 s after a reconnect and stays down,
          seen on the Sony WH-1000XM6. Every minute, a connected device in
          `devices` without its "<name> (AVRCP)" input device is
          disconnected and reconnected, unless it is recording, at most
          every 10 minutes per device.
        '';
      };
    };

    config = lib.mkIf cfg.enable (lib.mkMerge [
      {
        home.packages = let
          deviceEntries =
            lib.concatMapStrings
            (d: "  ${lib.escapeShellArg "${d.mac} ${d.name}"}\n")
            cfg.devices;
          defaultMac =
            if cfg.devices == []
            then ""
            else (lib.head cfg.devices).mac;
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
      }

      (lib.mkIf cfg.claudeDictation.enable {
        assertions = [
          {
            assertion = config.azos.claude.enable && config.azos.claude.ide.enable;
            message = "azos.headphones.claudeDictation needs azos.claude.enable and azos.claude.ide.enable.";
          }
        ];

        home.file.".emacs.d/extra/azos-headphones.el".text = ''
          ;;; -*- lexical-binding: t; -*-
          ;; Generated by azos-core (suites/exwm/headphones).
          (azos/headphones/enable-claude-dictation ${builtins.toJSON cfg.claudeDictation.key})
        '';

        systemd.user.services.azos-headphones-hangup-watch = {
          Unit.Description = "Headset double tap (HFP hang-up) stops Claude dictation";
          Service = {
            ExecStart = "${hangupWatch}/bin/azos-headphones-hangup-watch";
            # emacsclient comes from the home-manager profile.
            Environment = "PATH=${config.home.profileDirectory}/bin";
            Restart = "always";
            RestartSec = 5;
          };
          Install.WantedBy = ["default.target"];
        };
      })

      (lib.mkIf cfg.avrcpReconnect {
        systemd.user.services.azos-headphones-avrcp-fix = {
          Unit.Description = "Reconnect headphones whose AVRCP (touch controls) link dropped";
          Service = {
            Type = "oneshot";
            ExecStart = "${avrcpFix}/bin/azos-headphones-avrcp-fix";
          };
        };

        systemd.user.timers.azos-headphones-avrcp-fix = {
          Unit.Description = "Check the headphones' AVRCP link every minute";
          Timer = {
            OnBootSec = "1min";
            OnUnitActiveSec = "1min";
          };
          Install.WantedBy = ["timers.target"];
        };
      })
    ]);
  };
}
