#!/usr/bin/env pwsh

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$wikiScript = Join-Path $repoRoot 'wiki.ps1'
$manifestPath = Join-Path $repoRoot 'PoShWiKi.psd1'
$artifactsDir = Join-Path $repoRoot 'artifacts'
$dbPath = Join-Path $artifactsDir 'contract-wiki.db'
$title = 'ContractTestPage'
$missingTitle = 'MissingContractPage'
$missingFile = Join-Path $repoRoot 'does-not-exist.md'
$firstContent = '# First Version'
$secondContent = '# Second Version'
$sectionTitle = 'SectionContractPage'
$sectionContent = @'
# Section Contract Page

## Current Seam

Old seam

## Next

Old next
'@
$replacementFile = Join-Path $artifactsDir 'section-update.txt'
$markdownTitle = 'MarkdownContractPage'
$markdownContent = @'
# Markdown Contract Page

## Notes

- alpha

> beta
'@

if (-not (Test-Path $artifactsDir)) {
    New-Item -ItemType Directory -Path $artifactsDir | Out-Null
}

if (Test-Path $dbPath) {
    Remove-Item -LiteralPath $dbPath -Force
}
if (Test-Path $replacementFile) {
    Remove-Item -LiteralPath $replacementFile -Force
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

function Invoke-WikiCli {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [switch]$ExpectFailure
    )

    $output = & pwsh -NoProfile -File $wikiScript @Arguments 2>&1
    $exitCode = $LASTEXITCODE

    if ($ExpectFailure) {
        Assert-True ($exitCode -ne 0) "Expected failure for arguments: $($Arguments -join ' ')"
    } else {
        Assert-True ($exitCode -eq 0) "Expected success for arguments: $($Arguments -join ' ')"
    }

    return @($output)
}

function Convert-JsonOutput {
    param(
        [AllowNull()]
        [object[]]$Output
    )

    if ($null -eq $Output -or $Output.Count -eq 0) {
        return @()
    }

    $warnings = @($Output | Where-Object { $_ -is [System.Management.Automation.WarningRecord] })
    Assert-True ($warnings.Count -eq 0) 'Expected command output without warnings.'

    $text = ($Output | ForEach-Object {
        if ($_ -is [System.Management.Automation.InformationRecord]) {
            $_.MessageData
        } elseif ($_ -is [string]) {
            $_
        }
    }) -join [Environment]::NewLine

    Assert-True (-not [string]::IsNullOrWhiteSpace($text)) 'Expected JSON output text.'
    return $text | ConvertFrom-Json
}

function Assert-HasExactProperties {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,

        [Parameter(Mandatory = $true)]
        [string[]]$ExpectedNames
    )

    $actual = @($Object.PSObject.Properties.Name | Sort-Object)
    $expected = @($ExpectedNames | Sort-Object)
    Assert-True (($actual -join ',') -eq ($expected -join ',')) "Expected properties [$($expected -join ', ')], got [$($actual -join ', ')]"
}

Invoke-WikiCli -Arguments @('init') | Out-Null

$stats = Convert-JsonOutput (Invoke-WikiCli -Arguments @('stats', '-JSON'))
Assert-HasExactProperties -Object $stats -ExpectedNames @('DatabaseSize', 'PageCount', 'Path')
Assert-True ($stats.PageCount -eq 0) 'Expected empty wiki after init.'

$emptyList = @(Convert-JsonOutput (Invoke-WikiCli -Arguments @('list', '-JSON')))
Assert-True ($emptyList.Count -eq 0) 'Expected empty list for new wiki.'

$emptyRecent = @(Convert-JsonOutput (Invoke-WikiCli -Arguments @('recent', '-JSON')))
Assert-True ($emptyRecent.Count -eq 0) 'Expected empty recent results for new wiki.'

$emptyFind = @(Convert-JsonOutput (Invoke-WikiCli -Arguments @('find', 'NoMatch', '-JSON')))
Assert-True ($emptyFind.Count -eq 0) 'Expected empty search results for unmatched query.'

$templates = @(Convert-JsonOutput (Invoke-WikiCli -Arguments @('templates', '-JSON')))
Assert-True (($templates | Where-Object Name -eq 'project').Count -eq 1) 'Expected templates list to include project.'
Assert-True (($templates | Where-Object Name -eq 'task').Count -eq 1) 'Expected templates list to include task.'

$missingTemplateOutput = Invoke-WikiCli -Arguments @('new-page', 'missing-template', 'Whatever') -ExpectFailure
Assert-True (($missingTemplateOutput | Out-String) -match 'Unknown template') 'Expected unknown-template error.'

$missingGetOutput = Invoke-WikiCli -Arguments @('get', $missingTitle, '-JSON') -ExpectFailure
Assert-True (($missingGetOutput | Out-String) -match 'not found') 'Expected missing-page error message.'

$missingRmOutput = Invoke-WikiCli -Arguments @('rm', $missingTitle) | Out-String
Assert-True ($missingRmOutput -match 'did not exist') 'Expected missing delete warning.'

$missingSetOutput = Invoke-WikiCli -Arguments @('set', $title, $missingFile) -ExpectFailure
Assert-True (($missingSetOutput | Out-String) -match 'Cannot find path') 'Expected missing-file error for set.'

$missingUpdateOutput = Invoke-WikiCli -Arguments @('update-section', $missingTitle, 'Current Seam', 'Updated body') -ExpectFailure
Assert-True (($missingUpdateOutput | Out-String) -match 'not found') 'Expected missing-page error for update-section.'

$missingAppendOutput = Invoke-WikiCli -Arguments @('append-section', $missingTitle, 'Current Seam', 'Appended body') -ExpectFailure
Assert-True (($missingAppendOutput | Out-String) -match 'not found') 'Expected missing-page error for append-section.'

$missingUpsertOutput = Invoke-WikiCli -Arguments @('upsert-section', $missingTitle, 'Current Seam', 'Upserted body') -ExpectFailure
Assert-True (($missingUpsertOutput | Out-String) -match 'not found') 'Expected missing-page error for upsert-section.'

$invalidCommandOutput = Invoke-WikiCli -Arguments @('bogus-command') -ExpectFailure
Assert-True (($invalidCommandOutput | Out-String) -match 'Unknown command') 'Expected unknown command error.'

$templatedPage = Convert-JsonOutput (Invoke-WikiCli -Arguments @('new-page', 'decision', 'Contract Template', '-JSON'))
Assert-True ($templatedPage.Title -eq 'Decision: Contract Template') 'Expected decision template title prefix.'
Assert-True ($templatedPage.Content -match '## Decision') 'Expected decision template headings.'

Invoke-WikiCli -Arguments @('save', $markdownTitle, $markdownContent) | Out-Null
$jsonMarkdownPage = Convert-JsonOutput (Invoke-WikiCli -Arguments @('get', $markdownTitle, '-JSON'))
Assert-True ($jsonMarkdownPage.Content -eq $markdownContent) 'Expected JSON get output to preserve raw Markdown content.'

Invoke-WikiCli -Arguments @('save', $title, $firstContent) | Out-Null
$firstPage = Convert-JsonOutput (Invoke-WikiCli -Arguments @('get', $title, '-JSON'))
Assert-HasExactProperties -Object $firstPage -ExpectedNames @('Content', 'Created', 'Id', 'Modified', 'Title')
Assert-True ($firstPage.Title -eq $title) 'Expected saved title.'
Assert-True ($firstPage.Content -eq $firstContent) 'Expected first content.'

Start-Sleep -Seconds 1

Invoke-WikiCli -Arguments @('save', $title, $secondContent) | Out-Null
$updatedPage = Convert-JsonOutput (Invoke-WikiCli -Arguments @('get', $title, '-JSON'))
Assert-True ($updatedPage.Content -eq $secondContent) 'Expected updated content.'
Assert-True ($updatedPage.Created -eq $firstPage.Created) 'Expected Created timestamp to remain stable across updates.'
Assert-True ($updatedPage.Modified -ne $firstPage.Modified) 'Expected Modified timestamp to change after update.'

$findResults = @(Convert-JsonOutput (Invoke-WikiCli -Arguments @('find', 'Second', '-JSON')))
Assert-True ($findResults.Count -eq 1) 'Expected one search result for updated page.'
Assert-HasExactProperties -Object $findResults[0] -ExpectedNames @('Created', 'Modified', 'Title')

$listResults = @(Convert-JsonOutput (Invoke-WikiCli -Arguments @('list', '-JSON')))
Assert-True (($listResults | Where-Object Title -eq $title).Count -eq 1) 'Expected list to include the saved page.'
Assert-HasExactProperties -Object $listResults[0] -ExpectedNames @('Created', 'Modified', 'Title')

$secondTitle = 'ContractSecondPage'
Start-Sleep -Seconds 1
Invoke-WikiCli -Arguments @('save', $secondTitle, '# Newest Page') | Out-Null

$recentResults = @(Convert-JsonOutput (Invoke-WikiCli -Arguments @('recent', '-JSON')))
Assert-True ($recentResults.Count -ge 2) 'Expected at least two recent results.'
Assert-HasExactProperties -Object $recentResults[0] -ExpectedNames @('Created', 'Modified', 'Title')
Assert-True ($recentResults[0].Title -eq $secondTitle) 'Expected most recently modified page first in recent results.'
Assert-True ($recentResults[1].Title -eq $title) 'Expected older page after newer page in recent results.'

Invoke-WikiCli -Arguments @('save', $sectionTitle, $sectionContent) | Out-Null
$updatedSection = Convert-JsonOutput (Invoke-WikiCli -Arguments @('update-section', $sectionTitle, 'Current Seam', 'New seam text', '-JSON'))
Assert-True ($updatedSection.Content -match 'New seam text') 'Expected inline section update to replace the section body.'
Assert-True ($updatedSection.Content -match '## Next') 'Expected update-section to preserve following sections.'

Set-Content -LiteralPath $replacementFile -Value 'Replacement from file'
$fileUpdatedSection = Convert-JsonOutput (Invoke-WikiCli -Arguments @('update-section', $sectionTitle, 'Next', '-File', $replacementFile, '-JSON'))
Assert-True ($fileUpdatedSection.Content -match 'Replacement from file') 'Expected file-based section update to replace the section body.'

$missingSectionOutput = Invoke-WikiCli -Arguments @('update-section', $sectionTitle, 'Missing Section', 'Nope') -ExpectFailure
Assert-True (($missingSectionOutput | Out-String) -match 'Section') 'Expected missing-section error.'

$appendedSection = Convert-JsonOutput (Invoke-WikiCli -Arguments @('append-section', $sectionTitle, 'Current Seam', 'Appended seam text', '-JSON'))
Assert-True ($appendedSection.Content -match 'New seam text') 'Expected existing section content to remain after append.'
Assert-True ($appendedSection.Content -match 'Appended seam text') 'Expected append-section to add new content.'

Set-Content -LiteralPath $replacementFile -Value 'Appended from file'
$fileAppendedSection = Convert-JsonOutput (Invoke-WikiCli -Arguments @('append-section', $sectionTitle, 'Next', '-File', $replacementFile, '-JSON'))
Assert-True ($fileAppendedSection.Content -match 'Replacement from file') 'Expected prior section text to remain before file append.'
Assert-True ($fileAppendedSection.Content -match 'Appended from file') 'Expected file-based append to add new content.'

$missingAppendSectionOutput = Invoke-WikiCli -Arguments @('append-section', $sectionTitle, 'Missing Section', 'Nope') -ExpectFailure
Assert-True (($missingAppendSectionOutput | Out-String) -match 'Section') 'Expected missing-section error for append-section.'

$upsertExistingSection = Convert-JsonOutput (Invoke-WikiCli -Arguments @('upsert-section', $sectionTitle, 'Current Seam', 'Upserted seam text', '-JSON'))
Assert-True ($upsertExistingSection.Content -match 'Upserted seam text') 'Expected upsert-section to update an existing section.'

Set-Content -LiteralPath $replacementFile -Value 'Created by upsert from file'
$upsertCreatedSection = Convert-JsonOutput (Invoke-WikiCli -Arguments @('upsert-section', $sectionTitle, 'Verification', '-File', $replacementFile, '-JSON'))
Assert-True ($upsertCreatedSection.Content -match '## Verification') 'Expected upsert-section to create a missing section.'
Assert-True ($upsertCreatedSection.Content -match 'Created by upsert from file') 'Expected created section content from file.'

Import-Module $manifestPath -Force
$importedPage = Get-WikiPage -Title $title
Assert-True ($importedPage.Title -eq $title) 'Expected manifest import to expose Get-WikiPage.'

Write-Host 'Contract test passed.' -ForegroundColor Green
