<#
.SYNOPSIS
    Add a start menu shortcut to "install" a network-only ClickOnce application
.EXAMPLE
    PS C:\> Install-ClickOnceApplication.ps1 'https://lovettsoftwarestorage.blob.core.windows.net/downloads/XmlNotepad/XmlNotepad.application'
    Download and install XML Notepad
#>

[CmdletBinding(DefaultParameterSetName = 'Folder', SupportsShouldProcess)]
param (
    # The manifest file to install
    [Parameter(Mandatory)]
    $Manifest,
    # The shortcut's location, including file name
    [Parameter(Mandatory, ParameterSetName='Location')][ValidatePattern("(\.lnk|\.url)$")]
    $Location,
    # The name to install the app as. Defaults to app name from manifest.
    [Parameter(ParameterSetName='Folder')]
    [string]$AppName, 
    # The folder to list the app in on the start menu. Defaults to publisher from the manifest.
    [Parameter(ParameterSetName='Folder')][Alias('Publisher')]
    [string]$Folder,
    [string]$Description
)
    # $IconLocation, # default to try from manifest
    # $Arguments,
    # [string]$Hotkey,
    # $WindowStyle,
    # $WorkingDirectory

. .\Import-ClickOnceManifest.ps1
. .\Save-ClickOnceApplicationIcon.ps1

[xml]$xml = Import-ClickOnceManifest $manifest

$TargetPath = $Manifest

if (-not($AppName)) {$AppName = $xml.assembly.description.product}
$Publisher = $xml.assembly.description.publisher
$Suite = $xml.assembly.description.suite

if (-not($Folder)) { 
    $Folder = if ($Suite) { Join-Path $Publisher $Suite} else {$Publisher}
}

$shortcutDir = Join-Path ([System.Environment]::GetFolderPath('Programs')) ($Folder)
$location = Join-Path $shortcutDir ($AppName + '.lnk')

if ($PSCmdlet.ShouldProcess($manifest, 'Retrieve icon')) {
    try {
        $IconLocation = Save-ClickOnceApplicationIcon -Manifest $manifest
    } catch {
        Write-Warning ('Unable to get icon for {0}: {1}' -f $AppName, $_.Exception.Message)
    }
}

if ($PSCmdlet.ShouldProcess($Location, 'Create shortcut')) {
    if (-not(Test-Path -PathType Container -Path $shortcutDir)) {
        mkdir $shortcutDir
    }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Location)

    # if ($Arguments) {$shortcut.Arguments = $Arguments}
    if ($Description) {$shortcut.Destination = $Destination}
    # if ($Hotkey) {$shortcut.Hotkey = $Hotkey}
    if ($IconLocation) {$shortcut.IconLocation = $IconLocation}
    if ($TargetPath) {$shortcut.TargetPath = $TargetPath}
    # if ($WindowStyle) {$shortcut.WindowStyle = $WindowStyle}
    # if ($WorkingDirectory) {$shortcut.WorkingDirectory = $WorkingDirectory}

    $shortcut.Save()
    $shortcut
}
