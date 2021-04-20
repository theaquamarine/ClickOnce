. .\Get-ClickOnceApplicationIcon.ps1

function Save-ClickOnceApplicationIcon {
    [CmdletBinding()]
    param (
        # The manifest to get the icon for
        [Parameter(Mandatory)]
        $Manifest,
        # The location to save the file to. Defaults to %temp%.
        $Destination = $env:TEMP
    )
    # TODO: better default for $Destination? Temp isn't a great choice as it needs to be kept
        # existing location for files? temp for everything?

    [uri]$iconFile = Get-ClickOnceApplicationIcon $Manifest

    if (Test-Path -PathType -Container $Destination) {
        # Possibly better to use product name?
        $iconfilename = Split-Path -Leaf $iconFile
        $Destination = Join-Path $Destination $iconfilename
    }

    if ($iconFile.scheme -in 'http','https') {
        Invoke-WebRequest -Uri $iconFile -OutFile $Destination -ErrorAction Stop
        Write-Output $Destination
    } else {
        Copy-Item -Path $iconFile.OriginalString -Destination $Destination -Force -PassThru
    }
}
