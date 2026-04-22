#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$wikiScript = Join-Path $repoRoot 'wiki.ps1'
$artifactsDir = Join-Path $repoRoot 'artifacts'
$dbPath = Join-Path $artifactsDir 'smoke-wiki.db'
$title = 'SmokeTestPage'
$content = '# Smoke Test'
$sectionTitle = 'SmokeSectionPage'
$sectionContent = @'
# Smoke Section Page

## Notes

Original body

## Next

Keep this section
'@
$markdownTitle = 'SmokeMarkdownPage'
$markdownContent = @'
# Smoke Markdown Page

## Summary

- first item
- second item

> quoted line

```powershell
Get-Date
```
'@

if (Test-Path $dbPath) {
    Remove-Item -LiteralPath $dbPath -Force
}
if (-not (Test-Path $artifactsDir)) {
    New-Item -ItemType Directory -Path $artifactsDir | Out-Null
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

$stats = pwsh -NoProfile -File $wikiScript stats -JSON | ConvertFrom-Json
Assert-True ($stats.PageCount -eq 0) 'Expected empty wiki after init.'

pwsh -NoProfile -File $wikiScript save $title $content | Out-Null

$page = pwsh -NoProfile -File $wikiScript get $title -JSON | ConvertFrom-Json
Assert-True ($page.Title -eq $title) 'Expected saved page title.'
Assert-True ($page.Content -eq $content) 'Expected saved page content.'

$templates = @(pwsh -NoProfile -File $wikiScript templates -JSON | ConvertFrom-Json)
Assert-True (($templates | Where-Object Name -eq 'task').Count -eq 1) 'Expected templates list to include task.'

$templatedPage = pwsh -NoProfile -File $wikiScript new-page task 'Smoke Task' -JSON | ConvertFrom-Json
Assert-True ($templatedPage.Title -eq 'Task: Smoke Task') 'Expected templated page title.'
Assert-True ($templatedPage.Content -match '## Goal') 'Expected task template headings.'

$results = @(pwsh -NoProfile -File $wikiScript find Smoke -JSON | ConvertFrom-Json)
Assert-True ($results.Count -ge 1) 'Expected search to find the saved page.'
Assert-True (($results | Where-Object Title -eq $title).Count -eq 1) 'Expected search results to include the saved page.'

$list = @(pwsh -NoProfile -File $wikiScript list -JSON | ConvertFrom-Json)
Assert-True (($list | Where-Object Title -eq $title).Count -eq 1) 'Expected list to include the saved page.'

$recent = @(pwsh -NoProfile -File $wikiScript recent -JSON | ConvertFrom-Json)
Assert-True (($recent | Where-Object Title -eq $title).Count -eq 1) 'Expected recent to include the saved page.'

pwsh -NoProfile -File $wikiScript save $sectionTitle $sectionContent | Out-Null
pwsh -NoProfile -File $wikiScript save $markdownTitle $markdownContent | Out-Null
$updatedSection = pwsh -NoProfile -File $wikiScript update-section $sectionTitle Notes 'Updated body' -JSON | ConvertFrom-Json
Assert-True ($updatedSection.Content -match '## Notes') 'Expected updated section heading to remain.'
Assert-True ($updatedSection.Content -match 'Updated body') 'Expected section body to update.'
Assert-True ($updatedSection.Content -match '## Next') 'Expected later section to remain.'

$appendedSection = pwsh -NoProfile -File $wikiScript append-section $sectionTitle Notes 'Appended body' -JSON | ConvertFrom-Json
Assert-True ($appendedSection.Content -match 'Updated body') 'Expected original updated section body to remain after append.'
Assert-True ($appendedSection.Content -match 'Appended body') 'Expected appended section body to be added.'

$upsertedSection = pwsh -NoProfile -File $wikiScript upsert-section $sectionTitle Summary 'Created summary' -JSON | ConvertFrom-Json
Assert-True ($upsertedSection.Content -match '## Summary') 'Expected upsert-section to create a missing section.'
Assert-True ($upsertedSection.Content -match 'Created summary') 'Expected new upserted section body.'

$rendered = (& pwsh -NoProfile -File $wikiScript get $markdownTitle 2>&1 | Out-String)
Assert-True ($rendered -match 'Smoke Markdown Page') 'Expected rendered output to include the markdown page title.'
Assert-True ($rendered -match 'Summary') 'Expected rendered output to include section headings.'
Assert-True ($rendered -match '• first item') 'Expected rendered output to transform bullet lists.'
Assert-True ($rendered -match '│ quoted line') 'Expected rendered output to transform blockquotes.'
Assert-True ($rendered -match '\[code\]') 'Expected rendered output to mark code blocks.'

pwsh -NoProfile -File $wikiScript rm $title | Out-Null
pwsh -NoProfile -File $wikiScript rm 'Task: Smoke Task' | Out-Null
pwsh -NoProfile -File $wikiScript rm $sectionTitle | Out-Null
pwsh -NoProfile -File $wikiScript rm $markdownTitle | Out-Null

$statsAfterDelete = pwsh -NoProfile -File $wikiScript stats -JSON | ConvertFrom-Json
Assert-True ($statsAfterDelete.PageCount -eq 0) 'Expected empty wiki after delete.'

Write-Host 'Smoke test passed.' -ForegroundColor Green
