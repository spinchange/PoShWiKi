#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$agentScript = Join-Path $repoRoot 'PoShWiKi.Agent.ps1'
$wikiScript = Join-Path $repoRoot 'wiki.ps1'
$artifactsDir = Join-Path $repoRoot 'artifacts'
$dbPath = Join-Path $artifactsDir 'profile-smoke-wiki.db'
$profileScript = Join-Path $artifactsDir 'profile-smoke-loader.ps1'

if (-not (Test-Path $artifactsDir)) {
    New-Item -ItemType Directory -Path $artifactsDir | Out-Null
}

if (Test-Path $dbPath) {
    Remove-Item -LiteralPath $dbPath -Force
}

$env:POSHWIKI_DB_PATH = $dbPath
pwsh -NoProfile -File $wikiScript init | Out-Null

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

$profileContent = @"
# PoShWiKi agent wrapper
`$poShWiKiAgentCandidates = @(
    `$env:POSHWIKI_AGENT_SCRIPT
    (Join-Path `$HOME 'Documents\GitHub\PoShWiKi\PoShWiKi.Agent.ps1')
    'C:\dev\repos\PoShWiKi\PoShWiKi.Agent.ps1'
)
`$poShWiKiAgentScript = `$poShWiKiAgentCandidates |
    Where-Object { -not [string]::IsNullOrWhiteSpace(`$_) } |
    Where-Object { Test-Path -LiteralPath `$_ } |
    Select-Object -First 1
if (`$poShWiKiAgentScript) {
    . `$poShWiKiAgentScript
}
"@

Set-Content -LiteralPath $profileScript -Value $profileContent

$command = @"
`$env:POSHWIKI_AGENT_SCRIPT = '$agentScript'
`$env:POSHWIKI_DB_PATH = '$dbPath'
. '$profileScript'
`$commands = Get-Command wiki-note, wiki-log, wiki-get -ErrorAction Stop
wiki-note 'Profile Smoke Page' 'Goal' 'Validate profile loader.' | Out-Null
wiki-log 'Profile Smoke Page' 'Validate action logging through profile autoload.' | Out-Null
`$page = wiki-get 'Profile Smoke Page'
[PSCustomObject]@{
    CommandCount = @(`$commands).Count
    Title = `$page.Title
    Content = `$page.Content
} | ConvertTo-Json -Compress
"@

$result = pwsh -NoProfile -Command $command
Assert-True ($LASTEXITCODE -eq 0) 'Expected profile smoke child session to exit successfully.'

$payload = $result | ConvertFrom-Json
Assert-True ($payload.CommandCount -eq 3) 'Expected profile loader to expose all wrapper commands.'
Assert-True ($payload.Title -eq 'Profile Smoke Page') 'Expected profile-loaded wrapper commands to write the target page.'
Assert-True ($payload.Content -match 'Validate profile loader\.') 'Expected profile-loaded wiki-note content.'
Assert-True ($payload.Content -match 'Validate action logging through profile autoload\.') 'Expected profile-loaded wiki-log content.'

Write-Host 'Profile smoke test passed.' -ForegroundColor Green
