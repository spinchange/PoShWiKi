# PoShWiKi

PoShWiKi is a minimal PowerShell 7 wiki backed by SQLite. It is designed to be usable from a terminal and easy for agents to script against.

## Requirements

- PowerShell 7 (`pwsh`)
- The bundled `lib/` directory in this repository

Windows PowerShell 5.1 is not supported.

## Database Path Override

By default, PoShWiKi uses `wiki.db` in the repository root. To point the CLI at a different database, set `POSHWIKI_DB_PATH` before running commands:

```powershell
$env:POSHWIKI_DB_PATH = ".\artifacts\scratch.db"
pwsh -NoProfile -File .\wiki.ps1 init
```

## Bootstrap

From the repository root:

```powershell
pwsh -NoProfile -File .\wiki.ps1 init
pwsh -NoProfile -File .\wiki.ps1 save Home "# Welcome to PoShWiKi"
pwsh -NoProfile -File .\wiki.ps1 get Home
pwsh -NoProfile -File .\wiki.ps1 list
```

For agent-friendly output, add `-JSON`:

```powershell
pwsh -NoProfile -File .\wiki.ps1 get Home -JSON
pwsh -NoProfile -File .\wiki.ps1 find Welcome -JSON
```

Without `-JSON`, `get` renders common Markdown patterns into terminal-friendly text for easier human reading.

## Commands

- `init` - initialize the SQLite database
- `get <title>` - fetch a page by title
- `templates` - list built-in page templates
- `new-page <template> <title>` - create a page from a built-in template
- `save <title> <text>` - save a page from inline text
- `set <title> <file>` - save a page from a file
- `update-section <title> <section> <text>` - replace an existing `##` section body
- `update-section <title> <section> -File <file>` - replace a section body from a file
- `append-section <title> <section> <text>` - append to an existing `##` section body
- `append-section <title> <section> -File <file>` - append to a section from a file
- `upsert-section <title> <section> <text>` - update an existing `##` section or create it
- `upsert-section <title> <section> -File <file>` - update or create a section from a file
- `find <query>` - search title and content
- `list` - list existing pages
- `recent` - list pages ordered by most recent modification
- `rm <title>` - remove a page
- `stats` - show database stats

## Smoke Test

Run the built-in smoke test:

```powershell
pwsh -NoProfile -File .\tests\smoke.ps1
```

Run the contract and error-path test:

```powershell
pwsh -NoProfile -File .\tests\contracts.ps1
```
