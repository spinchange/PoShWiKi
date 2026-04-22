# Handoff

## Project State

PoShWiKi is fully functional as a "smallest honest version." All core CRUD operations (get, set, find, rm, stats) are operational and verified in PowerShell 7.

## Completed

- Core SQLite module with dependency management (working cross-platform runtimes).
- CLI entry point (`wiki.ps1`) for basic management.
- Fixed a critical PowerShell unrolling bug in `Invoke-WikiSql`.
- Verified and initialized the database with test data.

## In Progress

- Filling in tracking documentation.

## Blocked

- None.

## Known Risks

- Dependency on PowerShell 7 (`pwsh`): The project cannot run in Windows PowerShell 5.1 due to `.NET Core` requirements.

## Important Context

- **PowerShell 7 Requirement:** You MUST use `pwsh` to run the wiki. Windows PowerShell 5.1 will fail to load the assemblies.
- **Unrolling Fix:** The `Invoke-WikiSql` function uses `return ,$table` to prevent PowerShell from unrolling its results.

## Next Recommended Step

Begin using the wiki for your knowledge base. Run `./wiki.ps1 stats` to confirm readiness. Consider adding a `list` command for easier discovery of existing pages.

## Verification

- `stats`: Success.
- `save`: Success.
- `get`: Success.
- `find`: Success.
- `rm`: Success.

## Key Artifacts

- `./wiki.ps1`: Primary entry point.
- `./PoShWiKi.psm1`: Core module.
- `./wiki.db`: The SQLite database.
