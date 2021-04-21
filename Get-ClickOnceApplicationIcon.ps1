. .\Import-ClickOnceManifest.ps1

function Get-ClickOnceApplicationIcon {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Manifest
    )
    # TODO: identify if it's a deployment manifest or app manifest & handle appopriately
    # TODO: use/retry using deployment manifest from /assembly/deployment/deploymentProvider/@codebase if present - $Manifest may not point to current program version and host may only provide current version

    [xml]$deploymentManifest = Import-ClickOnceManifest $Manifest

    # Get the canonical manifest location
    [uri]$deploymentManifestSourcePath = $deploymentManifest.assembly.deployment.deploymentProvider.codebase
    $deploymentManifestDir = ([uri]::new($deploymentManifestSourcePath, '.')).OriginalString # gets dir for both files & urls

    [uri]$appManifestPath = [System.IO.Path]::Combine($deploymentManifestDir, $deploymentManifest.assembly.dependency.dependentAssembly.codebase)
    [xml]$appManifest = Import-ClickOnceManifest $appManifestPath

    $iconfilename = $appManifest.assembly.description.iconFile + '.deploy'
    $appManifestDir = ([uri]::new($appManifestPath, '.')).OriginalString # gets dir for both files & urls
    [uri]$iconPath = [System.IO.Path]::Combine($appManifestDir, $iconfilename)
    Write-Output ($iconPath.ToString())
}
