Load and save project knowledge in org-roam.

## When to use
- Proactively at the start of every session: load known context for the current project
- When you discover something significant not already stored
- When you need context you don't have: check org-roam before asking the user

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

### Subnodes (for large or specialized domains)
Split a section into a subnode when it grows beyond ~15–20 entries, or when it
covers a subsystem only relevant to specialized sessions.

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

### Load context (invoke at session start)
1. Get project name: basename of the current working directory
2. Search org-roam: `mcp__org-roam__search_nodes` with the project name and tag "knowledge"
3. If found: fetch root node with `mcp__org-roam__get_node` and incorporate into working context
4. If the session is clearly focused on a specific domain, also search for and load `<project>/<domain>`
5. If not found: note that no prior knowledge exists yet for this project

### Save new knowledge
1. Determine whether the knowledge belongs in the root node or a domain subnode
2. Search for the target node via `mcp__org-roam__search_nodes`
3. If no node: create via `mcp__org-roam__create_node` with appropriate title and tags;
   if creating a subnode, also update the root's `** Subnodes` section with a link to it
4. Fetch current content with `mcp__org-roam__get_node`
5. Add new findings under the appropriate section, avoiding duplicates
6. Update via `mcp__org-roam__update_node`

### Split a section into a subnode
1. Identify the section in the root node that has outgrown its place
2. Create a new node titled `<project>/<domain>` tagged `["project", "knowledge", "<domain>"]`
3. Move the section content into the subnode
4. Replace the section in the root with a brief summary and a link to the subnode
5. Add the subnode link to the root's `** Subnodes` section
