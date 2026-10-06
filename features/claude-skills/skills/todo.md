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

## Resolving the todos subnode
Call `mcp__org-roam__search_nodes` with `<project>/todos` (substring search — pick the result
whose `title` is an exact match). The result already carries `{id, title, file, tags, aliases}` —
`Read` the returned `file` path directly. Never follow up with `mcp__org-roam__get_node` or
`get_node_by_title`: both re-fetch the full content you already have the path for, and you need
`Read` before any `Edit` regardless. If no exact-title match, the subnode doesn't exist yet.

## Steps

### Add a TODO
1. Get project name: basename of the current working directory
2. Resolve the todos subnode (see above)
3. If no subnode exists: create one via `mcp__org-roam__create_node` (title = `<project>/todos`, tags = `["project", "todo"]`); then resolve the root project knowledge node and `Edit` its `** Subnodes` section to link the new subnode
4. `Edit` the file to append `* TODO <description>`

### List TODOs
1. Get project name from the current working directory basename
2. Resolve the todos subnode (see above) and `Read` it, unless already read earlier this session
3. Display all headings prefixed with `* TODO`

### Mark a TODO done
1. Resolve the todos subnode as above
2. `Edit` the file, replacing `* TODO <matching text>` with `* DONE <matching text>`

### Remove a TODO
1. Resolve the todos subnode as above
2. `Edit` the file, removing the matching heading line
