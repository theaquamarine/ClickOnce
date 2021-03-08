<#
.SYNOPSIS
    Create a ConfigMgr application & deployment type for a ClickOnce deployment manifest
.DESCRIPTION
    Create an application in Configuration Manager using the details from a ClickOnce deployment manifest and a deployment type to silently install it using Install-ClickOnceApplication.ps1 for users.
.EXAMPLE
    PS P01:\> New-CMClickOnceApplication.ps1 -Manifest "https://lovettsoftwarestorage.blob.core.windows.net/downloads/XmlNotepad/XmlNotepad.application" -ContentLocation '\\localhost\c\ClickOnce'
    Create a ConfigMgr application to silently install XML Notepad using Install-ClickOnceApplication.ps1 located in \\localhost\c\ClickOnce
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    # The application manifest to package
    [Parameter(Mandatory)]
    [string]$manifest,
    # The location to use as the deployment type's content location, containing 'Install-ClickOnceApplication.ps1'
    [Parameter(Mandatory)]
    [string]$ContentLocation
)

# read the application's manifest
if (($uri = $manifest -as [uri]) -and ($uri.scheme -in 'http','https')) {
    # There has got to be an easier way to deal with the BOM
    $content = Invoke-WebRequest $manifest | Select-Object -ExpandProperty Content
    $manifestContent = [System.Xml.XmlDocument]::new()
    $manifestContent.Load([System.IO.MemoryStream]::new($content))
} else {
    [xml]$manifestContent = Get-Content $manifest
}


#region Application
$appsplat = @{
    Name = $manifestContent.assembly.description.product
    Publisher = $manifestContent.assembly.description.publisher
}
if ($manifestContent.assembly.description.supportUrl) {
    $appSplat['UserDocumentation'] = $manifestContent.assembly.description.supportUrl
}

New-CMApplication @appsplat -ErrorAction Stop
#endregion Application

#region Deployment Type
$dtsplat = @{
    ApplicationName = $appsplat.Name
    DeploymentTypeName = '{0} ClickOnce Installer' -f $appsplat.Name
    InstallCommand = 'powershell.exe -noprofile -noninteractive -executionpolicy bypass -File Install-ClickOnceApplication.ps1 -Manifest {0}' -f $manifest
    ScriptText = @'
Get-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*,HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | ? DisplayName -like '{0}'
'@ -f $appsplat.Name
    ScriptLanguage = 'PowerShell'
    InstallationBehaviorType = 'InstallForUser'
    ContentLocation = $ContentLocation
    UserInteractionMode = 'Hidden'
    UninstallCommand = @'
powershell.exe -noninteractive -noprofile -executionpolicy bypass -command "& {{cmd.exe /C (gp HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*,HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue | ? DisplayName -like '{0}' | Select -ExpandProperty UninstallString)}}"
'@ -f $appsplat.Name # Or get the details from the manifest?
    UninstallOption = 'NoneRequired'
}

Add-CMScriptDeploymentType @dtsplat -ErrorAction Stop
#endregion Deployment Type
