<#
.SYNOPSIS
    Create a ConfigMgr application & deployment type for a ClickOnce deployment manifest
.DESCRIPTION
    Create an application in Configuration Manager using the details from a ClickOnce deployment manifest and a deployment type to silently install it using Install-ClickOnceApplication.ps1 for users.
.EXAMPLE
    PS P01:\> C:New-CMClickOnceApplication.ps1 -Manifest "https://lovettsoftwarestorage.blob.core.windows.net/downloads/XmlNotepad/XmlNotepad.application" -ContentLocation '\\localhost\c\ClickOnce'
    Create a ConfigMgr application to silently install XML Notepad using Install-ClickOnceApplication.ps1 located in \\localhost\c\ClickOnce

    PS P01:\> . 'c:\Users\Administrator\clickonce\New-CMClickOnceApplication.ps1' 'https://sccmclictr.azurewebsites.net/ClickOnce/SCCMCliCtrWPF.application' '\\localhost\c$\Packages\ClickOnce'
    Create a ConfigMgr application for Client Center for Configuration Manager's ClickOnce installer
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    # The application manifest to package
    [Parameter(Mandatory)]
    [string]$manifest,
    # The location to use as the deployment type's content location, containing 'Install-ClickOnceApplication.ps1'
    [Parameter(Mandatory)]
    [string]$ContentLocation,
    [Parameter(Mandatory)]
    [string]$Description,
    [Alias('AppName','Name')]
    [Parameter(Mandatory)]
    [string]$Product,
    # The location to put the shortcut, absolute or relative to the user's Programs folder. Defaults to $programs\$publisher\$suite from the manifest.
    [Alias('Publisher','MenuStructure','Location')]
    [Parameter(Mandatory)]
    [string]$Folder,
    # The icon to use for the shortcut. Defaults to icon from manifest.
    [Parameter(Mandatory)]
    $IconFile,
    # The location to save the application icon to. Defaults to %temp%.
    [Parameter(Mandatory)]
    $IconSaveLocation
)

if (-not($Product -and $Folder)) {
    # Only load the manifest if we actually need something from it
    . .\Import-ClickOnceManifest.ps1
    [xml]$xml = Import-ClickOnceManifest $manifest -ErrorAction Stop
}

# if (-not($Product)) {$Product = $xml.assembly.description.product}
# $Publisher = $xml.assembly.description.publisher
# $Suite = $xml.assembly.description.suite

#region Application
$appsplat = @{
    Name = $Product
}

# Use first folder in path as Publisher
$appsplat['Publisher'] = $Folder -split '\\|/' | Select -First 1

# if ($manifestContent.assembly.description.supportUrl) {
#     $appSplat['UserDocumentation'] = $manifestContent.assembly.description.supportUrl
# }
if ($Description) {$appsplat['Description'] = $Description}
if ($IconFile -and (Test-Path $IconFile)) {$appsplat['IconLocationFile'] = $IconFile}

New-CMApplication @appsplat -ErrorAction Stop
#endregion Application

#region Detection script
# TODO: Work out detection script/$shortcutDir in advance? Can at least decide if it's absolute or not
if (Split-Path -IsAbsolute $Folder) {
    # Path is absolute so we know where it will be installed in advance
    $location = Join-Path $Folder ($Product + '.lnk')
    $detectionScript = @'
if (Test-Path '{0}') {{'Installed'}}
'@ -f $location
} else {
    # Path is relative to $Programs so must be worked out as user
    $location = @'
Join-Path (Join-Path ([System.Environment]::GetFolderPath('Programs')) '{0}') ('{1}' + '.lnk')
'@ -f $Folder, $Product
    $detectionScript = @'
if (Test-Path ({0})) {{'Installed'}}
'@ -f $location
}
#endregion Detection script

#region Deployment Type
$dtsplat = @{
    ApplicationName = $appsplat.Name
    DeploymentTypeName = '{0} ClickOnce Installer' -f $appsplat.Name
    InstallCommand = 'powershell.exe -noprofile -noninteractive -executionpolicy bypass -File New-ClickOnceApplicationShortcut.ps1 -Manifest "{0}" -Product "{1}" -Folder "{2}" -Description "{3}" -IconFile "{4}" -IconSaveLocation "{5}"' -f $manifest, $Product, $Folder, $Description, $IconFile, $IconSaveLocation
    ScriptText = $detectionScript
    ScriptLanguage = 'PowerShell'
    InstallationBehaviorType = 'InstallForUser'
    ContentLocation = $ContentLocation
    UserInteractionMode = 'Hidden'
#     UninstallCommand = @'
# powershell.exe -noninteractive -noprofile -executionpolicy bypass -command "exit 0"
# '@
#     UninstallOption = 'NoneRequired'
}

Add-CMScriptDeploymentType @dtsplat -ErrorAction Stop
#endregion Deployment Type
