Track daily work history entries in org-roam nodes and retrieve or archive them on demand.

TRIGGER on: (1) proactively after significant work in the current session (feature implemented, bug fixed, design completed, non-trivial refactor finished); (2) explicit user request (log work history, show history, archive history, /work-history); (3) session end when meaningful work was done. Skip trivial actions — file browsing, reading docs, minor edits with no user-visible effect.

This skill does NOT replace `project-brain` (architecture/conventions) or `todo` (task tracking). It records *what was done*, not what to do or how things work.

## Node structure

- Recent node title: `<project>/work-history/recent` — tags: `["project", "work-history"]`
- Archive node titles: `<project>/work-history/archive/YYYY/MM` — tags: `["project", "work-history", "archive"]`
- Day headings inside nodes: `* YYYY-MM-DD Ddd` (e.g. `* 2026-07-20 Sun`), newest first
- Entries: past-tense bullets under the day heading (`- Implemented X`, `- Fixed Y`, `- Debugged Z`)
- The recent node has a `** Archives` section at the bottom linking to any archive nodes

## Resolving a node's file
Call `mcp__org-roam__search_nodes` with the node's title (exact titles work fine as a query
since it's substring search — pick the result whose `title` is an exact match). The result
already carries `{id, title, file, tags, aliases}` — `Read` the returned `file` path directly.
Never follow up with `mcp__org-roam__get_node` or `get_node_by_title`: both re-fetch content you
already have the path for, and you need `Read` before any `Edit` regardless. If no exact-title
match, the node doesn't exist yet.

## Operations

### Log (default)

1. Get today's date in `YYYY-MM-DD Ddd` format (e.g. `2026-07-20 Sun`)
2. Get project name: basename of the current working directory
3. Resolve `<project>/work-history/recent` (see above)
4. If not found:
   a. Create via `mcp__org-roam__create_node` with title `<project>/work-history/recent`, tags `["project", "work-history"]`, and initial body:
      ```
      * YYYY-MM-DD Ddd

      - <first entry>

      ** Archives
      ```
   b. Resolve the root project knowledge node (`<project>`). If found, `Edit` its `** Subnodes` section to link the recent node
   c. Done — skip to step 7
5. `Read` the file, unless already read earlier this session
6. If a heading matching today's date already exists: `Edit` to append the new bullet(s) under it. If not: `Edit` to insert a new `* YYYY-MM-DD Ddd` heading at the top of the body (before any existing day headings, after the property drawer), with the new bullet(s) beneath it
7. Count the lines in the node body. If it exceeds ~200 lines, run the Archive operation automatically and inform the user

### Read

1. Get project name: basename of the current working directory
2. Resolve `<project>/work-history/recent` (see above)
3. If not found: report that no work history exists yet for this project
4. `Read` the file, unless already read earlier this session
5. Filter and display day headings and their bullets from the last 7 days (default). For each heading, check whether the date is within the cutoff
6. If the user asks for older history: use `mcp__org-roam__search_nodes` with `<project>/work-history/archive` to locate monthly archive nodes, then `Read` the relevant one(s) and display the matching entries

### Archive

Moves entries older than 30 days from the recent node into monthly archive nodes.

1. Get project name: basename of the current working directory
2. Resolve and `Read` `<project>/work-history/recent` (see above)
3. Partition day headings: identify entries with dates older than 30 days from today
4. Group old entries by `YYYY/MM`
5. For each month group:
   a. Determine the archive node title: `<project>/work-history/archive/YYYY/MM`
   b. Resolve that title (see above)
   c. If not found: create via `mcp__org-roam__create_node` (title as above, tags `["project", "work-history", "archive"]`)
   d. `Read` the file if it already existed; `Edit` to append the archived day headings (maintaining newest-first order within the archive node)
6. `Edit` the recent node, keeping only the last 30 days of entries. In the `** Archives` section, add a link for each newly created archive node (skip if a link already exists)
7. Report how many entries were archived and which monthly nodes were created or updated
