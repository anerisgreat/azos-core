Talk through daily/weekly task planning across all projects and keep the plan in a dedicated cross-project `workplate` node in org-roam.

## When to use
Invoke on `/workplate`, or whenever the user wants to plan today's tasks, think through a weekly schedule, or mentions "workplate".

This skill does not own task tracking — that's `todo` (per-project, in `<project>/todos`). Workplate references those tasks rather than duplicating them, and is the place for deciding what to actually work on and roughly when. It also doesn't log what was done — that's `work-history`.

## Convention
- Single cross-project node, title `workplate`, tags `["workplate", "planning"]` — not scoped to the current directory, since a plan spans projects
- Effort estimates are loose, one of: `quick`, `few-hours`, `half-day`, `whole-day` — never clock-time estimates
- Body structure (org headings, so TODO/DONE keywords behave normally):
  ```
  * Today (YYYY-MM-DD Ddd)
  ** TODO [effort] (project) task description
  ** DONE [effort] (project) task description

  * This Week (YYYY-MM-DD to YYYY-MM-DD)
  ** TODO [effort] (project) task description
  ```
- Keep task wording close to the source TODO so it's recognizable, and always note the source project in parens
- The node links to each referenced project's `<project>/todos` node once (via `mcp__org-roam__add_link`), not per task

## Steps

### Plan today
1. `mcp__org-roam__get_node_by_title` with `workplate`. If not found, create via `mcp__org-roam__create_node` (title `workplate`, tags `["workplate", "planning"]`) with an initial body containing empty `* Today` and `* This Week` headings.
2. Find candidate tasks: `mcp__org-roam__search_nodes` for todo nodes (title pattern `/todos`). Fetch each hit via `mcp__org-roam__get_node` and collect its `* TODO` headings, noting the project name from the node title.
3. Talk it through with the user conversationally: carry over any unfinished `** TODO` items under today's existing heading if replanning, surface newly-relevant items from each project's todo list, and gauge roughly how much is realistic for today. Keep it to a handful of items with loose effort tags — this is a realistic plate, not a packed schedule.
4. Agree on today's list with the user, each tagged with a loose effort estimate.
5. Fetch current `workplate` content. Replace the `* Today (...)` heading and its `**` items wholesale with the new date and list (don't append onto a stale day).
6. For each referenced project not already linked from the node, add a link to its `<project>/todos` node via `mcp__org-roam__add_link`.
7. Update via `mcp__org-roam__update_node`.

### Plan the week
Same as "Plan today" but targets the `* This Week (...)` heading, using the Monday–Sunday date range of the current week. Keep it higher-level than the daily plan — a handful of themes/goals per project, not a granular task list.

### Mark a workplate item done
1. Fetch the `workplate` node.
2. Replace the matching `** TODO ...` heading (today or this week) with `** DONE ...`.
3. Update via `mcp__org-roam__update_node`.
4. If the item also exists as a `* TODO` in its source project's `<project>/todos` node, ask whether to mark it done there too via the `todo` skill — don't do it silently, since "done for today's push" and "fully done" aren't always the same thing.

### Review the plate
1. Fetch the `workplate` node.
2. Display the `* Today` and `* This Week` sections as-is.
