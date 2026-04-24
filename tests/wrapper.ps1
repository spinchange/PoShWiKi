#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$wikiScript = Join-Path $repoRoot 'wiki.ps1'
$agentScript = Join-Path $repoRoot 'PoShWiKi.Agent.ps1'
$artifactsDir = Join-Path $repoRoot 'artifacts'
$dbPath = Join-Path $artifactsDir 'wrapper-wiki.db'

if (-not (Test-Path $artifactsDir)) {
    New-Item -ItemType Directory -Path $artifactsDir | Out-Null
}

if (Test-Path $dbPath) {
    Remove-Item -LiteralPath $dbPath -Force
}

$env:POSHWIKI_DB_PATH = $dbPath

function Assert-True {
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Condition,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

. $agentScript

pwsh -NoProfile -File $wikiScript init | Out-Null

$sessionPage = wiki-session-page 'Wrapper Validation'
Assert-True ($sessionPage -eq 'Session {0:yyyy-MM-dd} Wrapper Validation' -f (Get-Date)) 'Expected standard session page title format.'

$goalPage = 'Session 2026-04-22 Wrapper Goal'
$goalResult = wiki-note -Page $goalPage -Section 'Goal' -Text 'Verify missing pages are bootstrapped.'
Assert-True ($goalResult.Title -eq $goalPage) 'Expected wiki-note to return the updated page.'
Assert-True ($goalResult.Content -match '^# Session 2026-04-22 Wrapper Goal') 'Expected wiki-note to create a page stub with a heading.'
Assert-True ($goalResult.Content -match '## Goal') 'Expected wiki-note to create the requested section.'
Assert-True ($goalResult.Content -match 'Verify missing pages are bootstrapped\.') 'Expected wiki-note content to be present.'

$logPage = 'Session 2026-04-22 Wrapper Log'
$logResult = wiki-log -Page $logPage -Text 'Record the first action.'
Assert-True ($logResult.Title -eq $logPage) 'Expected wiki-log to return the updated page.'
Assert-True ($logResult.Content -match '## Actions') 'Expected wiki-log to create the default Actions section.'
Assert-True ($logResult.Content -match 'Record the first action\.') 'Expected wiki-log to append the provided content.'

$secondLogResult = wiki-log -Page $logPage -Text 'Record the second action.'
Assert-True ($secondLogResult.Content -match 'Record the first action\.') 'Expected previous log content to remain after a second append.'
Assert-True ($secondLogResult.Content -match 'Record the second action\.') 'Expected second log entry to be appended.'

$pageObject = wiki-get -Title $logPage
Assert-True ($pageObject.Title -eq $logPage) 'Expected wiki-get to return a page object.'

$textOutput = wiki-get -Title $logPage -Text | Out-String
Assert-True ($textOutput -match 'Session 2026-04-22 Wrapper Log') 'Expected wiki-get -Text output to include the page title.'
Assert-True ($textOutput -match 'Actions') 'Expected wiki-get -Text output to include section headings.'

$listedPages = @(wiki-list)
Assert-True (($listedPages | Where-Object Title -eq $goalPage).Count -eq 1) 'Expected wiki-list to include the goal page.'
Assert-True (($listedPages | Where-Object Title -eq $logPage).Count -eq 1) 'Expected wiki-list to include the log page.'

$foundPages = @(wiki-find -Query 'second action')
Assert-True (($foundPages | Where-Object Title -eq $logPage).Count -eq 1) 'Expected wiki-find to locate the logged page by content.'

$stats = wiki-stats
Assert-True ($stats.PageCount -eq 2) 'Expected wrapper test database to contain two pages.'

Write-Host 'Wrapper test passed.' -ForegroundColor Green
