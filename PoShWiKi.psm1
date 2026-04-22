# PoShWiKi.psm1 - Core Module for PowerShell Wiki

$Script:LibPath = Join-Path $PSScriptRoot "lib"

function Get-WikiDatabasePath {
    $overridePath = $env:POSHWIKI_DB_PATH
    if (-not [string]::IsNullOrWhiteSpace($overridePath)) {
        return $overridePath
    }

    return Join-Path $PSScriptRoot "wiki.db"
}

$Script:DbPath = Get-WikiDatabasePath

# Load Assemblies
function Import-SqliteAssemblies {
    $dlls = @(
        "SQLitePCLRaw.core.dll",
        "SQLitePCLRaw.provider.e_sqlite3.dll",
        "SQLitePCLRaw.batteries_v2.dll",
        "Microsoft.Data.Sqlite.dll"
    )

    foreach ($dll in $dlls) {
        $path = Join-Path $Script:LibPath $dll
        if (Test-Path $path) {
            Add-Type -Path $path -ErrorAction SilentlyContinue
        }
    }

    # Manually load native library if possible
    $os = if ($IsWindows) { "win" } elseif ($IsLinux) { "linux" } elseif ($IsMacOS) { "osx" } else { "unknown" }
    $arch = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLower()
    
    # Map architectures to runtime names
    $runtimeArch = switch ($arch) {
        "x64" { "x64" }
        "arm64" { "arm64" }
        "x86" { "x86" }
        "arm" { "arm" }
        default { $arch }
    }

    $nativeLibName = if ($IsWindows) { "e_sqlite3.dll" } elseif ($IsMacOS) { "libe_sqlite3.dylib" } else { "libe_sqlite3.so" }
    $nativePath = Join-Path $Script:LibPath "runtimes/$os-$runtimeArch/native/$nativeLibName"

    if (Test-Path $nativePath) {
        try {
            [Runtime.InteropServices.NativeLibrary]::Load($nativePath)
        } catch {
            Write-Warning "Failed to load native library via NativeLibrary.Load: $_"
        }
    }

    # Initialize SQLitePCLRaw batteries to handle native library loading
    try {
        [SQLitePCL.Batteries]::Init()
    } catch {
        Write-Warning "Failed to initialize SQLite batteries: $_"
    }
}

Import-SqliteAssemblies

function Get-WikiConnection {
    $connectionString = "Data Source=$Script:DbPath"
    $connection = [Microsoft.Data.Sqlite.SqliteConnection]::new($connectionString)
    $connection.Open()
    return $connection
}

function Invoke-WikiSql {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,
        [hashtable]$Parameters = @{}
    )

    $connection = Get-WikiConnection
    try {
        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        foreach ($key in $Parameters.Keys) {
            $command.Parameters.AddWithValue("@$key", $Parameters[$key]) | Out-Null
        }

        $reader = $command.ExecuteReader()
        $results = @()

        while ($reader.Read()) {
            $row = [ordered]@{}
            for ($i = 0; $i -lt $reader.FieldCount; $i++) {
                $value = if ($reader.IsDBNull($i)) { $null } else { $reader.GetValue($i) }
                $row[$reader.GetName($i)] = $value
            }

            $results += [PSCustomObject]$row
        }

        return @($results)
    }
    finally {
        $connection.Close()
        $connection.Dispose()
    }
}

function Invoke-WikiNonQuery {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Query,
        [hashtable]$Parameters = @{}
    )

    $connection = Get-WikiConnection
    try {
        $command = $connection.CreateCommand()
        $command.CommandText = $Query
        foreach ($key in $Parameters.Keys) {
            $command.Parameters.AddWithValue("@$key", $Parameters[$key]) | Out-Null
        }
        return $command.ExecuteNonQuery()
    }
    finally {
        $connection.Close()
        $connection.Dispose()
    }
}

function Save-WikiPageContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $query = @"
INSERT INTO Pages (Title, Content, Modified)
VALUES (@Title, @Content, CURRENT_TIMESTAMP)
ON CONFLICT(Title) DO UPDATE SET
    Content = excluded.Content,
    Modified = CURRENT_TIMESTAMP;
"@
    Invoke-WikiNonQuery -Query $query -Parameters @{ Title = $Title; Content = $Content } | Out-Null
}

function Convert-WikiMarkdownToDisplayText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $lines = ($Content -replace "`r`n", "`n") -split "`n"
    $output = New-Object System.Collections.Generic.List[string]
    $inCodeBlock = $false

    foreach ($line in $lines) {
        if ($line -match '^\s*```') {
            if (-not $inCodeBlock) {
                $output.Add('[code]')
                $inCodeBlock = $true
            } else {
                $inCodeBlock = $false
            }
            continue
        }

        if ($inCodeBlock) {
            $output.Add("    $line")
            continue
        }

        if ($line -match '^#\s+(.+)$') {
            $text = $matches[1].Trim()
            $output.Add($text)
            $output.Add(('=' * $text.Length))
            continue
        }

        if ($line -match '^##\s+(.+)$') {
            $text = $matches[1].Trim()
            $output.Add('')
            $output.Add($text)
            $output.Add(('-' * $text.Length))
            continue
        }

        if ($line -match '^###\s+(.+)$') {
            $output.Add('')
            $output.Add("-> $($matches[1].Trim())")
            continue
        }

        if ($line -match '^\s*[-*]\s+(.+)$') {
            $output.Add("• $($matches[1])")
            continue
        }

        if ($line -match '^\s*>\s+(.+)$') {
            $output.Add("│ $($matches[1])")
            continue
        }

        $output.Add($line)
    }

    return ($output -join [Environment]::NewLine).TrimEnd()
}

function Initialize-Wiki {
    [CmdletBinding()]
    param()

    Write-Host "Initializing Wiki database at $Script:DbPath..." -ForegroundColor Cyan
    
    $query = @"
CREATE TABLE IF NOT EXISTS Pages (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    Title TEXT UNIQUE NOT NULL,
    Content TEXT NOT NULL,
    Created DATETIME DEFAULT CURRENT_TIMESTAMP,
    Modified DATETIME DEFAULT CURRENT_TIMESTAMP
);
"@
    Invoke-WikiNonQuery -Query $query
    Write-Host "Success: Database initialized." -ForegroundColor Green
}

function Get-WikiPage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Title
    )

    $query = "SELECT * FROM Pages WHERE Title = @Title"
    $results = Invoke-WikiSql -Query $query -Parameters @{ Title = $Title }
    
    if ($results.Count -eq 0) {
        Write-Error "Page '$Title' not found."
        return $null
    }

    return $results[0]
}

function Set-WikiPage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Title,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$Content
    )

    Save-WikiPageContent -Title $Title -Content $Content
    Write-Host "Page '$Title' saved." -ForegroundColor Green
}

function Get-WikiTemplateNames {
    [CmdletBinding()]
    param()

    return @(
        [PSCustomObject]@{ Name = 'project' }
        [PSCustomObject]@{ Name = 'decision' }
        [PSCustomObject]@{ Name = 'handoff' }
        [PSCustomObject]@{ Name = 'task' }
        [PSCustomObject]@{ Name = 'debug' }
        [PSCustomObject]@{ Name = 'runbook' }
    )
}

function New-WikiPageFromTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Template,

        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    $templateKey = $Template.ToLowerInvariant()
    $fullTitle = switch ($templateKey) {
        'project' { "Project: $Title" }
        'decision' { "Decision: $Title" }
        'handoff' { "Handoff: $Title" }
        'task' { "Task: $Title" }
        'debug' { "Debug: $Title" }
        'runbook' { "Runbook: $Title" }
        default {
            Write-Error "Unknown template '$Template'."
            return $null
        }
    }

    $content = switch ($templateKey) {
        'project' {
@"
# $fullTitle

## Purpose


## Current Capabilities


## Working Rule


## Primary Note Types


"@
        }
        'decision' {
@"
# $fullTitle

## Decision


## Reasoning


## Tradeoffs


## Revisit When


"@
        }
        'handoff' {
@"
# $fullTitle

## Current Seam


## Verified


## Immediate Next Moves


## Constraints


"@
        }
        'task' {
@"
# $fullTitle

## Status


## Goal


## Scope


## Acceptance


"@
        }
        'debug' {
@"
# $fullTitle

## Issue


## Reproduction


## Observed Behavior


## Root Cause


## Fix


## Status


"@
        }
        'runbook' {
@"
# $fullTitle

## Purpose


## Prerequisites


## Commands


## Verification


"@
        }
    }

    Save-WikiPageContent -Title $fullTitle -Content $content
    return Get-WikiPage -Title $fullTitle
}

function Update-WikiPageSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Section,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $page = Get-WikiPage -Title $Title
    if (-not $page) {
        return $null
    }

    $normalized = ([string]$page.Content) -replace "`r`n", "`n"
    $escapedSection = [Regex]::Escape($Section)
    $pattern = "(?ms)^##\s+$escapedSection\s*\n.*?(?=^##\s+|\z)"
    $match = [Regex]::Match($normalized, $pattern)

    if (-not $match.Success) {
        Write-Error "Section '$Section' not found in page '$Title'."
        return $null
    }

    $replacementContent = $Content -replace "`r`n", "`n"
    $replacement = "## $Section`n$replacementContent`n"
    $updated = [Regex]::Replace($normalized, $pattern, $replacement, 1)
    $finalContent = $updated -replace "`n", [Environment]::NewLine

    $query = @"
INSERT INTO Pages (Title, Content, Modified)
VALUES (@Title, @Content, CURRENT_TIMESTAMP)
ON CONFLICT(Title) DO UPDATE SET
    Content = excluded.Content,
    Modified = CURRENT_TIMESTAMP;
"@
    Save-WikiPageContent -Title $Title -Content $finalContent
    return Get-WikiPage -Title $Title
}

function Add-WikiPageSectionContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Section,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $page = Get-WikiPage -Title $Title
    if (-not $page) {
        return $null
    }

    $normalized = ([string]$page.Content) -replace "`r`n", "`n"
    $escapedSection = [Regex]::Escape($Section)
    $pattern = "(?ms)^##\s+$escapedSection\s*\n.*?(?=^##\s+|\z)"
    $match = [Regex]::Match($normalized, $pattern)

    if (-not $match.Success) {
        Write-Error "Section '$Section' not found in page '$Title'."
        return $null
    }

    $sectionText = $match.Value.TrimEnd("`n")
    $appendContent = $Content -replace "`r`n", "`n"
    $replacement = "$sectionText`n$appendContent`n"
    $updated = [Regex]::Replace($normalized, $pattern, $replacement, 1)
    $finalContent = $updated -replace "`n", [Environment]::NewLine

    $query = @"
INSERT INTO Pages (Title, Content, Modified)
VALUES (@Title, @Content, CURRENT_TIMESTAMP)
ON CONFLICT(Title) DO UPDATE SET
    Content = excluded.Content,
    Modified = CURRENT_TIMESTAMP;
"@
    Save-WikiPageContent -Title $Title -Content $finalContent
    return Get-WikiPage -Title $Title
}

function Set-WikiPageSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Section,

        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $page = Get-WikiPage -Title $Title
    if (-not $page) {
        return $null
    }

    $normalized = ([string]$page.Content) -replace "`r`n", "`n"
    $escapedSection = [Regex]::Escape($Section)
    $pattern = "(?ms)^##\s+$escapedSection\s*\n.*?(?=^##\s+|\z)"
    $replacementContent = $Content -replace "`r`n", "`n"
    $replacement = "## $Section`n$replacementContent`n"

    if ([Regex]::IsMatch($normalized, $pattern)) {
        $updated = [Regex]::Replace($normalized, $pattern, $replacement, 1)
    } else {
        $suffix = if ($normalized.EndsWith("`n")) { "" } else { "`n" }
        $updated = "$normalized$suffix`n$replacement"
    }

    $finalContent = $updated -replace "`n", [Environment]::NewLine

    Save-WikiPageContent -Title $Title -Content $finalContent
    return Get-WikiPage -Title $Title
}

function Find-WikiPage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Query
    )

    $sqlQuery = "SELECT Title, Created, Modified FROM Pages WHERE Title LIKE @Q OR Content LIKE @Q"
    $results = Invoke-WikiSql -Query $sqlQuery -Parameters @{ Q = "%$Query%" }
    return @($results)
}

function Get-WikiPageList {
    [CmdletBinding()]
    param()

    $query = "SELECT Title, Created, Modified FROM Pages ORDER BY Title"
    $results = Invoke-WikiSql -Query $query
    return @($results)
}

function Get-WikiRecentPages {
    [CmdletBinding()]
    param()

    $query = "SELECT Title, Created, Modified FROM Pages ORDER BY Modified DESC, Title ASC"
    $results = Invoke-WikiSql -Query $query
    return @($results)
}

function Remove-WikiPage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Title
    )

    $query = "DELETE FROM Pages WHERE Title = @Title"
    $rowsAffected = Invoke-WikiNonQuery -Query $query -Parameters @{ Title = $Title }
    
    if ($rowsAffected -gt 0) {
        Write-Host "Page '$Title' deleted." -ForegroundColor Yellow
    } else {
        Write-Warning "Page '$Title' did not exist."
    }
}

function Get-WikiStats {
    $query = "SELECT COUNT(*) as Total FROM Pages"
    $results = Invoke-WikiSql -Query $query
    
    $pageCount = 0
    if ($results.Count -gt 0) {
        $pageCount = $results[0].Total
    }
    
    $dbFile = Get-Item $Script:DbPath -ErrorAction SilentlyContinue
    $size = if ($dbFile) { "$([Math]::Round($dbFile.Length / 1KB, 2)) KB" } else { "N/A" }

    return [PSCustomObject]@{
        PageCount = $pageCount
        DatabaseSize = $size
        Path = $Script:DbPath
    }
}

Export-ModuleMember -Function Initialize-Wiki, Get-WikiPage, Set-WikiPage, Get-WikiTemplateNames, New-WikiPageFromTemplate, Convert-WikiMarkdownToDisplayText, Update-WikiPageSection, Add-WikiPageSectionContent, Set-WikiPageSection, Find-WikiPage, Get-WikiPageList, Get-WikiRecentPages, Remove-WikiPage, Get-WikiStats
