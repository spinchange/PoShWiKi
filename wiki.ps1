#!/usr/bin/env pwsh

# wiki.ps1 - CLI Entry Point for PoShWiKi

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
Import-Module (Join-Path $PSScriptRoot "PoShWiKi.psd1") -Force

function Show-Help {
    Write-Host "PoShWiKi CLI" -ForegroundColor Cyan
    Write-Host "Usage: ./wiki.ps1 <command> [arguments] [-JSON]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  init                 Initialize the wiki database"
    Write-Host "  get <title>          Retrieve a page"
    Write-Host "  templates            List built-in page templates"
    Write-Host "  new-page <template> <title>"
    Write-Host "                       Create a page from a built-in template"
    Write-Host "  set <title> <file>   Save a page from a file's content"
    Write-Host "  save <title> <text>  Save a page from direct text"
    Write-Host "  update-section <title> <section> <text>"
    Write-Host "                       Replace an existing ## section body"
    Write-Host "  append-section <title> <section> <text>"
    Write-Host "                       Append to an existing ## section body"
    Write-Host "  upsert-section <title> <section> <text>"
    Write-Host "                       Update an existing ## section or create it"
    Write-Host "  find <query>         Search pages"
    Write-Host "  list                 List pages"
    Write-Host "  recent               List pages by most recent modification"
    Write-Host "  rm <title>           Delete a page"
    Write-Host "  stats                Show wiki statistics"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -JSON                Output results as JSON (Agent-friendly)"
}

if ($args.Count -eq 0) {
    Show-Help
    exit 1
}

$command = $args[0]
$JSON = $args -contains "-JSON"
$remainingArgs = @($args | Where-Object { $_ -ne $command -and $_ -ne "-JSON" })

switch ($command) {
    "init" {
        Initialize-Wiki
    }
    "get" {
        if ($remainingArgs.Count -lt 1) { Write-Error "Title required."; exit 1 }
        $page = Get-WikiPage -Title $remainingArgs[0]
        if ($page) {
            if ($JSON) { $page | ConvertTo-Json }
            else { 
                $hasMatchingTitleHeading = $page.Content -match "^\#\s+$([Regex]::Escape($page.Title))(\s|$)"
                if (-not $hasMatchingTitleHeading) {
                    Write-Output $page.Title
                    Write-Output ('=' * $page.Title.Length)
                    Write-Output ''
                }
                Write-Output (Convert-WikiMarkdownToDisplayText -Content $page.Content)
                Write-Output ''
                Write-Output "Modified: $($page.Modified)"
            }
        } else {
            exit 1
        }
    }
    "templates" {
        $results = Get-WikiTemplateNames
        if ($JSON) { $results | ConvertTo-Json }
        else { $results | Format-Table }
    }
    "new-page" {
        if ($remainingArgs.Count -lt 2) { Write-Error "Template and Title required."; exit 1 }
        $page = New-WikiPageFromTemplate -Template $remainingArgs[0] -Title $remainingArgs[1]
        if ($page) {
            if ($JSON) { $page | ConvertTo-Json }
            else { Write-Host "Page '$($page.Title)' created from template." -ForegroundColor Green }
        } else {
            exit 1
        }
    }
    "save" {
        if ($remainingArgs.Count -lt 2) { Write-Error "Title and Text required."; exit 1 }
        Set-WikiPage -Title $remainingArgs[0] -Content $remainingArgs[1]
    }
    "update-section" {
        if ($remainingArgs.Count -lt 3) { Write-Error "Title, Section, and Text or -File path required."; exit 1 }

        if ($remainingArgs.Count -ge 4 -and $remainingArgs[2] -eq "-File") {
            try {
                $content = Get-Content -Raw -ErrorAction Stop $remainingArgs[3]
            } catch {
                Write-Error $_
                exit 1
            }
        } else {
            $content = $remainingArgs[2]
        }

        $page = Update-WikiPageSection -Title $remainingArgs[0] -Section $remainingArgs[1] -Content $content
        if ($page) {
            if ($JSON) { $page | ConvertTo-Json }
        } else {
            exit 1
        }
    }
    "append-section" {
        if ($remainingArgs.Count -lt 3) { Write-Error "Title, Section, and Text or -File path required."; exit 1 }

        if ($remainingArgs.Count -ge 4 -and $remainingArgs[2] -eq "-File") {
            try {
                $content = Get-Content -Raw -ErrorAction Stop $remainingArgs[3]
            } catch {
                Write-Error $_
                exit 1
            }
        } else {
            $content = $remainingArgs[2]
        }

        $page = Add-WikiPageSectionContent -Title $remainingArgs[0] -Section $remainingArgs[1] -Content $content
        if ($page) {
            if ($JSON) { $page | ConvertTo-Json }
        } else {
            exit 1
        }
    }
    "upsert-section" {
        if ($remainingArgs.Count -lt 3) { Write-Error "Title, Section, and Text or -File path required."; exit 1 }

        if ($remainingArgs.Count -ge 4 -and $remainingArgs[2] -eq "-File") {
            try {
                $content = Get-Content -Raw -ErrorAction Stop $remainingArgs[3]
            } catch {
                Write-Error $_
                exit 1
            }
        } else {
            $content = $remainingArgs[2]
        }

        $page = Set-WikiPageSection -Title $remainingArgs[0] -Section $remainingArgs[1] -Content $content
        if ($page) {
            if ($JSON) { $page | ConvertTo-Json }
        } else {
            exit 1
        }
    }
    "set" {
        if ($remainingArgs.Count -lt 2) { Write-Error "Title and File required."; exit 1 }
        try {
            $content = Get-Content -Raw -ErrorAction Stop $remainingArgs[1]
        } catch {
            Write-Error $_
            exit 1
        }
        Set-WikiPage -Title $remainingArgs[0] -Content $content
    }
    "find" {
        if ($remainingArgs.Count -lt 1) { Write-Error "Query required."; exit 1 }
        $results = Find-WikiPage -Query $remainingArgs[0]
        if ($JSON) { $results | ConvertTo-Json }
        else { $results | Format-Table }
    }
    "list" {
        $results = Get-WikiPageList
        if ($JSON) { $results | ConvertTo-Json }
        else { $results | Format-Table }
    }
    "recent" {
        $results = Get-WikiRecentPages
        if ($JSON) { $results | ConvertTo-Json }
        else { $results | Format-Table }
    }
    "rm" {
        if ($remainingArgs.Count -lt 1) { Write-Error "Title required."; exit 1 }
        Remove-WikiPage -Title $remainingArgs[0]
    }
    "stats" {
        $stats = Get-WikiStats
        if ($JSON) { $stats | ConvertTo-Json }
        else { $stats | Format-List }
    }
    default {
        Write-Error "Unknown command: $command"
        Show-Help
        exit 1
    }
}
