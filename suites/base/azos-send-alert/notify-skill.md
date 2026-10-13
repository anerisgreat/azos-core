# Notify — sending alerts when tasks finish

Use `azos-send-alert` to push a notification when long tasks complete. The local desktop
notification always fires; the remote half (ntfy, Slack, a webhook...) is whatever command
this environment has configured.

## When to use proactively

When running (or suggesting) a command that will take more than ~30 seconds — training runs,
builds, deploys, downloads, test suites — append a notification automatically. Don't wait to
be asked.

## Background / async tasks (Claude Code specifically)

If you (the agent) are running a command via Bash that could take longer than
~10 minutes — large transfers, builds, training runs — and it might run in
the background (either because you set `run_in_background`, or because the
harness auto-backgrounds it after its timeout), chain the `azos-send-alert`
call **into that same command string from the start**. Don't wait until you
notice it's taking a while and then think about notifying — by then the
command is already running without it, and the harness's own "task
finished" signal only reaches this session, not the user's phone. Chaining
upfront is the only way to get a real push the moment it actually finishes:

```bash
rclone copy ... ; azos-send-alert -t "Backup" -p default -T "$([ $? -eq 0 ] && echo white_check_mark || echo x)" "rclone copy finished (exit $?)"
```

## Local commands

Append after the command so it fires on success only (`&&`) or always (`;`):

```bash
# Notify on success only
long_cmd && azos-send-alert "Task done"

# Always notify (even on failure) — prefer this for deploys/training
long_cmd; azos-send-alert -t "Training" -p high -T "$([ $? -eq 0 ] && echo white_check_mark || echo x)" "Exited $?"
```

## Remote commands (SSH / training machines)

Remote machines don't have `azos-send-alert`. Use `-r`/`--print-remote` to get a self-contained
command (the exact form depends on the configured remote command — e.g. a `curl` with a token
already embedded). The `$(...)` expands **locally**; the resulting command string is what the
remote machine executes.

```bash
ssh user@host "python train.py && $(azos-send-alert -r -t 'Training' -p high -T white_check_mark 'Model finished')"
```

## Flags

| Flag | Short | Values / notes |
|------|-------|----------------|
| `--title TITLE` | `-t` | Notification title |
| `--priority PRIO` | `-p` | `min` / `low` / `default` / `high` / `urgent` |
| `--tags TAGS` | `-T` | Comma-separated emoji shortcodes: `white_check_mark`, `x`, `warning`, `rotating_light`, `tada` |
| `--print-remote` | `-r` | Print a self-contained remote invocation instead of sending |

## Choosing priority and tags

- Routine completion (backup, build): `default` priority, `white_check_mark`
- Training / long job: `high` priority, `white_check_mark` on success / `x` on failure
- Something broke: `urgent` priority, `rotating_light`
