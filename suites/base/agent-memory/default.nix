{...}: {
  config.flake.overlayPkgs.org-roam-mcp = pkgs:
    pkgs.python3Packages.buildPythonApplication rec {
      pname = "org-roam-mcp";
      version = "0.1.0";
      pyproject = true;
      src = pkgs.fetchFromGitHub {
        owner = "anerisgreat";
        repo = "org-roam-mcp";
        rev = "8a169a9ec3fec1305a0573a1fddb9fcae97bcc2a";
        sha256 = "19d41p7rgpiqfdg11h585zw15mz9p7iml9f77zxllcbp4mrdamp6";
      };
      build-system = [pkgs.python3Packages.hatchling];
      dependencies = with pkgs.python3Packages; [
        mcp
        pydantic
        typing-extensions
        anyio
      ];
    };

  config.flake.modules.homeManager.base = {
    lib,
    config,
    pkgs,
    ...
  }: let
    cfg = config.azos.agent-memory;
  in {
    options.azos.agent-memory.orgRoamDir = lib.mkOption {
      default = config.home.homeDirectory + "/roam";
      example = "/home/user/notes/roam";
      type = lib.types.str;
      description = ''
        Absolute path to the org-roam notes directory.
        Passed to org-roam-mcp as ORG_ROAM_DIR.
        Must match the value of org-roam-directory in your Emacs config.
      '';
    };
    options.azos.agent-memory.orgRoamDbPath = lib.mkOption {
      default = config.home.homeDirectory + "/.emacs.d/org-roam.db";
      example = "/home/user/.config/emacs/org-roam.db";
      type = lib.types.str;
      description = ''
        Absolute path to the org-roam SQLite database file.
        Passed to org-roam-mcp as ORG_ROAM_DB_PATH.
        With the sqlite-builtin connector the default location is
        <user-emacs-directory>/org-roam.db (~/.emacs.d/org-roam.db).
      '';
    };

    options.azos.agent-memory.backends.claude.enable = lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
      description = ''
        Wires org-roam memory into Claude Code specifically, via its own
        ~/.claude.json and ~/.claude/settings.json.

        Registers org-roam-mcp as a global MCP server in ~/.claude.json so
        Claude Code can search, create, and update notes in your org-roam
        knowledge base across sessions.

        Also installs a global PostToolUse hook in ~/.claude/settings.json:
        after Claude edits or creates a file under orgRoamDir directly (e.g.
        via the project-brain skill), it runs org-roam-resync (bundled with
        org-roam-mcp) to re-derive that file's hash/title/tags/links and
        write them straight into org-roam's SQLite index, so backlinks/
        tags/search stay current without a full org-roam-db-sync -- and
        without requiring Emacs to be running at all.

        Also adds global permission rules so Read and Edit are always
        allowed under orgRoamDir, without per-call prompts, in every
        project/session -- the project-brain/todo/workplate/work-history
        skills read and write there constantly. Edit still only applies
        when the session's permission mode otherwise allows edits (e.g. not
        plan mode); this just removes the per-file prompt within that path.

        Also pre-approves the org-roam MCP tools used in that same normal
        flow: mcp__org-roam__search_nodes unconditionally (read-only), and
        mcp__org-roam__create_node under the same gating as Edit above --
        pre-approved, but still subject to the session's permission mode.

        Also installs a global SessionStart hook: at the start of every
        session, it looks up the org-roam node whose title exactly matches
        the basename of the current working directory (the project-brain
        root node for that project) and injects its full content into the
        model's context via hookSpecificOutput.additionalContext. This
        makes root-node knowledge available immediately without the model
        needing to invoke the project-brain skill just to load it. Domain
        subnodes are still loaded on demand via the skill. Runs unconditionally
        regardless of AZOS_AGENT_SHELL_SESSION (see
        azos.agent-memory.backends.agent-shell below) -- that backend has no
        session-start context-injection mechanism of its own yet, so there's
        nothing to double up with here.

        The PostToolUse resync hook above, specifically, no-ops when
        AZOS_AGENT_SHELL_SESSION is set in its environment -- see
        azos.agent-memory.backends.agent-shell, which sets that variable on
        Claude sessions it launches via agent-shell, so the resync doesn't
        run twice for the same edit.
      '';
    };

    options.azos.agent-memory.backends.agent-shell.enable = lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
      description = ''
        Wires org-roam memory into agent-shell directly, at the Emacs
        level -- so it applies no matter which ACP backend a given
        agent-shell session is actually running (Claude, Gemini CLI,
        Codex, ...), not just Claude.

        Drops ~/.emacs.d/extra/azos-agent-memory.el (auto-loaded by the
        load-dir setup in suites/base/emacs): registers org-roam-mcp in
        agent-shell-mcp-servers (applies to every session regardless of
        backend), and subscribes to agent-shell's `file-write` event on
        every agent-shell-mode buffer to run org-roam-resync when a file
        under orgRoamDir is written -- the agent-shell-level equivalent of
        the Claude-specific PostToolUse hook above.

        Also appends AZOS_AGENT_SHELL_SESSION=1 to
        agent-shell-anthropic-claude-environment, so that when agent-shell
        launches Claude specifically, azos.agent-memory.backends.claude's
        PostToolUse resync hook (which reads the exact same
        ~/.claude/settings.json claude-agent-acp merges into that session)
        sees the marker and no-ops instead of double-acting alongside this
        backend's file-write subscription. Session-start context injection
        has no equivalent here yet, so the claude backend's SessionStart
        hook is intentionally left unguarded -- it's still the only thing
        providing that for a Claude-via-agent-shell session.
      '';
    };

    config = lib.mkMerge [
      (lib.mkIf (cfg.backends.claude.enable || cfg.backends.agent-shell.enable) {
        home.packages = [pkgs.org-roam-mcp];
      })

      (lib.mkIf cfg.backends.claude.enable (let
        sessionStartScript = pkgs.writeShellScript "project-brain-session-start" ''
          roam_dir="${cfg.orgRoamDir}"
          project=$(basename "$PWD")
          file=$(${pkgs.gnugrep}/bin/grep -rlFx "#+title: $project" "$roam_dir" 2>/dev/null | head -n1)
          if [ -z "$file" ]; then
            echo '{}'
            exit 0
          fi
          content=$(cat "$file")
          ${pkgs.jq}/bin/jq -n --arg ctx "$content" \
            '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
        '';
      in {
        home.packages = [pkgs.jq];

        home.activation.configureMcpMemory = lib.hm.dag.entryAfter ["writeBoundary"] ''
          CLAUDE_JSON="$HOME/.claude.json"
          MCP_ENTRY=$(${pkgs.jq}/bin/jq -n \
            --arg cmd "${pkgs.org-roam-mcp}/bin/org-roam-mcp" \
            --arg roamDir "${cfg.orgRoamDir}" \
            --arg dbPath "${cfg.orgRoamDbPath}" \
            '{command: $cmd, args: [], env: {ORG_ROAM_DIR: $roamDir, ORG_ROAM_DB_PATH: $dbPath, PYTHONPATH: ""}}')

          if [ -f "$CLAUDE_JSON" ]; then
            tmp=$(mktemp)
            ${pkgs.jq}/bin/jq --argjson entry "$MCP_ENTRY" \
              '.mcpServers["org-roam"] = $entry' \
              "$CLAUDE_JSON" > "$tmp" && mv "$tmp" "$CLAUDE_JSON"
          else
            ${pkgs.jq}/bin/jq -n --argjson entry "$MCP_ENTRY" \
              '{mcpServers: {"org-roam": $entry}}' > "$CLAUDE_JSON"
          fi
        '';

        home.activation.configureOrgRoamEditHook = lib.hm.dag.entryAfter ["writeBoundary"] ''
          SETTINGS_JSON="$HOME/.claude/settings.json"
          HOOK_ENTRY=$(${pkgs.jq}/bin/jq -n \
            --arg roamDir "${cfg.orgRoamDir}" \
            --arg dbPath "${cfg.orgRoamDbPath}" \
            --arg resync "${pkgs.org-roam-mcp}/bin/org-roam-resync" \
            '{
              matcher: "Edit|Write",
              hooks: [{
                type: "command",
                command: ("[ -n \"$AZOS_AGENT_SHELL_SESSION\" ] && { cat >/dev/null; exit 0; }; jq -r .tool_input.file_path | { read -r f; case \"$f\" in " + $roamDir + "/*) ORG_ROAM_DIR=" + $roamDir + " ORG_ROAM_DB_PATH=" + $dbPath + " " + $resync + " \"$f\" >/dev/null 2>&1 || true ;; esac; }")
              }]
            }')

          if [ -f "$SETTINGS_JSON" ]; then
            tmp=$(mktemp)
            ${pkgs.jq}/bin/jq --argjson entry "$HOOK_ENTRY" \
              '.hooks.PostToolUse = ((.hooks.PostToolUse // []) | map(select(.matcher != $entry.matcher))) + [$entry]' \
              "$SETTINGS_JSON" > "$tmp" && mv "$tmp" "$SETTINGS_JSON"
          else
            ${pkgs.jq}/bin/jq -n --argjson entry "$HOOK_ENTRY" \
              '{hooks: {PostToolUse: [$entry]}}' > "$SETTINGS_JSON"
          fi
        '';

        home.activation.configureOrgRoamSessionStartHook = lib.hm.dag.entryAfter ["writeBoundary"] ''
          SETTINGS_JSON="$HOME/.claude/settings.json"
          HOOK_ENTRY=$(${pkgs.jq}/bin/jq -n \
            --arg cmd "${sessionStartScript}" \
            '{hooks: [{type: "command", command: $cmd}]}')

          if [ -f "$SETTINGS_JSON" ]; then
            tmp=$(mktemp)
            ${pkgs.jq}/bin/jq --argjson entry "$HOOK_ENTRY" \
              '.hooks.SessionStart = ((.hooks.SessionStart // []) | map(select((.hooks[0].command // "") | contains("project-brain-session-start") | not))) + [$entry]' \
              "$SETTINGS_JSON" > "$tmp" && mv "$tmp" "$SETTINGS_JSON"
          else
            ${pkgs.jq}/bin/jq -n --argjson entry "$HOOK_ENTRY" \
              '{hooks: {SessionStart: [$entry]}}' > "$SETTINGS_JSON"
          fi
        '';

        home.activation.configureOrgRoamPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
          SETTINGS_JSON="$HOME/.claude/settings.json"
          READ_RULE="Read(/${cfg.orgRoamDir}/**)"
          EDIT_RULE="Edit(/${cfg.orgRoamDir}/**)"
          SEARCH_NODES_RULE="mcp__org-roam__search_nodes"
          CREATE_NODE_RULE="mcp__org-roam__create_node"

          if [ -f "$SETTINGS_JSON" ]; then
            tmp=$(mktemp)
            ${pkgs.jq}/bin/jq \
              --arg read "$READ_RULE" --arg edit "$EDIT_RULE" \
              --arg searchNodes "$SEARCH_NODES_RULE" --arg createNode "$CREATE_NODE_RULE" \
              '.permissions.allow = (((.permissions.allow // []) + [$read, $edit, $searchNodes, $createNode]) | unique)' \
              "$SETTINGS_JSON" > "$tmp" && mv "$tmp" "$SETTINGS_JSON"
          else
            ${pkgs.jq}/bin/jq -n \
              --arg read "$READ_RULE" --arg edit "$EDIT_RULE" \
              --arg searchNodes "$SEARCH_NODES_RULE" --arg createNode "$CREATE_NODE_RULE" \
              '{permissions: {allow: [$read, $edit, $searchNodes, $createNode]}}' > "$SETTINGS_JSON"
          fi
        '';
      }))

      (lib.mkIf cfg.backends.agent-shell.enable {
        home.file.".emacs.d/extra/azos-agent-memory.el".text = ''
          ;;; -*- lexical-binding: t; -*-
          ;; Generated by azos-core (suites/base/agent-memory) -- registers
          ;; org-roam-mcp with agent-shell so memory applies no matter which
          ;; ACP backend a session actually runs, and suppresses azos's
          ;; Claude-specific hooks for sessions agent-shell launches, so the
          ;; two backends never both act on the same session.

          (with-eval-after-load 'agent-shell
            (add-to-list 'agent-shell-mcp-servers
                         '((name . "org-roam")
                           (command . "${pkgs.org-roam-mcp}/bin/org-roam-mcp")
                           (args . [])
                           (env . (((name . "ORG_ROAM_DIR") (value . "${cfg.orgRoamDir}"))
                                   ((name . "ORG_ROAM_DB_PATH") (value . "${cfg.orgRoamDbPath}"))))))

            (defun azos/agent-shell-memory--on-file-write (event)
              "Resync org-roam's index after agent-shell reports a file write under the roam dir."
              (let ((path (map-elt (map-elt event :data) :path)))
                (when (and path (string-prefix-p "${cfg.orgRoamDir}/" path))
                  (call-process "${pkgs.org-roam-mcp}/bin/org-roam-resync" nil 0 nil path))))

            (add-hook 'agent-shell-mode-hook
                      (lambda ()
                        (agent-shell-subscribe-to
                         :shell-buffer (current-buffer)
                         :event 'file-write
                         :on-event #'azos/agent-shell-memory--on-file-write))))

          (with-eval-after-load 'agent-shell-anthropic
            (add-to-list 'agent-shell-anthropic-claude-environment "AZOS_AGENT_SHELL_SESSION=1"))
        '';
      })
    ];
  };
}
