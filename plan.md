# Implementation Plan: PoShWiKi

## Phase 1: Dependency Management
1.  **Scaffold Lib Directory:** Create `C:\Users\user\Documents\PoShWiKi\lib`.
2.  **Pull NuGet Package:** Create a temporary .NET project, add `Microsoft.Data.Sqlite`, run `dotnet publish`, and copy the DLLs to `lib/`.
3.  **Verify Loading:** Test `Add-Type -Path lib\Microsoft.Data.Sqlite.dll` in PowerShell 7.

## Phase 2: Core Module Development
1.  **Create Module:** `C:\Users\user\Documents\PoShWiKi\PoShWiKi.psm1`.
2.  **Initialize DB Function:** Write `Initialize-Wiki` to create the `wiki.db` file and the `Pages` table using SQLite.
3.  **CRUD Functions:**
    - `Get-WikiPage` (SQL SELECT)
    - `Set-WikiPage` (SQL INSERT/UPDATE with UPSERT)
    - `Find-WikiPage` (SQL LIKE)
    - `Remove-WikiPage` (SQL DELETE)
4.  **Helper Functions:** Error handling, database connection management.

## Phase 3: CLI Implementation
1.  **Main Entry Script:** Create `C:\Users\user\Documents\PoShWiKi\wiki.ps1`.
2.  **Command Routing:** Handle command-line arguments (e.g., `.\wiki.ps1 get "MyPage"`).
3.  **Formatting:** Ensure clean, parsed output.

## Phase 4: Verification
1.  **Integration Test:**
    - `Initialize-Wiki`
    - `Set-WikiPage "Home" "# Welcome to PoShWiKi"`
    - `Get-WikiPage "Home"`
    - `Find-WikiPage "Welcome"`
    - `Remove-WikiPage "Home"`
2.  **Cross-Platform Check:** Verify the SQL strings are platform-neutral.
