@{
    RootModule = 'PoShWiKi.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'ae73488e-0d4d-4f65-b8d8-89ae1af95e5c'
    Author = 'Chris Duffy'
    CompanyName = 'Spinchange'
    Copyright = '(c) Chris Duffy. All rights reserved.'
    Description = 'Minimal PowerShell 7 wiki backed by SQLite.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Initialize-Wiki',
        'Get-WikiPage',
        'Set-WikiPage',
        'Get-WikiTemplateNames',
        'New-WikiPageFromTemplate',
        'Convert-WikiMarkdownToDisplayText',
        'Update-WikiPageSection',
        'Add-WikiPageSectionContent',
        'Set-WikiPageSection',
        'Find-WikiPage',
        'Get-WikiPageList',
        'Get-WikiRecentPages',
        'Remove-WikiPage',
        'Get-WikiStats'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
}
