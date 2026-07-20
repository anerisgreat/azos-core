Track daily work history entries in org-roam nodes and retrieve or archive them on demand.

TRIGGER on: (1) proactively after significant work in the current session (feature implemented, bug fixed, design completed, non-trivial refactor finished); (2) explicit user request (log work history, show history, archive history, /work-history); (3) session end when meaningful work was done. Skip trivial actions — file browsing, reading docs, minor edits with no user-visible effect.

This skill does NOT replace `project-brain` (architecture/conventions) or `todo` (task tracking). It records *what was done*, not what to do or how things work.

## Node structure

- Recent node title: `<project>/work-history/recent` — tags: `["project", "work-history"]`
- Archive node titles: `<project>/work-history/archive/YYYY/MM` — tags: `["project", "work-history", "archive"]`
- Day headings inside nodes: `* YYYY-MM-DD Ddd` (e.g. `* 2026-07-20 Sun`), newest first
- Entries: past-tense bullets under the day heading (`- Implemented X`, `- Fixed Y`, `- Debugged Z`)
- The recent node has a `** Archives` section at the bottom linking to any archive nodes

## Operations

### Log (default)

1. Get today's date in `YYYY-MM-DD Ddd` format (e.g. `2026-07-20 Sun`)
2. Get project name: basename of the current working directory
3. Call `mcp__org-roam__get_node_by_title` with `<project>/work-history/recent`
4. If not found:
   a. Create via `mcp__org-roam__create_node` with title `<project>/work-history/recent`, tags `["project", "work-history"]`, and initial body:
      ```
      * YYYY-MM-DD Ddd

      - <first entry>

      ** Archives
      ```
   b. Find the root project knowledge node via `mcp__org-roam__get_node_by_title` with `<project>`. If found, add a link to the recent node in its `** Subnodes` section and update it via `mcp__org-roam__update_node`
   c. Done — skip to step 7
5. Fetch full content via `mcp__org-roam__get_node`
6. If a heading matching today's date already exists: append the new bullet(s) under it. If not: insert a new `* YYYY-MM-DD Ddd` heading at the top of the body (before any existing day headings, after the property drawer), with the new bullet(s) beneath it
7. Update via `mcp__org-roam__update_node`
8. Count the lines in the node body. If it exceeds ~200 lines, run the Archive operation automatically and inform the user

### Read

1. Get project name: basename of the current working directory
2. Call `mcp__org-roam__get_node_by_title` with `<project>/work-history/recent`
3. If not found: report that no work history exists yet for this project
4. Fetch full content via `mcp__org-roam__get_node`
5. Filter and display day headings and their bullets from the last 7 days (default). For each heading, check whether the date is within the cutoff
6. If the user asks for older history: use `mcp__org-roam__search_nodes` with `<project>/work-history/archive` to locate monthly archive nodes, then fetch the relevant one(s) via `mcp__org-roam__get_node` and display the matching entries

### Archive

Moves entries older than 30 days from the recent node into monthly archive nodes.

1. Get project name: basename of the current working directory
2. Call `mcp__org-roam__get_node_by_title` with `<project>/work-history/recent`; fetch its content via `mcp__org-roam__get_node`
3. Partition day headings: identify entries with dates older than 30 days from today
4. Group old entries by `YYYY/MM`
5. For each month group:
   a. Determine the archive node title: `<project>/work-history/archive/YYYY/MM`
   b. Call `mcp__org-roam__get_node_by_title` on that title
   c. If not found: create via `mcp__org-roam__create_node` (title as above, tags `["project", "work-history", "archive"]`)
   d. Fetch existing content via `mcp__org-roam__get_node`; append the archived day headings (maintaining newest-first order within the archive node)
   e. Update the archive node via `mcp__org-roam__update_node`
6. Rewrite the recent node, keeping only the last 30 days of entries. In the `** Archives` section, add a link for each newly created archive node (skip if a link already exists)
7. Update the recent node via `mcp__org-roam__update_node`
8. Report how many entries were archived and which monthly nodes were created or updated
