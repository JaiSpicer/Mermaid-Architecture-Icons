#Requires -Version 7.0

function Test-IconPackFile {
    <#
    .SYNOPSIS
        Loads and structurally validates a single generated icon pack JSON file.

    .PARAMETER Path
        Full path to the icon pack JSON file (e.g. packs/azure-icons.json).

    .OUTPUTS
        On success, a PSCustomObject with Prefix, IconNames, and IconCount.
        Throws on invalid JSON or a missing 'prefix'/'icons' structure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Icon pack file not found: $Path"
    }

    try {
        $content = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        throw "Invalid JSON in '$Path': $($_.Exception.Message)"
    }

    if (-not $content.PSObject.Properties.Match('prefix').Count -or [string]::IsNullOrWhiteSpace($content.prefix)) {
        throw "Icon pack '$Path' is missing a 'prefix' property"
    }

    if (-not $content.PSObject.Properties.Match('icons').Count -or $null -eq $content.icons) {
        throw "Icon pack '$Path' is missing an 'icons' property"
    }

    $iconNames = @($content.icons.PSObject.Properties.Name)

    [PSCustomObject]@{
        Prefix    = $content.prefix
        IconNames = $iconNames
        IconCount = $iconNames.Count
    }
}

function Find-DuplicateIconNames {
    <#
    .SYNOPSIS
        Returns any icon names that appear more than once in the given list.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [string[]]$IconNames
    )

    $IconNames | Group-Object | Where-Object { $_.Count -gt 1 } | ForEach-Object { $_.Name }
}

Export-ModuleMember -Function Test-IconPackFile, Find-DuplicateIconNames
