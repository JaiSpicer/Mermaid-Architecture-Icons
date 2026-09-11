#Requires -Version 7.0

function Get-SvgIconData {
    <#
    .SYNOPSIS
        Parses a single SVG file into an Iconify-compatible icon definition.

    .DESCRIPTION
        Reads an SVG file, validates it has a well-formed <svg> root element with a
        viewBox, and extracts the body markup plus a pixel width/height suitable for
        an Iconify icon set entry (https://iconify.design/docs/icons/json.html).

    .PARAMETER Path
        Full path to the SVG file to parse.

    .OUTPUTS
        An ordered hashtable with 'body', 'width', 'height', and (when the viewBox
        has a non-zero origin) 'left'/'top' keys.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "SVG file not found: $Path"
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8

    try {
        [xml]$xml = $raw
    }
    catch {
        throw "Invalid SVG structure in '$Path': $($_.Exception.Message)"
    }

    $svgNode = $xml.DocumentElement
    if ($null -eq $svgNode -or $svgNode.LocalName -ne 'svg') {
        throw "Invalid SVG structure in '$Path': root element is not <svg>"
    }

    $viewBoxAttr = $svgNode.GetAttribute('viewBox')
    if ([string]::IsNullOrWhiteSpace($viewBoxAttr)) {
        throw "Missing viewBox in '$Path'"
    }

    $viewBoxParts = $viewBoxAttr -split '[\s,]+' | Where-Object { $_ -ne '' }
    if ($viewBoxParts.Count -ne 4) {
        throw "Invalid viewBox format in '$Path': '$viewBoxAttr'"
    }

    try {
        $minX = [double]$viewBoxParts[0]
        $minY = [double]$viewBoxParts[1]
        $vbWidth = [double]$viewBoxParts[2]
        $vbHeight = [double]$viewBoxParts[3]
    }
    catch {
        throw "Invalid viewBox values in '$Path': '$viewBoxAttr'"
    }

    if ($vbWidth -le 0 -or $vbHeight -le 0) {
        throw "Invalid viewBox dimensions in '$Path': '$viewBoxAttr'"
    }

    $widthAttr = $svgNode.GetAttribute('width')
    $heightAttr = $svgNode.GetAttribute('height')

    $width = if ([string]::IsNullOrWhiteSpace($widthAttr)) { $vbWidth } else { [double]($widthAttr -replace '[^0-9.]', '') }
    $height = if ([string]::IsNullOrWhiteSpace($heightAttr)) { $vbHeight } else { [double]($heightAttr -replace '[^0-9.]', '') }

    $body = $svgNode.InnerXml
    if ([string]::IsNullOrWhiteSpace($body)) {
        throw "Empty SVG body in '$Path'"
    }

    # .NET re-declares the inherited default/prefixed namespaces on every child
    # element when serializing InnerXml as a standalone fragment. Those
    # declarations are redundant once the body is embedded in the pack JSON
    # (it is inserted into an existing <svg> context), so strip them.
    $body = $body -replace '\s+xmlns(:\w+)?="[^"]*"', ''

    $result = [ordered]@{
        body   = $body
        width  = [int][math]::Round($width)
        height = [int][math]::Round($height)
    }

    if ($minX -ne 0) { $result['left'] = [int][math]::Round($minX) }
    if ($minY -ne 0) { $result['top'] = [int][math]::Round($minY) }

    return $result
}

Export-ModuleMember -Function Get-SvgIconData
