Manage per-project TODOs stored in org-roam.

## When to use
Invoke when the user asks to add, list, update, or complete project TODOs or tasks.

## Convention
- TODOs live in a dedicated subnode, not the main project knowledge node
- Subnode title: `<project>/todos` (e.g. `azos/todos` for /home/user/azos)
- Subnode tags: `["project", "todo"]`
- TODOs are top-level headings: `* TODO <description>`
- Completed items: `* DONE <description>`
- When creating the subnode, also add a link to it in the root project node's `** Subnodes` section (if the root node exists)

## Steps

### Add a TODO
1. Get project name: basename of the current working directory
2. Search for the todos subnode via `mcp__org-roam__search_nodes` with `<project>/todos`
3. If no subnode exists: create one via `mcp__org-roam__create_node` (title = `<project>/todos`, tags = `["project", "todo"]`); then search for the root project knowledge node and add a link to the subnode in its `** Subnodes` section
4. Fetch current content via `mcp__org-roam__get_node`, append `* TODO <description>`, update via `mcp__org-roam__update_node`

### List TODOs
1. Get project name from the current working directory basename
2. Find the todos subnode via `mcp__org-roam__search_nodes` with `<project>/todos`
3. Fetch full content via `mcp__org-roam__get_node`
4. Display all headings prefixed with `* TODO`

### Mark a TODO done
1. Find the todos subnode as above
2. Fetch content, replace `* TODO <matching text>` with `* DONE <matching text>`
3. Update via `mcp__org-roam__update_node`

### Remove a TODO
1. Find the todos subnode as above
2. Fetch content, remove the matching heading line
3. Update via `mcp__org-roam__update_node`
