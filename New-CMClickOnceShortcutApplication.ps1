<#
.SYNOPSIS
    Create a ConfigMgr application & deployment type for a ClickOnce shortcut
.DESCRIPTION
    Create an application in Configuration Manager which creates a start menu shortcut to a ClickOnce application, for network-only ClickOnce deployments.
.EXAMPLE
    PS P01:\> . 'C:New-CMClickOnceShortcutApplication.ps1' -Manifest 'http://configmgr/ReportServer/ReportBuilder/ReportBuilder_3_0_0_0.application' -ContentLocation '\\localhost\c$\Users\Administrator\ClickOnce' -Description 'Actually XML Notepad' -Product 'Important Software' -Folder 'Tailspin Toys' -IconFile C:\Users\Administrator\icon.ico -IconSaveLocation 'TailSpin Icons'

    Create a start menu shortcut called 'Important Software' in a 'Tailspin Toys' folder which launches Report Builder, with an icon from C:\Users\Administrator\icon.ico stored in %AppData%\TailSpin Icons\icon.ico.
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
    $IconSaveLocation,
    # The icon to display in Software Center
    $ApplicationIcon,
    # The publisher to display in Software Center
    $ApplicationPublisher
)
# TODO: Get properties from manifest if not specified
# TODO: Delete icon & folder if empty when uninstalling

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
if ($ApplicationPublisher) {
    $appsplat['Publisher'] = $ApplicationPublisher
} else {
    $appsplat['Publisher'] = $Folder -split '\\|/' | Select -First 1
}

# if ($manifestContent.assembly.description.supportUrl) {
#     $appSplat['UserDocumentation'] = $manifestContent.assembly.description.supportUrl
# }
if ($Description) {
    $appsplat['Description'] = $Description
    $appsplat['LocalizedDescription'] = $Description
}
if ($ApplicationIcon) {$appsplat['IconLocationFile'] = $ApplicationIcon}
elseif ($IconFile) {
    if (Test-Path $IconFile) {$appsplat['IconLocationFile'] = $IconFile}
    elseif (Test-Path (Join-Path $ContentLocation $IconFile)) {
        $appsplat['IconLocationFile'] = Join-Path $ContentLocation $IconFile
    }
}


New-CMApplication @appsplat -ErrorAction Stop
#endregion Application

#region Detection & uninstall scripts
if (Split-Path -IsAbsolute $Folder) {
    # Path is absolute so we know where it will be installed in advance
    $location = Join-Path $Folder ($Product + '.lnk')
    $detectionScript = @'
if (Test-Path '{0}') {{'Installed'}}
'@ -f $location
    $uninstallCommand = @'
powershell.exe -noninteractive -noprofile -executionpolicy bypass -command "Remove-Item '{0}'"
'@ -f $location
} else {
    # Path is relative to $Programs so must be worked out as user
    $location = @'
Join-Path (Join-Path ([System.Environment]::GetFolderPath('Programs')) '{0}') ('{1}' + '.lnk')
'@ -f $Folder, $Product
    $detectionScript = @'
if (Test-Path ({0})) {{'Installed'}}
'@ -f $location
    $uninstallCommand = @'
powershell.exe -noninteractive -noprofile -executionpolicy bypass -command "Remove-Item ({0})"
'@ -f $location
}
#endregion Detection & uninstall scripts

#region Deployment Type
$dtsplat = @{
    ApplicationName = $appsplat.Name
    DeploymentTypeName = '{0} ClickOnce Shortcut Installer' -f $appsplat.Name
    InstallCommand = 'powershell.exe -noprofile -noninteractive -executionpolicy bypass -File New-ClickOnceApplicationShortcut.ps1 -Manifest "{0}" -Product "{1}" -Folder "{2}" -Description "{3}" -IconFile "{4}" -IconSaveLocation "{5}"' -f $manifest, $Product, $Folder, $Description, $IconFile, $IconSaveLocation
    ScriptText = $detectionScript
    ScriptLanguage = 'PowerShell'
    InstallationBehaviorType = 'InstallForUser'
    ContentLocation = $ContentLocation
    UserInteractionMode = 'Hidden'
    UninstallCommand = $uninstallCommand
    UninstallOption = 'NoneRequired'
}

Add-CMScriptDeploymentType @dtsplat -ErrorAction Stop
#endregion Deployment Type
