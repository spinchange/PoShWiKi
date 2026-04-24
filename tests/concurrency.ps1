#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$wikiScript = Join-Path $repoRoot 'wiki.ps1'
$artifactsDir = Join-Path $repoRoot 'artifacts'
$dbPath = Join-Path $artifactsDir 'concurrency-wiki.db'
$roundCount = 8

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

pwsh -NoProfile -File $wikiScript init | Out-Null

for ($round = 1; $round -le $roundCount; $round++) {
    $title = "Concurrency Test Page $round"
    pwsh -NoProfile -File $wikiScript save $title "# $title" | Out-Null

    $jobs = @(
        Start-Job -ScriptBlock {
            param($ScriptPath, $PageTitle, $DatabasePath)
            $env:POSHWIKI_DB_PATH = $DatabasePath
            & pwsh -NoProfile -File $ScriptPath upsert-section $PageTitle 'Goal' 'Concurrency goal' -JSON
        } -ArgumentList $wikiScript, $title, $dbPath
        Start-Job -ScriptBlock {
            param($ScriptPath, $PageTitle, $DatabasePath)
            $env:POSHWIKI_DB_PATH = $DatabasePath
            & pwsh -NoProfile -File $ScriptPath upsert-section $PageTitle 'Findings' 'Concurrency finding' -JSON
        } -ArgumentList $wikiScript, $title, $dbPath
        Start-Job -ScriptBlock {
            param($ScriptPath, $PageTitle, $DatabasePath)
            $env:POSHWIKI_DB_PATH = $DatabasePath
            & pwsh -NoProfile -File $ScriptPath upsert-section $PageTitle 'Next Steps' 'Concurrency next step' -JSON
        } -ArgumentList $wikiScript, $title, $dbPath
    )

    $null = $jobs | Wait-Job
    $null = $jobs | Receive-Job
    $jobFailures = @($jobs | Where-Object State -ne 'Completed')
    $jobs | Remove-Job -Force

    Assert-True ($jobFailures.Count -eq 0) "Expected all concurrent update jobs to complete in round $round."

    $page = pwsh -NoProfile -File $wikiScript get $title -JSON | ConvertFrom-Json

    Assert-True ($page.Content -match '## Goal') "Expected final page to contain the Goal section after concurrent writes in round $round."
    Assert-True ($page.Content -match '## Findings') "Expected final page to contain the Findings section after concurrent writes in round $round."
    Assert-True ($page.Content -match '## Next Steps') "Expected final page to contain the Next Steps section after concurrent writes in round $round."
}

Write-Host 'Concurrency test passed.' -ForegroundColor Green
