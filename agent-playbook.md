# Agent Playbook for PoShWiKi

## Goal

Use PoShWiKi as a local, scriptable memory store for an agent that needs to:

- capture durable notes
- look up prior decisions
- maintain running task context
- avoid rewriting entire documents when only one section changes

## Operating Rules

1. Always run through `pwsh` and `wiki.ps1`.
2. Prefer `-JSON` for reads and searches.
3. Store durable information in Markdown pages.
4. Use `save` only when creating or replacing a full page.
5. Use `upsert-section` for iterative updates.
6. Use `find`, `list`, and `recent` as discovery tools before creating duplicates.

## Suggested Page Types

### Stable Reference Pages

Use for information that should persist and be updated over time.

Examples:

- `Project Alpha`
- `Build Notes`
- `Local Environment`
- `PowerShell Tips`

Suggested structure:

```md
# Project Alpha

## Summary

Short description of what this page is for.

## Decisions

- Decision and rationale

## Commands

- Useful command lines

## Open Questions

- Unknowns to revisit
```

### Session Pages

Use for one working session or one task thread.

Naming pattern:

- `Session 2026-04-22 Repo Setup`
- `Session 2026-04-22 Bug Triage`

Suggested structure:

```md
# Session 2026-04-22 Repo Setup

## Goal

What the agent is trying to do.

## Actions

- Step taken

## Findings

- What was learned

## Next Steps

- Immediate follow-up work
```

## Recommended Agent Loop

### 1. Check readiness

```powershell
pwsh -NoProfile -File .\wiki.ps1 stats -JSON
```

### 2. Search before writing

```powershell
pwsh -NoProfile -File .\wiki.ps1 find "repo setup" -JSON
pwsh -NoProfile -File .\wiki.ps1 recent -JSON
```

### 3. Read the best matching page

```powershell
pwsh -NoProfile -File .\wiki.ps1 get "Project Alpha" -JSON
```

### 4. Write only what changed

Create a page:

```powershell
pwsh -NoProfile -File .\wiki.ps1 save "Project Alpha" "# Project Alpha`n`n## Summary`nInitial notes"
```

Update one section:

```powershell
pwsh -NoProfile -File .\wiki.ps1 upsert-section "Project Alpha" "Decisions" "- Use PowerShell 7 only"
```

Append to a running log:

```powershell
pwsh -NoProfile -File .\wiki.ps1 append-section "Session 2026-04-22 Repo Setup" "Actions" "- Cloned repository and initialized database."
```

## When To Write

Write when information becomes durable, costly to rediscover, or useful after a context switch.

### Good write points during a session

#### Session start

Create or refresh a session page with:

- goal
- scope
- constraints
- starting assumptions

Recommended command:

```powershell
pwsh -NoProfile -File .\wiki.ps1 upsert-section "Session 2026-04-22 Repo Setup" "Goal" "Set up PoShWiKi locally and define an agent usage pattern."
```

#### After environment discovery

Write facts that took work to uncover and may matter later.

Examples:

- required runtime
- file locations
- environment variables
- setup quirks
- test commands

Recommended command:

```powershell
pwsh -NoProfile -File .\wiki.ps1 upsert-section "Local Environment" "PoShWiKi" "- Requires PowerShell 7.`n- Database defaults to wiki.db in repo root."
```

#### After a decision

Write decisions as soon as they are made, especially if there was tradeoff analysis.

Examples:

- selected tool or library
- chosen database path
- naming convention
- rejected alternative

Recommended command:

```powershell
pwsh -NoProfile -File .\wiki.ps1 append-section "Project Alpha" "Decisions" "- Use session pages for short-lived work logs and reference pages for durable knowledge."
```

#### After completing a meaningful step

Append a short result when a meaningful unit of work finishes.

Examples:

- repository cloned
- database initialized
- tests passed
- bug reproduced
- migration applied

Recommended command:

```powershell
pwsh -NoProfile -File .\wiki.ps1 append-section "Session 2026-04-22 Repo Setup" "Actions" "- Smoke and contract tests passed after initialization."
```

#### When blocked

Write blockers when they are concrete enough to help with later recovery.

Capture:

- exact failure
- likely cause
- next diagnostic step

Recommended command:

```powershell
pwsh -NoProfile -File .\wiki.ps1 append-section "Session 2026-04-22 Repo Setup" "Blockers" "- Git clone initially failed inside sandbox; reran with approval."
```

#### When a workaround is found

These are high-value notes because they are easy to forget and expensive to rediscover.

Recommended command:

```powershell
pwsh -NoProfile -File .\wiki.ps1 append-section "Build Notes" "Workarounds" "- Use pwsh, not Windows PowerShell 5.1, or the module will fail to load."
```

#### Before a context switch

If the session is about to pause or move to another task, update:

- current state
- unfinished work
- next step

Recommended command:

```powershell
pwsh -NoProfile -File .\wiki.ps1 upsert-section "Session 2026-04-22 Repo Setup" "Next Steps" "- Add thin wrapper commands for wiki-note and wiki-log."
```

#### Session end

Close out the session page with the final state:

- findings
- decisions
- next steps

This is often the most valuable write of the session because it makes resumption cheap.

## When Not To Write

Skip writes for low-value noise.

Examples:

- every shell command
- obvious repo facts that can be found faster in source files
- speculative thinking that did not affect the outcome
- repeated status updates with no new information
- duplicate notes already stored on a better page

## Simple Write Rule

Write if at least one of these is true:

- it was expensive to discover
- it changes future decisions
- it will matter after a break
- it explains why something was done
- it captures a workaround or blocker

Otherwise, skip it.

## Command Mapping By Situation

- new page: `save`
- maintain a named section such as `Decisions` or `Next Steps`: `upsert-section`
- add chronological progress to a log section: `append-section`
- replace a section wholesale with corrected content: `update-section`

## Opinionated Usage Pattern

For an agent, this is the cleanest default split:

- `find` or `recent` before creating anything
- `get -JSON` before modifying an existing page
- `upsert-section` for decisions, findings, and next steps
- `append-section` for chronological logs
- `save` only for first creation or deliberate full replacement

That keeps pages stable while still letting the agent write incrementally.

## Good Defaults

### Use a dedicated database per workspace

```powershell
$env:POSHWIKI_DB_PATH = "C:\dev\repos\PoShWiKi\wiki.db"
```

For isolated experiments:

```powershell
$env:POSHWIKI_DB_PATH = "C:\dev\repos\PoShWiKi\artifacts\scratch.db"
```

### Prefer structured reads

Examples:

```powershell
pwsh -NoProfile -File .\wiki.ps1 list -JSON
pwsh -NoProfile -File .\wiki.ps1 recent -JSON
pwsh -NoProfile -File .\wiki.ps1 find "SQLite" -JSON
pwsh -NoProfile -File .\wiki.ps1 get "Build Notes" -JSON
```

## What I Would Standardize If Using This Daily

- One reference page per project or topic
- One session page per work session
- `## Decisions`, `## Findings`, and `## Next Steps` as standard sections
- `append-section` for logs, `upsert-section` for maintained knowledge
- JSON reads everywhere the agent needs to parse output

## Thin Wrapper Idea

If you want a cleaner operator experience, add shell functions like:

- `wiki-find`
- `wiki-get`
- `wiki-note`
- `wiki-log`

Where:

- `wiki-note` maps to `upsert-section`
- `wiki-log` maps to `append-section`

That would make PoShWiKi feel more like an agent memory API without changing the core project.
