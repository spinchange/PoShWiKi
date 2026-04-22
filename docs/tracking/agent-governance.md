# Agent Governance

## Authority

- Define who owns authoritative updates to `docs/tracking/`.
- Other agents may propose tracking changes, but those changes are not authoritative until verified and applied by the owner.
- Define who owns verification authority for each major build or release candidate.

## Operating Roles

- `Tracking owner` maintains the authoritative state of `docs/tracking/`.
- `Verifier` checks whether a slice or build actually satisfies the claimed behavior and constraints.
- `Documentarian` keeps high-signal project memory current without turning tracking into a transcript.
- One person or agent may hold both roles on a small project, but the responsibilities should remain conceptually distinct.

## Delegation Rules

- Sidecar agents should prefer isolated write scopes.
- No agent should edit the same high-signal planning file in parallel with another agent unless explicitly coordinated.
- Shared planning files require explicit ownership.
- If a documentarian is assigned, define which tracking files they may update directly and which ones require tracking-owner approval.

## Verification Rules

- "Done" means the code or doc exists, the stated scope was actually changed, and the relevant validation was run when applicable.
- For docs, verify the file path, content, and any linked references.
- For code, verify behavior with the most direct practical checks.
- Verification must test both what the slice should do and any important behavior it must not break.
- If verification is partial, record the gap explicitly instead of implying full confidence.

## Major Build Verification

- Every major build should assign a named verifier before the build is treated as complete.
- The verifier should check the build against the current brief, spec, plan slice, or release intent, not just against raw execution output.
- The verifier should record:
  - what was verified
  - what commands or checks were run
  - whether the result is `Done`, `Blocked`, or still partial
  - any known gaps, regressions, or unverified edges
- If the build passes, the tracking owner may move the work to `Done` and update the current seam.
- If the build fails or remains ambiguous, keep it in `Now` or move it to `Blocked` with the reason attached.

## Status Rules

- Use `Ready`, `Now`, `Blocked`, and `Done` as the core lifecycle states for tracked work.
- Use `Deferred`, `Later`, and `Future` only for intentionally non-active work.
- Use `Completed` only in reporting views such as weekly status; it maps to `Done`.

## Invocation Rule

- On each major build, explicitly task the verifier to review the intended behavior, run the most direct practical checks, and report whether the build is actually ready to count as `Done`.

## Documentation Rules

- The documentarian should update durable state, not log every action.
- Good documentarian updates include:
  - status changes on the board
  - newly available next steps
  - decisions that became durable
  - verification outcomes and known gaps
  - the current seam for safe pause or handoff
- Avoid transcript-like notes, speculative status changes, or redundant restatements of commit output.

## Major Build Documentation

- Every major build should also assign a documentarian, unless the tracking owner is explicitly handling that function.
- After verification, the documentarian should update the relevant tracking files to reflect:
  - what moved to `Done`, `Blocked`, or remained in `Now`
  - what evidence exists for the claimed state
  - what the next clean seam is
  - any durable decisions or risks exposed by the build
- Documentation should happen as part of the build closeout, not as an optional later cleanup.

## Documentation Invocation Rule

- On each major build, explicitly task the documentarian to update the tracking artifacts after verification and before the build is treated as fully closed out.
