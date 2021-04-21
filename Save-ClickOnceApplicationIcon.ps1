. .\Get-ClickOnceApplicationIcon.ps1

function Save-ClickOnceApplicationIcon {
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'Manifest')]
    param (
        # The manifest to get the icon for
        [Parameter(Mandatory, ParameterSetName = 'Manifest')]
        $Manifest,
        # A specific file to save
        [Parameter(Mandatory, ParameterSetName = 'IconFile')]
        [uri]$IconFile,
        # The location to save the file to. Defaults to %temp%.
        $Destination = $env:TEMP
    )
    # TODO: better default for $Destination? Temp isn't a great choice as it needs to be kept
        # existing location for files? temp for everything?

    if ($PSCmdlet.ParameterSetName -eq 'Manifest') {
        [uri]$iconFile = Get-ClickOnceApplicationIcon $Manifest
        Write-Debug "Found icon from manifest $iconFile"
    }

    # TODO: create destination dir if needed
    if (Test-Path -PathType Container $Destination) {
        # Possibly better to use product name? Icon filename's usually unique but product's probably more reliable
        $iconfilename = (Split-Path -Leaf $iconFile) -replace '\.deploy$'
        $Destination = Join-Path $Destination $iconfilename
    }

    if ($PSCmdlet.ShouldProcess($Destination, 'Save icon')) {
        if ($iconFile.scheme -in 'http','https') {
            Invoke-WebRequest -Uri $iconFile -OutFile $Destination -ErrorAction Stop
            Write-Output $Destination
        } else {
            Copy-Item -Path $iconFile.OriginalString -Destination $Destination -Force -PassThru
        }
    }
}
