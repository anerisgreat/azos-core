# claude-skills

Deploys Claude Code global skills and standing behavioral instructions via home-manager.

Enabled automatically when `azos.claude.enable = true`.

## What gets deployed

| Destination | Source |
|---|---|
| `~/.claude/commands/<name>.md` | Each entry in `azos.claude.globalSkills` |
| `~/.claude/CLAUDE.md` | All entries in `azos.claude.globalMdSections` merged alphabetically |

## Built-in skills

- **`todo`** — manages per-project TODO lists in org-roam
- **`project-brain`** — loads and saves project knowledge in org-roam at session start and when something significant is learned

## Extending from any module

### Adding a skill (slash command)

```nix
azos.claude.globalSkills.my-skill = ./path/to/my-skill.md;
```

The skill file is a markdown document. Claude invokes it automatically when
the user's request matches, or the user can call it explicitly as `/my-skill`.

### Adding a standing behavioral instruction (CLAUDE.md section)

```nix
azos.claude.globalMdSections.my-rule = ''
  # My Standing Instruction

  Always do X when working in this environment.
'';
```

Sections are merged alphabetically by key. Prefix your key to control ordering
(e.g. `"10-my-rule"` sorts before `"20-other-rule"`).

Both options accept contributions from any module — azos-core features, machine
configs, or external repos — without modifying azos-core itself.
