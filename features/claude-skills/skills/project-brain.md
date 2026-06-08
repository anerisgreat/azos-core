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
2. Search org-roam: `mcp__org-roam__search_nodes` using **only the project name as the query** — do NOT append "knowledge" or other words to the query string; the tag filter handles that
3. If found: fetch the root node with `mcp__org-roam__get_node` and incorporate into working context
4. If the session or task is clearly focused on a specific domain, also search for and load `<project>/<domain>` (e.g. search `azos/emacs`)
5. If not found: note that no prior knowledge exists yet for this project

### Save new knowledge (run after planning, research, or feature work — not just when explicitly asked)
1. Determine whether the knowledge belongs in the root node or a domain subnode
2. Search for the target node via `mcp__org-roam__search_nodes` (query = project name only)
3. If no node: create via `mcp__org-roam__create_node` with appropriate title and tags;
   if creating a subnode, also update the root's `** Subnodes` section with a link to it
4. Fetch current content with `mcp__org-roam__get_node`
5. Add new findings under the appropriate section, avoiding duplicates
6. **Before writing**: check whether any section now exceeds ~15 lines. If it does, split it
   into a subnode NOW rather than letting the root grow. Prefer many small focused nodes
   over one large node — a future session loads only what it needs.
7. Update via `mcp__org-roam__update_node`

### Split a section into a subnode
1. Identify the section in the root node that has outgrown its place
2. Create a new node titled `<project>/<domain>` tagged `["project", "knowledge", "<domain>"]`
3. Move the section content into the subnode
4. Replace the section in the root with a brief summary and a link to the subnode
5. Add the subnode link to the root's `** Subnodes` section
