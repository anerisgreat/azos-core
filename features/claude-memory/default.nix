{...}: {
  config.flake.overlayPkgs.org-roam-mcp = pkgs:
    pkgs.python3Packages.buildPythonApplication rec {
      pname = "org-roam-mcp";
      version = "0.1.0";
      pyproject = true;
      src = pkgs.fetchFromGitHub {
        owner = "anerisgreat";
        repo = "org-roam-mcp";
        rev = "dd2e1f7dd040a57240e448016e3625a0de7fbff6";
        sha256 = "1b3hsszzgcn57jfxnp8zghf8hl1v01kk445q40x8yqzrcvd7nf9v";
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
          '{command: $cmd, args: [], env: {ORG_ROAM_DIR: $roamDir, ORG_ROAM_DB_PATH: $dbPath}}')

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
    };
  };
}
