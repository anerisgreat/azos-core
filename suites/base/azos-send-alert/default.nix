{...}: {
  config.flake.modules.homeManager.base = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.send-alert.enable = lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
    };
    options.azos.send-alert.remoteCommand = lib.mkOption {
      type = lib.types.str;
      description = ''
        Shell command invoked for the remote-notification half of
        azos-send-alert (e.g. posting to ntfy, Slack, a webhook...). Runs
        with TITLE, PRIORITY, TAGS, and MESSAGE exported as environment
        variables.

        In normal mode its exit status and output are ignored -- the local
        desktop notification (via notify-send) always fires regardless, as a
        fallback independent of whether the remote command succeeds.

        When azos-send-alert is run with -r/--print-remote, the command
        instead runs with AZOS_SEND_ALERT_PRINT_REMOTE=1 set and its stdout
        is captured and printed -- the convention is that the command checks
        this variable and, if set, resolves any local secrets (e.g. via
        `pass`) and prints a fully self-contained invocation that a remote
        host without those secrets can run (see azos/features/homey-alert in
        the azos project for the ntfy-backed implementation of this).
      '';
    };
    options.azos.send-alert.longCommandThresholdSeconds = lib.mkOption {
      default = 300;
      example = 600;
      type = lib.types.int;
      description = ''
        Installs a global PreToolUse hook (matcher "Bash") in
        ~/.claude/settings.json that transparently wraps every Bash command
        Claude Code runs: it times the command, and if it ran at or past
        this threshold, fires azos-send-alert with the elapsed time and exit
        code once it finishes. Commands that finish faster are unaffected.

        This exists so long-running commands (big transfers, builds) notify
        automatically even when Claude never thinks to chain azos-send-alert
        itself, and even if the harness moves the command to the background
        partway through.

        The hook only adds timing + notification around the command as
        given -- it does not change permissions, so normal confirmation
        prompts for risky commands still happen exactly as before.
      '';
    };

    config = lib.mkIf config.azos.send-alert.enable (let
      threshold = toString config.azos.send-alert.longCommandThresholdSeconds;
      # Rewrites every Bash tool command to time itself and fire
      # azos-send-alert if it ran at or past the threshold. The original
      # command is spliced in verbatim (not eval'd from an encoded blob)
      # so it stays human-readable in any permission prompt, and it's run
      # in a subshell so the wrapper's own timing/notify code still runs
      # even if the original command uses `set -e` or calls `exit`.
      # permissionDecision is deliberately omitted from the hook's JSON
      # output: supplying it (even as "allow") would bypass the normal
      # confirmation flow, which must stay untouched here.
      bashNotifyHook = pkgs.writeShellApplication {
        name = "azos-bash-notify-hook";
        runtimeInputs = [pkgs.jq];
        text = ''
          input=$(cat)
          command=$(printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null) || command=""

          if [ -z "$command" ]; then
            echo '{}'
            exit 0
          fi

          wrapped="__azos_notify_start=\$(date +%s)
          (
          $command
          )
          __azos_notify_rc=\$?
          __azos_notify_dur=\$(( \$(date +%s) - __azos_notify_start ))
          if [ \"\$__azos_notify_dur\" -ge ${threshold} ]; then
            __azos_notify_tag=\$([ \"\$__azos_notify_rc\" -eq 0 ] && echo white_check_mark || echo x)
            azos-send-alert -t \"Long command\" -T \"\$__azos_notify_tag\" \"Finished in \$__azos_notify_dur s (exit \$__azos_notify_rc)\" >/dev/null 2>&1 || true
          fi
          exit \"\$__azos_notify_rc\""

          jq -n --arg cmd "$wrapped" \
            '{hookSpecificOutput: {hookEventName: "PreToolUse", updatedInput: {command: $cmd}}}' 2>/dev/null || echo '{}'
        '';
      };
    in {
      azos.claude.globalSkills.notify = ./notify-skill.md;

      home.activation.configureBashNotifyHook = lib.hm.dag.entryAfter ["writeBoundary"] ''
        SETTINGS_JSON="$HOME/.claude/settings.json"
        HOOK_ENTRY=$(${pkgs.jq}/bin/jq -n \
          --arg cmd "${bashNotifyHook}/bin/azos-bash-notify-hook" \
          '{
            matcher: "Bash",
            hooks: [{type: "command", command: $cmd}]
          }')

        if [ -f "$SETTINGS_JSON" ]; then
          tmp=$(mktemp)
          ${pkgs.jq}/bin/jq --argjson entry "$HOOK_ENTRY" \
            '.hooks.PreToolUse = ((.hooks.PreToolUse // []) | map(select(.matcher != $entry.matcher))) + [$entry]' \
            "$SETTINGS_JSON" > "$tmp" && mv "$tmp" "$SETTINGS_JSON"
        else
          ${pkgs.jq}/bin/jq -n --argjson entry "$HOOK_ENTRY" \
            '{hooks: {PreToolUse: [$entry]}}' > "$SETTINGS_JSON"
        fi
      '';

      home.packages = [
        bashNotifyHook
        (pkgs.writeShellApplication {
          name = "azos-send-alert";
          runtimeInputs = with pkgs; [libnotify];
          text = ''
            usage() {
              cat <<EOF
            Usage: azos-send-alert [OPTIONS] [MESSAGE]

            Send a notification via the configured remote command
            (azos.send-alert.remoteCommand), and (when run locally, not with
            --print-remote) also via notify-send -- the remote side isn't
            always reachable, so the local desktop notification always fires
            too, independent of whether the remote command succeeds.
            MESSAGE can be given as a positional argument or piped via stdin.

            Options:
              -t, --title TITLE      notification title
              -p, --priority PRIO    priority: min|low|default|high|urgent  (default: default)
              -T, --tags TAGS        comma-separated emoji shortcodes (e.g. warning,rotating_light)
              -r, --print-remote     have the remote command print a self-contained invocation
                                     instead of sending (for pasting into SSH commands)
              -h, --help             show this help

            Examples:
              # Local
              long_cmd && azos-send-alert -t "Training" -p high -T white_check_mark "done"

              # Remote — expands locally, runs on the remote machine
              ssh user@host "python train.py && \$(azos-send-alert -r -t 'Training' 'done')"
            EOF
            }

            TITLE=""
            PRIORITY="default"
            TAGS=""
            PRINT_REMOTE=false

            while [[ $# -gt 0 ]]; do
              case "$1" in
                -t|--title)        TITLE="$2";        shift 2 ;;
                -p|--priority)     PRIORITY="$2";     shift 2 ;;
                -T|--tags)         TAGS="$2";         shift 2 ;;
                -r|--print-remote) PRINT_REMOTE=true; shift   ;;
                -h|--help)         usage; exit 0 ;;
                --)                shift; break ;;
                -*)                echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
                *)                 break ;;
              esac
            done

            if [[ $# -gt 0 ]]; then
              MESSAGE="$*"
            elif [[ ! -t 0 ]]; then
              MESSAGE="$(cat)"
            else
              echo "azos-send-alert: no message provided" >&2
              usage >&2
              exit 1
            fi

            export TITLE PRIORITY TAGS MESSAGE

            if $PRINT_REMOTE; then
              AZOS_SEND_ALERT_PRINT_REMOTE=1 bash -c ${lib.escapeShellArg config.azos.send-alert.remoteCommand}
            else
              bash -c ${lib.escapeShellArg config.azos.send-alert.remoteCommand} >/dev/null 2>&1 || true

              # Local desktop notification, independent of the remote command above --
              # the remote side isn't always reachable, so this always fires as a fallback.
              URGENCY="normal"
              case "$PRIORITY" in
                min|low)    URGENCY="low" ;;
                high|urgent) URGENCY="critical" ;;
              esac
              notify-send -u "$URGENCY" "''${TITLE:-azos-send-alert}" "$MESSAGE" || true
            fi
          '';
        })
      ];
    });
  };
}
