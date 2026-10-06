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

  config.flake.modules.homeManager.claude-memory = {
    lib,
    config,
    pkgs,
    ...
  }: {
    options.azos.claude-memory.enable = lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
      description = ''
        Enable the Claude memory MCP server backed by org-roam.

        When enabled, installs org-roam-mcp and registers it as a global
        MCP server in ~/.claude.json so Claude Code can search, create, and
        update notes in your org-roam knowledge base across sessions.

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
      '';
    };
    options.azos.claude-memory.orgRoamDir = lib.mkOption {
      default = config.home.homeDirectory + "/roam";
      example = "/home/user/notes/roam";
      type = lib.types.str;
      description = ''
        Absolute path to the org-roam notes directory.
        Passed to org-roam-mcp as ORG_ROAM_DIR.
        Must match the value of org-roam-directory in your Emacs config.
      '';
    };
    options.azos.claude-memory.orgRoamDbPath = lib.mkOption {
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

    config = lib.mkIf config.azos.claude-memory.enable {
      home.packages = [pkgs.org-roam-mcp pkgs.jq];

      home.activation.configureMcpMemory = lib.hm.dag.entryAfter ["writeBoundary"] ''
        CLAUDE_JSON="$HOME/.claude.json"
        MCP_ENTRY=$(${pkgs.jq}/bin/jq -n \
          --arg cmd "${pkgs.org-roam-mcp}/bin/org-roam-mcp" \
          --arg roamDir "${config.azos.claude-memory.orgRoamDir}" \
          --arg dbPath "${config.azos.claude-memory.orgRoamDbPath}" \
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
          --arg roamDir "${config.azos.claude-memory.orgRoamDir}" \
          --arg dbPath "${config.azos.claude-memory.orgRoamDbPath}" \
          --arg resync "${pkgs.org-roam-mcp}/bin/org-roam-resync" \
          '{
            matcher: "Edit|Write",
            hooks: [{
              type: "command",
              command: ("jq -r .tool_input.file_path | { read -r f; case \"$f\" in " + $roamDir + "/*) ORG_ROAM_DIR=" + $roamDir + " ORG_ROAM_DB_PATH=" + $dbPath + " " + $resync + " \"$f\" >/dev/null 2>&1 || true ;; esac; }")
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

      home.activation.configureOrgRoamPermissions = lib.hm.dag.entryAfter ["writeBoundary"] ''
        SETTINGS_JSON="$HOME/.claude/settings.json"
        READ_RULE="Read(/${config.azos.claude-memory.orgRoamDir}/**)"
        EDIT_RULE="Edit(/${config.azos.claude-memory.orgRoamDir}/**)"

        if [ -f "$SETTINGS_JSON" ]; then
          tmp=$(mktemp)
          ${pkgs.jq}/bin/jq --arg read "$READ_RULE" --arg edit "$EDIT_RULE" \
            '.permissions.allow = (((.permissions.allow // []) + [$read, $edit]) | unique)' \
            "$SETTINGS_JSON" > "$tmp" && mv "$tmp" "$SETTINGS_JSON"
        else
          ${pkgs.jq}/bin/jq -n --arg read "$READ_RULE" --arg edit "$EDIT_RULE" \
            '{permissions: {allow: [$read, $edit]}}' > "$SETTINGS_JSON"
        fi
      '';
    };
  };
}
