Manage TODOs: local per-project TODOs stored in org-roam, and DAV todos (task lists synced
with a CalDAV server -- e.g. the user's phone reminders) when DAV sync is installed.

## When to use
Invoke when the user asks to add, list, update, or complete project TODOs or tasks, or
mentions their phone/reminders/DAV lists.

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

## DAV todos
Only applies if `azos-dav-sync` is on PATH (`command -v azos-dav-sync`); otherwise there are
no DAV todos on this machine. DAV todos are separate from project todos: they live in task
lists on a CalDAV server (synced to the user's phone, possibly other accounts), and are
managed with todoman's `todo` CLI over a local copy that `azos-dav-sync` keeps in sync.
Never edit the synced `.ics` files or the generated org view (`azos-dav-org-view` output)
directly.

- **Sync first, and after every change.** Run `azos-dav-sync` before reading and again right
  after any `todo` write, so the change reaches the server immediately. If it exits 75, the
  presence check failed (YubiKey not plugged in): carry on with the local copy, but tell the
  user the data may be stale and quote the last-sync time it printed. Writes made while
  unsynced are pushed on the next successful sync.
- **List:** `todo --porcelain list` (JSON; open items only — add `--status ANY` to include
  completed). Fields of interest: `id`, `list`, `summary`, `description`, `start`, `due`
  (epoch seconds; local midnight means a date-only value), `priority` (iCalendar: 1-4 high,
  5 medium, 6-9 low, 0 none), `recurring`. The available lists are the distinct `list`
  values (a list with no open items won't show up — ask the user if unsure).
- **Add:** `todo new --list "<list>" [--due "YYYY-MM-DD[ HH:MM]"] [--start ...] [--priority high|medium|low] "<summary>"`.
  If the user didn't say which list, ask. Note that todoman can't create alarms, so a timed
  task created this way won't ring on the phone — mention it when adding one with a time.
- **Mark done:** `todo done <id>`, with the `id` from a fresh `todo --porcelain list` (ids
  are local and can change between syncs). **Never complete a `recurring` item** — todoman
  mishandles recurrence (it forks a new task and drops the start date and alarm). Tell the
  user to tick recurring items off on their phone instead.
- **Edit:** `todo edit <id> [--due ...] [--priority ...]` etc. — same `recurring` caveat:
  leave recurring items to the phone.
- **Move a project todo to DAV:** only when the user asks. Create it with
  `todo new --list "<list>" "(<project>) <description>"`, sync, then remove the `* TODO`
  heading from `<project>/todos` (it lives in one place, not both).
