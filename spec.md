# Technical Specification: PoShWiKi

## 1. Overview
PoShWiKi is a minimalist, cross-platform wiki system built on PowerShell 7 and SQLite. It aims to be "agent-friendly," providing a CLI that is easy for both humans and LLMs to interact with.

## 2. Technical Stack
- **Runtime:** PowerShell 7.x (cross-platform).
- **Database:** SQLite (managed via `Microsoft.Data.Sqlite` .NET assembly).
- **Data Format:** Markdown for page content.
- **Output Formats:** Plain text (human-readable) and JSON/Object (agent-friendly).

## 3. Database Schema
A single `wiki.db` file with the following table:

### Table: `Pages`
- `Id`: INTEGER PRIMARY KEY AUTOINCREMENT
- `Title`: TEXT UNIQUE NOT NULL
- `Content`: TEXT NOT NULL
- `Created`: DATETIME DEFAULT CURRENT_TIMESTAMP
- `Modified`: DATETIME DEFAULT CURRENT_TIMESTAMP

## 4. CLI Commands (Internal Module)
- `Initialize-Wiki`: Creates the `wiki.db` and the `Pages` table.
- `Get-WikiPage -Title <string>`: Retrieves a page.
- `Set-WikiPage -Title <string> -Content <string>`: Creates or updates a page.
- `Get-WikiTemplateNames`: Lists built-in template names.
- `New-WikiPageFromTemplate -Template <string> -Title <string>`: Creates a page from a built-in template.
- `Update-WikiPageSection -Title <string> -Section <string> -Content <string>`: Replaces the body of an existing `##` section.
- `Add-WikiPageSectionContent -Title <string> -Section <string> -Content <string>`: Appends content to the body of an existing `##` section.
- `Set-WikiPageSection -Title <string> -Section <string> -Content <string>`: Updates an existing `##` section or creates it if missing.
- `Find-WikiPage -Query <string>`: Searches titles and content.
- `Get-WikiPageList`: Lists page titles and timestamps.
- `Get-WikiRecentPages`: Lists pages ordered by most recent modification.
- `Remove-WikiPage -Title <string>`: Deletes a page.
- `Get-WikiStats`: Shows total pages and DB size.

## 5. Deployment/Distribution
- Self-contained directory structure.
- `lib/` folder containing the necessary `Microsoft.Data.Sqlite` DLLs.
- `wiki.ps1` as the primary user-facing script.
- Database path defaults to `wiki.db` but may be overridden with `POSHWIKI_DB_PATH`.

## 6. Agent Governance
- CLI output must be consistent.
- Error messages must be descriptive and non-interactive.
- Support `-JSON` flag on retrieval and listing commands.
- JSON output should serialize plain PowerShell objects rather than raw `DataRow` / `DataTable` types.
- Human `get` output should render common Markdown patterns into readable terminal text without changing JSON output.
