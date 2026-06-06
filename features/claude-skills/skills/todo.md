Manage per-project TODOs stored in org-roam.

## When to use
Invoke when the user asks to add, list, update, or complete project TODOs or tasks.

## Convention
- Each project has a dedicated org-roam node named after the project directory basename
- Node title: basename of the current working directory (e.g. "azos" for /home/user/azos)
- Node tags: ["project", "todo"]
- TODOs are top-level headings: `* TODO <description>`
- Completed items: `* DONE <description>`

## Steps

### Add a TODO
1. Get project name: basename of the current working directory
2. Search for existing node via `mcp__org-roam__search_nodes` with the project name
3. If no node exists: create one via `mcp__org-roam__create_node` (title = project name, tags = ["project", "todo"])
4. Fetch current content via `mcp__org-roam__get_node`, append `* TODO <description>`, update via `mcp__org-roam__update_node`

### List TODOs
1. Get project name from the current working directory basename
2. Find the node via `mcp__org-roam__search_nodes`
3. Fetch full content via `mcp__org-roam__get_node`
4. Display all headings prefixed with `* TODO`

### Mark a TODO done
1. Find the node as above
2. Fetch content, replace `* TODO <matching text>` with `* DONE <matching text>`
3. Update via `mcp__org-roam__update_node`

### Remove a TODO
1. Find the node as above
2. Fetch content, remove the matching heading line
3. Update via `mcp__org-roam__update_node`
