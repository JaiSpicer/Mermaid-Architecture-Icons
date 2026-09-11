#Requires -Version 7.0

<#
.SYNOPSIS
    Builds a Mermaid/Iconify-compatible icon pack JSON file from local SVG sources.

.DESCRIPTION
    Scans source/<PackName> for *.svg files, parses each one into an Iconify icon
    definition (body/width/height), and writes the sorted result to
    packs/<PackName>-icons.json. Works for any pack name whose source folder exists
    under source/ (application, or any future pack) -- no code changes are
    required to support a new pack, only a new source folder.

.PARAMETER PackName
    Name of the icon pack to build. Must match a folder under source/, e.g. 'application'.

.PARAMETER RepoRoot
    Root of the repository. Defaults to the parent of this script's folder.

.EXAMPLE
    ./build-icon-pack.ps1 application

.EXAMPLE
    ./build-icon-pack.ps1 -PackName vendor
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$PackName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'shared/Logging.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'shared/SvgParser.psm1') -Force

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

$sourceFolder = Join-Path $RepoRoot "source/$PackName"
$packsDir = Join-Path $RepoRoot 'packs'
$outputFile = Join-Path $packsDir "$PackName-icons.json"

Write-BuildLog 'Mermaid Icon Pack Build'
Write-BuildLog "Pack Name: $PackName"
Write-BuildLog "Source Folder: source/$PackName"

if (-not (Test-Path -LiteralPath $sourceFolder -PathType Container)) {
    Write-BuildLog "Source folder not found: source/$PackName" -Level ERROR
    exit 1
}

$svgFiles = @(Get-ChildItem -LiteralPath $sourceFolder -Filter '*.svg' -File | Sort-Object Name)

if ($svgFiles.Count -eq 0) {
    Write-BuildLog "No SVG files found in source/$PackName" -Level ERROR
    exit 1
}

Write-BuildLog "Found $($svgFiles.Count) SVG files"
Write-BuildLog ''

$icons = [ordered]@{}
$hasErrors = $false

foreach ($file in $svgFiles) {
    Write-BuildLog "Processing $($file.Name)"
    $iconName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

    if ($icons.Contains($iconName)) {
        Write-BuildLog "Duplicate icon name '$iconName' (file $($file.Name))" -Level ERROR
        $hasErrors = $true
        continue
    }

    try {
        $icons[$iconName] = Get-SvgIconData -Path $file.FullName
    }
    catch {
        Write-BuildLog $_.Exception.Message -Level ERROR
        $hasErrors = $true
    }
}

if ($hasErrors) {
    Write-BuildLog ''
    Write-BuildLog 'Build failed due to one or more SVG validation errors.' -Level ERROR
    exit 1
}

$sortedIcons = [ordered]@{}
foreach ($key in ($icons.Keys | Sort-Object)) {
    $sortedIcons[$key] = $icons[$key]
}

$packOutput = [ordered]@{
    prefix = $PackName
    icons  = $sortedIcons
}

if (-not (Test-Path -LiteralPath $packsDir -PathType Container)) {
    New-Item -ItemType Directory -Path $packsDir -Force | Out-Null
}

($packOutput | ConvertTo-Json -Depth 10) | Set-Content -LiteralPath $outputFile -Encoding UTF8 -NoNewline

$stopwatch.Stop()

Write-BuildLog ''
Write-BuildLog "Generated packs/$PackName-icons.json"
Write-BuildLog ''
Write-BuildLog "Icons Generated: $($sortedIcons.Count)"
Write-BuildLog ("Duration: {0:N1} seconds" -f $stopwatch.Elapsed.TotalSeconds)
Write-BuildLog 'Validation Successful' -Level SUCCESS

exit 0
