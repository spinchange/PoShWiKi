Set-StrictMode -Version Latest

$script:PoShWiKiRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:PoShWiKiCli = Join-Path $script:PoShWiKiRoot 'wiki.ps1'

function Invoke-PoShWiKiCli {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [switch]$Json
    )

    $pwsh = Get-Command pwsh -ErrorAction Stop
    $allArguments = @('-NoProfile', '-File', $script:PoShWiKiCli) + $Arguments
    if ($Json) {
        $allArguments += '-JSON'
    }

    $output = & $pwsh.Source @allArguments
    if ($LASTEXITCODE -ne 0) {
        throw "PoShWiKi CLI failed with exit code $LASTEXITCODE."
    }

    if ($Json) {
        if (-not $output) {
            return $null
        }

        return $output | ConvertFrom-Json
    }

    return $output
}

function wiki-get {
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [switch]$Text
    )

    if ($Text) {
        Invoke-PoShWiKiCli -Arguments @('get', $Title)
        return
    }

    Invoke-PoShWiKiCli -Arguments @('get', $Title) -Json
}

function Test-WikiPageExists {
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    $pages = @(wiki-list) | Where-Object {
        $null -ne $_ -and
        $_.PSObject.Properties.Name -contains 'Title'
    }

    return $null -ne ($pages | Where-Object { $_.Title -eq $Title } | Select-Object -First 1)
}

function New-WikiPageStub {
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    Invoke-PoShWiKiCli -Arguments @('save', $Title, "# $Title")
}

function Test-WikiSectionExists {
    param(
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [string]$Section
    )

    $page = wiki-get -Title $Title
    $pattern = "(?m)^##\s+$([Regex]::Escape($Section))\s*$"
    return ([string]$page.Content) -match $pattern
}

function wiki-find {
    param(
        [Parameter(Mandatory)]
        [string]$Query
    )

    Invoke-PoShWiKiCli -Arguments @('find', $Query) -Json
}

function wiki-list {
    Invoke-PoShWiKiCli -Arguments @('list') -Json
}

function wiki-recent {
    Invoke-PoShWiKiCli -Arguments @('recent') -Json
}

function wiki-stats {
    Invoke-PoShWiKiCli -Arguments @('stats') -Json
}

function wiki-note {
    param(
        [Parameter(Mandatory)]
        [string]$Page,

        [Parameter(Mandatory)]
        [string]$Section,

        [Parameter(Mandatory)]
        [string]$Text
    )

    if (-not (Test-WikiPageExists -Title $Page)) {
        New-WikiPageStub -Title $Page | Out-Null
    }

    Invoke-PoShWiKiCli -Arguments @('upsert-section', $Page, $Section, $Text) -Json
}

function wiki-log {
    param(
        [Parameter(Mandatory)]
        [string]$Page,

        [Parameter(Mandatory)]
        [string]$Text,

        [string]$Section = 'Actions'
    )

    if (-not (Test-WikiPageExists -Title $Page)) {
        New-WikiPageStub -Title $Page | Out-Null
    }

    if (Test-WikiSectionExists -Title $Page -Section $Section) {
        return Invoke-PoShWiKiCli -Arguments @('append-section', $Page, $Section, $Text) -Json
    }

    Invoke-PoShWiKiCli -Arguments @('upsert-section', $Page, $Section, $Text) -Json
}

function wiki-save {
    param(
        [Parameter(Mandatory)]
        [string]$Page,

        [Parameter(Mandatory)]
        [string]$Text
    )

    Invoke-PoShWiKiCli -Arguments @('save', $Page, $Text)
}

function wiki-session-page {
    param(
        [Parameter(Mandatory)]
        [string]$Topic,

        [datetime]$Date = (Get-Date)
    )

    "Session {0:yyyy-MM-dd} {1}" -f $Date, $Topic
}
