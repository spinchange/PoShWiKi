# Board

Use these statuses consistently:

- `Now` - active work being executed
- `Next` - the next ready work to pull after `Now`
- `Blocked` - work that cannot proceed until an external dependency or decision is resolved
- `Later` - known work that is intentionally not active yet
- `Risks` - delivery threats, not tasks

Move work to `Done` only in status updates or milestone summaries after the code or doc exists and the claimed validation has been run.

## Now

- 

## Next

- [ ] Add basic Markdown rendering (to console or via external viewer).

## Blocked

- 

## Later

- [ ] Revise `Get-WikiPage` to handle multiple versions (if out-of-scope for now).

## Risks

- 

## Done

- [x] Phase 1: Dependency Management (SQLite DLLs).
- [x] Phase 2: Core Module Development (CRUD).
- [x] Phase 3: CLI Implementation (`wiki.ps1`).
- [x] Phase 4: Verification (Integrated tests pass in PowerShell 7).
- [x] Repo hardening: local git repo on `main`, `.gitignore`, manifest, README, and smoke test.
- [x] Added `list` command and plain object JSON output.

## Release / Pause State

- Current seam: Basic CRUD, search, list, docs, and smoke verification are functional.
- Minimum next step: Use it for actual notes or add Markdown-friendly display/rendering.
