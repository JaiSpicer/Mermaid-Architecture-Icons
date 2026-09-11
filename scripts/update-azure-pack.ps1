#Requires -Version 7.0

<#
.SYNOPSIS
    Refreshes the third-party Azure icon pack from its upstream source.

.DESCRIPTION
    Downloads the latest Azure Architecture Icons Iconify JSON from the
    NakayamaKento/AzureIcons repository, validates it is well-formed JSON with an
    'icons' collection, backs up the existing packs/azure-icons.json (if present),
    and replaces it with the freshly downloaded content byte-for-byte.

    packs/azure-icons.json is a third-party dependency: this script never modifies
    the downloaded content, and build-icon-pack.ps1 never writes to this file.

.PARAMETER SourceUrl
    URL of the upstream Iconify JSON file.

.PARAMETER RepoRoot
    Root of the repository. Defaults to the parent of this script's folder.

.EXAMPLE
    ./update-azure-pack.ps1
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$SourceUrl = 'https://raw.githubusercontent.com/NakayamaKento/AzureIcons/main/azureicons/allicons.json',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$RepoRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'shared/Logging.psm1') -Force

$packsDir = Join-Path $RepoRoot 'packs'
$outputFile = Join-Path $packsDir 'azure-icons.json'
$backupFile = Join-Path $packsDir 'azure-icons.backup.json'

Write-BuildLog 'Azure Icon Pack Update'
Write-BuildLog "Source: $SourceUrl"
Write-BuildLog ''

Write-BuildLog 'Downloading latest Azure icon pack...'
try {
    $response = Invoke-WebRequest -Uri $SourceUrl -UseBasicParsing
}
catch {
    Write-BuildLog "Failed to download Azure icon pack: $($_.Exception.Message)" -Level ERROR
    exit 1
}

try {
    $parsed = $response.Content | ConvertFrom-Json -ErrorAction Stop
}
catch {
    Write-BuildLog "Downloaded content is not valid JSON: $($_.Exception.Message)" -Level ERROR
    exit 1
}

if (-not $parsed.PSObject.Properties.Match('icons').Count -or $null -eq $parsed.icons) {
    Write-BuildLog "Downloaded JSON does not contain an 'icons' object" -Level ERROR
    exit 1
}

$iconCount = @($parsed.icons.PSObject.Properties).Count
Write-BuildLog "Validated JSON format ($iconCount icons found)"

if (-not (Test-Path -LiteralPath $packsDir -PathType Container)) {
    New-Item -ItemType Directory -Path $packsDir -Force | Out-Null
}

if (Test-Path -LiteralPath $outputFile -PathType Leaf) {
    Copy-Item -LiteralPath $outputFile -Destination $backupFile -Force
    Write-BuildLog 'Backed up existing pack to packs/azure-icons.backup.json'
}

Set-Content -LiteralPath $outputFile -Value $response.Content -Encoding UTF8 -NoNewline
Write-BuildLog 'Replaced packs/azure-icons.json'

Write-BuildLog ''
Write-BuildLog "Azure Icons: $iconCount"
Write-BuildLog 'Validation Successful' -Level SUCCESS

exit 0
