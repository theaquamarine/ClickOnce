. .\Get-ClickOnceApplicationIcon.ps1

function Save-ClickOnceApplicationIcon {
    [CmdletBinding()]
    param (
        # The manifest to get the icon for
        [Parameter(Mandatory)]
        $Manifest,
        # The location to save the file to
        [Parameter(Mandatory)]
        $Destination
    )

    [uri]$iconFile = Get-ClickOnceApplicationIcon $Manifest

    if ($iconFile.scheme -in 'http','https') {
        # TODO: Check if $Destination is a container, append icon file name if so
        Invoke-WebRequest -Uri $iconFile -OutFile $Destination -ErrorAction Stop
        Write-Output $Destination
    } else {
        Copy-Item -Path $uri.OriginalString -Destination $Destination -Force -PassThru
    }
}
