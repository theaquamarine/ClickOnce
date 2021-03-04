<#
.SYNOPSIS
    Download and install a ClickOnce application
.EXAMPLE
    PS C:\> Install-ClickOnceApplication.ps1 'https://lovettsoftwarestorage.blob.core.windows.net/downloads/XmlNotepad/XmlNotepad.application'
    Download and install XML Notepad
.NOTES
    https://docs.microsoft.com/en-us/dotnet/api/system.deployment.application.inplacehostingmanager?view=netframework-4.8
#>

[CmdletBinding()]
param (
    [Parameter()]
    # The manifest file to install
    [uri]$manifest = 'https://lovettsoftwarestorage.blob.core.windows.net/downloads/XmlNotepad/XmlNotepad.application',
    # The file to log to, defaulting to %temp%\ClickOnceInstall.log
    [string]$logfile = (Join-Path $env:temp 'ClickOnceInstall.log')
)

function Write-LogEntry {
    # Write a log file in ConfigMgr format
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$message,
        #Severity 1=Information, 2=Warning, 3=Error
        $Severity = 1
    )
    $item = '<![LOG[' + $message + ']LOG]!>'
    $time = 'time="' + (Get-Date -Format HH:mm:ss.fff) + '+000"' #Should actually be the bias
    $date = 'date="' + (Get-Date -Format MM-dd-yyyy) + '"'
    $component = 'component="ClickOnceInstaller"'
    $context = 'context=""'
    $type = 'type="' + $Severity + '"'  #Severity 1=Information, 2=Warning, 3=Error
    $thread = 'thread="' + $PID + '"'
    $file = 'file="{0}"' -f $application

    $logblock = ($time, $date, $component, $context, $type, $thread, $file) -join ' '
    $logblock = '<' + $logblock + '>'

    if ($logfile) {
        $item + $logblock | Out-File -Encoding utf8 -Append $logFile
    }
    switch ($Severity) {
        0 {Write-Debug $message}
        1 {Write-Verbose $message}
        2 {Write-Warning $message}
        3 {Write-Error $message}
    }
} # Write-LogEntry

try {
    #region prep InPlaceHostingManager
    $application = Split-Path $manifest -Leaf
    Write-LogEntry "Installing $manifest"
    Add-Type -AssemblyName System.Deployment
    $iphm = [System.Deployment.Application.InPlaceHostingManager]::new($manifest, $false)
    Register-ObjectEvent -InputObject $iphm -EventName DownloadApplicationCompleted -SourceIdentifier 'DownloadApplicationCompleted' -ErrorAction Stop | Out-Null
    # Register-ObjectEvent -InputObject $iphm -EventName DownloadProgressChanged -Action {Write-Host "Downloading..."} | Out-Null
    Register-ObjectEvent -InputObject $iphm -EventName 'GetManifestCompleted' -SourceIdentifier 'GetManifestCompleted' -ErrorAction Stop | Out-Null
    #endregion prep InPlaceHostingManager

    #region download & install application
    Write-LogEntry "Downloading manifest $manifest"
    $iphm.GetManifestAsync()
    $e = Wait-Event -SourceIdentifier 'GetManifestCompleted' -Timeout 60
    if ($null -ne $e.SourceArgs.Error) {
        throw $e.SourceArgs.Error
    }
    Write-LogEntry "$application download complete"
    $iphm.AssertApplicationRequirements($true)
    Write-LogEntry "Downloading application $application"
    $iphm.DownloadApplicationAsync()
    $e = Wait-Event -SourceIdentifier 'DownloadApplicationCompleted' -Timeout 60
    if ($null -ne $e.SourceArgs.Error) {
        throw $e.SourceArgs.Error
    }
    #endregion download & install application
} catch {
    $message = 'Error installing ' + $application + ' : ' + $_.Exception.Message + ' ' + $_.Exception.InnerException.Message
    Write-LogEntry -Severity 3 $message
    if ($_.Exception.HResult) {
        exit $_.Exception.HResult
    } else {exit 1}
} finally {
    Get-EventSubscriber |
        Where-Object SourceObject -is [System.Deployment.Application.InPlaceHostingManager] |
        Unregister-Event
    $iphm.Dispose()
}

Write-LogEntry ($application + ' installed successfully.')
exit 0
