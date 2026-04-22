# Tracking Kit

This folder is the operational memory layer for the project.

Use it to answer five questions quickly:

1. What are we doing now?
2. What is blocked?
3. What decisions are already settled?
4. What work is available next?
5. What evidence says a task is actually done?

## Files

- `board.md` — live execution board
- `backlog.md` — deferred and ready work that is not active
- `roadmap.md` — milestone-level direction
- `decisions.md` — durable decision log
- `agent-governance.md` — authority and collaboration rules
- `milestone-template.md` — reusable milestone brief
- `weekly-status-template.md` — reusable status update template

## Status Model

Keep status language consistent across the tracking kit:

- `Ready` — shaped work that can be pulled next, usually in `backlog.md`
- `Now` — currently active execution work on `board.md`
- `Blocked` — work that cannot move until a dependency, answer, or fix lands
- `Done` — work that exists and has been validated
- `Deferred` / `Later` / `Future` — intentionally non-active work, with lower commitment than `Ready`

Treat `Risks` and `Release / Pause State` as coordination signals, not task statuses.

## Verification Model

Treat verification as a first-class responsibility:

- assign a verifier for each major build or release candidate
- verify against intended behavior, not just whether a command completed
- record evidence before moving work to `Done`
- record gaps explicitly when verification is partial

The verifier may be the same person or agent as the tracking owner on small efforts, but the verification step should still be called out explicitly.

## Documentation Model

Treat documentation as a first-class responsibility when execution is substantial enough that project memory can drift:

- assign a documentarian for each major build or release candidate, or make the tracking owner explicitly absorb that role
- update durable tracking state after verification, not before it
- record decisions, current seam, risks, and next available work
- prefer compact state changes over transcript-like logs

The documentarian may be the same person or agent as the tracking owner on small efforts, but the documentation step should still be called out explicitly.

## Operating Rules

- Keep `board.md` current or the rest of the system decays.
- Record irreversible or high-impact choices in `decisions.md`.
- Do not let planning docs become changelogs.
- Do not mark work complete until the code or doc exists and the claimed validation has been run.
- Prefer editing an existing tracking file over creating a new one unless the new file has a clear purpose.
