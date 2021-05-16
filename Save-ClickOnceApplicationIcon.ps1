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
        # The location to save the file to, relative to %AppData%. Defaults to %temp%.
        $Destination = $env:TEMP
    )
    # TODO: better default for $Destination? Temp isn't a great choice as it needs to be kept
        # existing location for files? temp for everything?

    if ($PSCmdlet.ParameterSetName -eq 'Manifest') {
        [uri]$iconFile = Get-ClickOnceApplicationIcon $Manifest
        Write-Debug "Found icon from manifest $iconFile"
    }

    # $Destination is relative to $env:AppData
    $Destination = if (Split-Path -IsAbsolute $Destination) {$Destination} else {
        Join-Path ($env:AppData) $Destination
    }

    if (Test-Path -PathType Container $Destination) {
        # Destination is a directory -> use icon's existing filename
        $iconfilename = (Split-Path -Leaf $iconFile) -replace '\.deploy$'
        $Destination = Join-Path $Destination $iconfilename
    } elseif (Test-Path -PathType Leaf $Destination) {
        # Nothing to do?
    } elseif ([IO.Path]::GetExtension($Destination)) {
        # Has an extension -> it's a file, make parent dir
        mkdir (Split-Path -Parent $Destination) | Out-Null
    } else {
        # no extension -> it's a directory, create and use existing filename
        mkdir $Destination | Out-Null
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
