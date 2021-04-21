function Import-ClickOnceManifest {
    # Import an XML manifest from web or file URIs
    [CmdletBinding()]
    param (
        # Manifest to import
        [Parameter(Mandatory)]
        [string]$Manifest 
    )
    # TODO: Option to use deployment manifest (or retry using it) from /assembly/deployment/deploymentProvider/@codebase if present

    if (($uri = $manifest -as [uri]) -and ($uri.scheme -in 'http','https')) {
        # There has got to be an easier way to deal with the BOM
        $content = Invoke-WebRequest $manifest -ErrorAction Stop| Select-Object -ExpandProperty Content
        
        if ($content[0] -is [Char]) {
            # Clean the BOM
            $bom = [System.Text.Encoding]::UTF8.GetPreamble()
            if ($content.StartsWith([System.Text.Encoding]::UTF8.GetString($bom))) {
                $content = $content.Remove(0, $bom.Length)
            }
            [xml]$manifestContent = $content
        } else { # it's a [Byte]
            $manifestContent = [System.Xml.XmlDocument]::new()
            $ms = [System.IO.MemoryStream]::new($content)
            $manifestContent.Load($ms)
        }
    } else {
        # Might be neater to just use [uri] param
        if (($uri = $manifest -as [uri]) -and ($uri.scheme -eq 'file')) {
            $Manifest = $uri.AbsolutePath
        }

        [xml]$manifestContent = Get-Content $manifest
    }
    $manifestContent
}
