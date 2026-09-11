#Requires -Version 7.0

<#
.SYNOPSIS
    Validates every generated icon pack under packs/ for structural issues and
    cross-pack icon name conflicts.

.DESCRIPTION
    Loads every packs/*-icons.json file, checks it has a valid 'prefix' and
    'icons' structure, and checks for duplicate icon names among packs that
    share the same prefix (icon name collisions are only possible when two
    packs are registered under the same Mermaid prefix).

.PARAMETER RepoRoot
    Root of the repository. Defaults to the parent of this script's folder.

.EXAMPLE
    ./validate-icon-packs.ps1
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'shared/Logging.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'shared/IconPackValidator.psm1') -Force

$packsDir = Join-Path $RepoRoot 'packs'

Write-BuildLog 'Mermaid Icon Pack Validation'
Write-BuildLog ''

if (-not (Test-Path -LiteralPath $packsDir -PathType Container)) {
    Write-BuildLog "Packs folder not found: $packsDir" -Level ERROR
    exit 1
}

$packFiles = @(Get-ChildItem -LiteralPath $packsDir -Filter '*-icons.json' -File | Sort-Object Name)

if ($packFiles.Count -eq 0) {
    Write-BuildLog 'No icon pack files found in packs/' -Level ERROR
    exit 1
}

$hasErrors = $false
$duplicateCount = 0
$summaryLines = [System.Collections.Generic.List[string]]::new()

# prefix -> { iconName -> source file name }, used to detect cross-pack conflicts
$namesByPrefix = @{}

foreach ($file in $packFiles) {
    try {
        $packInfo = Test-IconPackFile -Path $file.FullName
    }
    catch {
        Write-BuildLog $_.Exception.Message -Level ERROR
        $hasErrors = $true
        continue
    }

    $withinPackDuplicates = @(Find-DuplicateIconNames -IconNames $packInfo.IconNames)
    foreach ($dup in $withinPackDuplicates) {
        Write-BuildLog "Duplicate icon name '$dup' within $($file.Name)" -Level ERROR
        $hasErrors = $true
        $duplicateCount++
    }

    $summaryLines.Add("$($packInfo.Prefix) Icons: $($packInfo.IconCount)")

    if (-not $namesByPrefix.ContainsKey($packInfo.Prefix)) {
        $namesByPrefix[$packInfo.Prefix] = @{}
    }

    foreach ($name in ($packInfo.IconNames | Select-Object -Unique)) {
        if ($namesByPrefix[$packInfo.Prefix].ContainsKey($name)) {
            $otherFile = $namesByPrefix[$packInfo.Prefix][$name]
            Write-BuildLog "Icon name '$name' conflicts across $otherFile and $($file.Name) (both use prefix '$($packInfo.Prefix)')" -Level ERROR
            $hasErrors = $true
            $duplicateCount++
        }
        else {
            $namesByPrefix[$packInfo.Prefix][$name] = $file.Name
        }
    }
}

foreach ($line in $summaryLines) {
    Write-BuildLog $line
}

Write-BuildLog "Duplicate Names: $duplicateCount"

if ($hasErrors) {
    Write-BuildLog 'Validation Failed' -Level ERROR
    exit 1
}

Write-BuildLog 'Validation Successful' -Level SUCCESS
exit 0
