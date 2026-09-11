#Requires -Version 7.0

function Write-BuildLog {
    <#
    .SYNOPSIS
        Writes a level-tagged, timestamp-free log line in the [LEVEL] Message format
        used across all Mermaid icon pack build and validation scripts.

    .PARAMETER Message
        The message to log. An empty string prints a blank line.

    .PARAMETER Level
        Severity level: INFO, WARN, ERROR, or SUCCESS. Defaults to INFO.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [AllowEmptyString()]
        [string]$Message = '',

        [Parameter(Position = 1)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    if ([string]::IsNullOrEmpty($Message)) {
        Write-Host ''
        return
    }

    $color = switch ($Level) {
        'INFO' { 'Gray' }
        'WARN' { 'Yellow' }
        'ERROR' { 'Red' }
        'SUCCESS' { 'Green' }
    }

    Write-Host "[$Level] $Message" -ForegroundColor $color
}

Export-ModuleMember -Function Write-BuildLog
