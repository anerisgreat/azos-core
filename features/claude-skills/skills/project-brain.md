Persistent cross-session project memory backed by org-roam. TRIGGER on three conditions — (1) **session start**: always load prior context before doing any work; (2) **before planning or multi-step tasks**: retrieve what's already known so you don't re-derive it; (3) **after learning something non-obvious**: save it immediately so future sessions start informed. Stores architecture decisions, gotchas, key file locations, and conventions that are NOT derivable from reading the code, CLAUDE.md, or git history.

## When to use

**Load** (read from org-roam):
- At the start of every session
- Before planning any non-trivial feature or multi-step task
- When you need context you don't have — check org-roam before asking the user

**Save** (write to org-roam) — do this proactively, without waiting to be asked:
- After any planning or research session where you learned how something works
- After implementing a new feature
- After making a significant change to an existing feature
- After discovering a non-obvious constraint, gotcha, or architectural decision

The rule: if you spent time figuring something out, save it so the next session doesn't have to.

## Node structure

### Root node (always)
- Title: basename of the current working directory (e.g. `myproject`)
- Tags: `["project", "knowledge"]`
- Sections:
  - `** Architecture` — system design, key components, how things fit together
  - `** Conventions` — coding patterns, naming rules, project-specific idioms
  - `** Gotchas` — non-obvious constraints, known issues, things that surprised you
  - `** Key Files` — important file locations and what they do
  - `** Subnodes` — links to any domain subnodes (added when subnodes are created)

Keep the root node lean. It should orient any session quickly, not document everything.
**Hard limit: no section in the root node should exceed ~15 lines.** Split before that point.

### Subnodes (for large or specialized domains)
Split a section into a subnode when it grows beyond ~15 lines, or when it covers a
subsystem only relevant to specialized sessions. Prefer splitting early — a subnode with
5 entries is better than a root section with 20. Many small nodes are always better than
one large node.

- Title: `<project>/<domain>` (e.g. `myproject/emacs`, `myproject/networking`)
- Tags: `["project", "knowledge", "<domain>"]`
- Content: same section structure as the root, scoped to the domain
- Link the subnode back to the root node using an org-roam link
- Add a link to the subnode in the root's `** Subnodes` section

The `<project>/<domain>` naming makes subnodes findable by search without
needing to follow links.

## What is worth saving
- Things not derivable from reading the code or CLAUDE.md
- Decisions and their reasons
- Anything a future session would have to re-derive from scratch
- Do NOT save things already obvious from file names, git history, or CLAUDE.md

## Steps

### Load context (invoke at session start AND before planning any non-trivial feature or multi-step task)
1. Get project name: basename of the current working directory (e.g. `azos`, not `azos knowledge`)
2. Call `mcp__org-roam__get_node_by_title` with the project name — this returns full node content in a single call
3. If `found: true`: incorporate the content into working context
   - If the `** Subnodes` section contains links and the current task is domain-focused, extract the linked node IDs and call `mcp__org-roam__get_node` on the relevant ones (all in parallel if multiple)
4. If `found: false`: note that no prior knowledge exists yet for this project

### Save new knowledge (run after planning, research, or feature work — not just when explicitly asked)
1. Determine whether the knowledge belongs in the root node or a domain subnode
2. Call `mcp__org-roam__get_node_by_title` with the target node's title to get current content
   and its `file` field (the absolute path to the node's `.org` file) in one call
3. If not found: create via `mcp__org-roam__create_node` with appropriate title and tags;
   if creating a subnode, also edit the root's `** Subnodes` section (see step 6) to link it
4. Add new findings under the appropriate section, avoiding duplicates
5. **Before writing**: check whether any section now exceeds ~15 lines. If it does, split it
   into a subnode NOW rather than letting the root grow. Prefer many small focused nodes
   over one large node — a future session loads only what it needs.
6. Edit the node directly: use `Read` then `Edit` on the `file` path returned in step 2 — add
   or amend just the lines that changed. Do NOT call `mcp__org-roam__update_node` for this; it
   only supports whole-file overwrites, so every edit would cost a full round-trip of the node's
   entire content in both directions. A targeted `Edit` does not. (A `PostToolUse` hook already
   re-syncs org-roam's index after any edit under the roam directory — nothing else to do.)

### Split a section into a subnode
1. Identify the section in the root node that has outgrown its place
2. Create a new node titled `<project>/<domain>` tagged `["project", "knowledge", "<domain>"]`
3. Move the section content into the subnode (`Read`/`Edit` the files directly, per above)
4. Replace the section in the root with a brief summary and a link to the subnode
5. Add the subnode link to the root's `** Subnodes` section

## Promoting knowledge to CLAUDE.md

Some things saved here turn out to be durable and worth every collaborator seeing — not just
you. CLAUDE.md is checked into the repo and hand-maintained; project-brain is private and
auto-written. Don't blur that line by editing CLAUDE.md yourself.

If a gotcha, convention, or architectural note in this project's root/subnode has proven
stable and would help a fresh contributor or agent, **suggest** promoting it: tell the user what
you'd propose adding and to which file, and let them decide. Never edit CLAUDE.md on your own
initiative as part of this skill's save flow.
