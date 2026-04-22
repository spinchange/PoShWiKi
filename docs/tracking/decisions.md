# Decisions

Record decisions that affect scope, architecture, workflow, or user-facing behavior.

## Decision Log

### 2026-04-06 — Fix PowerShell DataTable Unrolling

- Decision: Use the comma operator (`,`) when returning `DataTable` objects from `Invoke-WikiSql`.
- Why: PowerShell unrolls `IEnumerable` objects (like `DataTable`'s rows) when they are emitted to the pipeline. This caused `Invoke-WikiSql` to return a `DataRow` instead of a `DataTable` when exactly one row was found, leading to "property not found" errors in callers like `Get-WikiPage` and `Get-WikiStats`.
- Tradeoff: This is a PowerShell-specific idiom that might look strange to those unfamiliar with it, but it's the standard way to return collections as single objects.
- Follow-up: Ensure all future database-query functions that expect a single result object use this pattern.

### 2026-04-06 — Target PowerShell 7 (pwsh)

- Decision: Explicitly use `pwsh` (PowerShell Core) for execution.
- Why: The project dependencies (`Microsoft.Data.Sqlite` 10.x) are designed for `.NET Core` and fail to load in Windows PowerShell 5.1 (the default `powershell.exe`).
- Tradeoff: Limits usage to environments where PowerShell 7+ is installed (though this matches the project's original goal).
- Follow-up: Ensure `wiki.ps1` shebang or documentation reflects this requirement.
