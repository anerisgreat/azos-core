{...}: {
  config.flake.modules.homeManager.claude-skills = {
    lib,
    config,
    ...
  }: {
    options.azos.claude-skills.enable = lib.mkOption {
      default = false;
      example = true;
      type = lib.types.bool;
      description = ''
        Deploy Claude Code global skills and CLAUDE.md to ~/.claude/.

        Skills in azos.claude.globalSkills are deployed as markdown files to
        ~/.claude/commands/. Sections in azos.claude.globalMdSections are merged
        into ~/.claude/CLAUDE.md. Both options are extensible from any module.
      '';
    };

    options.azos.claude.globalSkills = lib.mkOption {
      default = {};
      type = lib.types.attrsOf lib.types.path;
      description = ''
        Attrset of skill name to markdown file path. Each entry is deployed to
        ~/.claude/commands/<name>.md and becomes a Claude Code slash command.
        Any module can contribute skills by adding entries here.
      '';
    };

    options.azos.claude.globalMdSections = lib.mkOption {
      default = {};
      type = lib.types.attrsOf lib.types.lines;
      description = ''
        Attrset of section key to markdown content. All sections are merged
        alphabetically by key into ~/.claude/CLAUDE.md. Any module can contribute
        standing behavioral instructions by adding entries here.
      '';
    };

    config = lib.mkIf config.azos.claude-skills.enable {
      azos.claude.globalSkills = {
        todo = ./skills/todo.md;
        project-brain = ./skills/project-brain.md;
      };

      azos.claude.globalMdSections.project-brain = ''
        # Project Knowledge (org-roam Second Brain)

        At the start of every session, invoke the `project-brain` skill to load
        known context from org-roam for the current project before doing any work.

        When you discover something significant about a project that is not already
        in org-roam (architecture decisions, non-obvious conventions, key file
        locations, unexpected constraints, gotchas), save it using the
        `project-brain` skill without waiting to be asked.

        If you need context you do not have, search org-roam first before asking
        the user.
      '';

      home.file =
        lib.mapAttrs' (name: skillPath:
          lib.nameValuePair ".claude/commands/${name}.md" {source = skillPath;})
        config.azos.claude.globalSkills
        // lib.optionalAttrs (config.azos.claude.globalMdSections != {}) {
          ".claude/CLAUDE.md".text =
            lib.concatStringsSep "\n\n"
            (lib.attrValues config.azos.claude.globalMdSections);
        };
    };
  };
}
