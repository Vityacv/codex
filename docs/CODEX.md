# Session Working Directory Workflow

## Recent Workspace Changes

- Added directory-aware filtering to `codex resume`; unless `--all-dirs` is passed, the picker lists only sessions whose rollout metadata matches the current working directory.
- Introduced the `--all-dirs` flag to `codex resume` so you can intentionally browse every recorded session.
- Added a `Ctrl+U` shortcut in the resume picker so you can sort sessions by the **Updated** column (newest edits first).
- Updated `build_release.sh` to fetch upstream changes before rebuilding and to emit release binaries without debug info.
- Documented working-directory behavior and recovery steps in this guide.

Codex records the working directory for every interactive session the moment it starts. This value is written into the first line of the rollout file under `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl` and is used when listing or resuming saved runs.

## Starting or Resuming in a Specific Directory

Use the `--cd` (or `-C`) flag to set the working root before the session begins:

```shell
codex --cd /path/to/project
codex resume --cd /path/to/project
```

If you omit `--cd`, Codex uses the current shell directory. From there:

- `codex resume` filters the picker to sessions that were originally recorded in the current directory.
- `codex resume --last` finds the most recent session for the current directory, scanning additional pages if needed.
- `codex resume --all-dirs` disables the filter and shows sessions from every recorded directory.
- Inside the picker, press <kbd>Ctrl</kbd>+<kbd>U</kbd> to toggle sorting by the **Updated** column if you want to see the most recently edited sessions first.

## Changing the Directory for an Existing Session

The recorded working directory is embedded in the session metadata and cannot be changed mid-run. To work from a different folder:

1. Resume the existing session with `codex resume --all-dirs --cd /new/path`. The live conversation will operate in `/new/path`, but the historical metadata remains unchanged.
2. (Advanced) Manually edit the `session_meta` line in the corresponding rollout file to update the `"cwd"` field. Always make a backup before editing; malformed JSON will break the session history.
3. Start a fresh session with `codex --cd /new/path` so the metadata, filters, and directory align automatically.

Choose the option that best fits your workflow. When in doubt, prefer launching a new session or using `--cd` alongside `--all-dirs` rather than editing rollout files by hand.
