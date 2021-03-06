<#
.SYNOPSIS
    Add a start menu shortcut to "install" a network-only ClickOnce application
.EXAMPLE
    PS C:\> New-ClickOnceApplicationShortcut.ps1 'http://configmgr/ReportServer/ReportBuilder/ReportBuilder_3_0_0_0.application'
    Add a shortcut for Report Builder to the start menu
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    # The manifest file to install
    [Parameter(Mandatory)]
    $Manifest,
    # The name to install the app as. Defaults to product name from manifest.
    [Alias('AppName','Name')]
    [string]$Product,
    # The location to put the shortcut, absolute or relative to the user's Programs folder. Defaults to $programs\$publisher\$suite from the manifest.
    [Alias('Publisher','MenuStructure','Location')]
    [string]$Folder,
    [string]$Description,
    # The icon to use for the shortcut. Defaults to icon from manifest.
    $IconFile,
    # The location to save the application icon to, relative to %AppData%. Defaults to %temp%.
    $IconSaveLocation
)
    # Combine Folder + Product into single param with path + shortcut name?
        # Create normal Product.lnk if it's not a shortcut
    # $Folder may be a better default icon save location? Images wouldn't be shown on start menu
    # TODO: Other shortcut parameters:
        # $Arguments,
        # [string]$Hotkey,
        # $WindowStyle,
        # $WorkingDirectory
    # TODO: consider populating ARP, act like a custom installer? https://docs.microsoft.com/en-us/visualstudio/deployment/walkthrough-creating-a-custom-installer-for-a-clickonce-application?view=vs-2019

. .\Save-ClickOnceApplicationIcon.ps1

if (-not($Product -and $Folder)) {
    # Only load the manifest if we actually need something from it
    . .\Import-ClickOnceManifest.ps1
    [xml]$xml = Import-ClickOnceManifest $manifest -ErrorAction Stop
}

if (-not($Product)) {$Product = $xml.assembly.description.product}
$Publisher = $xml.assembly.description.publisher
$Suite = $xml.assembly.description.suite

if (-not($Folder)) { 
    $Folder = if ($Suite) { Join-Path $Publisher $Suite} else {$Publisher}
}

$shortcutDir = if (Split-Path -IsAbsolute $Folder) {$Folder} else {
    Join-Path ([System.Environment]::GetFolderPath('Programs')) $Folder
}

$location = Join-Path $shortcutDir ($Product + '.lnk')

#region App Icon
$iconSplat = @{}
if ($IconFile) {
    $iconSplat['IconFile'] = $IconFile
    $iconsouce = $IconFile
}
else {
    $iconSplat['Manifest'] = $Manifest
    $iconsouce = $Manifest
}
if ($IconSaveLocation) {$iconSplat['Destination'] = $IconSaveLocation}

try {
    if ($PSCmdlet.ShouldProcess($iconsouce, 'Save icon')) {
        $IconLocation = Save-ClickOnceApplicationIcon @iconSplat
    }
} catch {
    Write-Warning ('Unable to get icon for {0}: {1}' -f $Product, $_.Exception.Message)
}
#endregion App Icon

if ($PSCmdlet.ShouldProcess($Location, 'Create shortcut')) {
    if (-not(Test-Path -PathType Container -Path $shortcutDir)) {
        mkdir $shortcutDir
    }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($Location)
    $shortcut.TargetPath = $Manifest

    # if ($Arguments) {$shortcut.Arguments = $Arguments}
    if ($Description) {$shortcut.Description = $Description}
    # if ($Hotkey) {$shortcut.Hotkey = $Hotkey}
    if ($IconLocation) {$shortcut.IconLocation = $IconLocation}
    # if ($WindowStyle) {$shortcut.WindowStyle = $WindowStyle}
    # if ($WorkingDirectory) {$shortcut.WorkingDirectory = $WorkingDirectory}

    $shortcut.Save()
    $shortcut
}

# TODO: run install afterwards? No idea if it actually does anything, but seems a popular thing to do.
# Install-ClickOnceApplication.ps1 -Manifest $Manifest
