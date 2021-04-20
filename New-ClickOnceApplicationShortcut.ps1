<#
.SYNOPSIS
    Add a start menu shortcut to "install" a network-only ClickOnce application
.EXAMPLE
    PS C:\> New-ClickOnceApplicationShortcut.ps1 'http://configmgr/ReportServer/ReportBuilder/ReportBuilder_3_0_0_0.application'
    Add a shortcut for Report Builder to the start menu
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
    [Alias('AppName','Name')]
    [string]$Product,
    # The folder to list the app in on the start menu. Defaults to publisher from the manifest.
    [Parameter(ParameterSetName='Folder')][Alias('Publisher','MenuStructure')]
    [string]$Folder,
    [string]$Description
)
    # TODO: Fix Location ParameterSet, rename to ExplicitLocation or something.
        # TODO: Consider removing Publisher/Suite param.
        # Relative to Programs
        # Create normal Product.lnk if it's not a shortcut
    # $IconLocation, # default to try from manifest
    # $IconSaveLocation to pass to Save-ClickOnceApplicationIcon
    # Other shortcut parameters:
        # $Arguments,
        # [string]$Hotkey,
        # $WindowStyle,
        # $WorkingDirectory
    # TODO: consider populating ARP, act like a custom installer? https://docs.microsoft.com/en-us/visualstudio/deployment/walkthrough-creating-a-custom-installer-for-a-clickonce-application?view=vs-2019

. .\Import-ClickOnceManifest.ps1
. .\Save-ClickOnceApplicationIcon.ps1

[xml]$xml = Import-ClickOnceManifest $manifest

$TargetPath = $Manifest

if (-not($Product)) {$Product = $xml.assembly.description.product}
$Publisher = $xml.assembly.description.publisher
$Suite = $xml.assembly.description.suite

if (-not($Folder)) { 
    $Folder = if ($Suite) { Join-Path $Publisher $Suite} else {$Publisher}
}

# TODO: if not $Folder.IsAbsolute {$Folder = Join-Path ([System.Environment]::GetFolderPath('Programs')) ($Folder)}

$shortcutDir = Join-Path ([System.Environment]::GetFolderPath('Programs')) ($Folder)
$location = Join-Path $shortcutDir ($Product + '.lnk')

if ($PSCmdlet.ShouldProcess($manifest, 'Retrieve icon')) {
    try {
        $IconLocation = Save-ClickOnceApplicationIcon -Manifest $manifest
    } catch {
        Write-Warning ('Unable to get icon for {0}: {1}' -f $Product, $_.Exception.Message)
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

# TODO: run install afterwards? No idea if it actually does anything, but seems a popular thing to do.
