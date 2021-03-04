# ClickOnce install tools

## Install-ClickOnceApplication

Download and install a ClickOnce application without user interaction.

### Usage

Download and install XML Notepad

```powershell
PS C:\> Install-ClickOnceApplication.ps1 'https://lovettsoftwarestorage.blob.core.windows.net/downloads/XmlNotepad/XmlNotepad.application'
```

## New-CMClickOnceApplication

Create an application in Configuration Manager using the details from a ClickOnce deployment manifest and a deployment type to silently install it using Install-ClickOnceApplication.ps1 for users.

### Usage

To create a ConfigMgr application to silently install XML Notepad, copy `Install-ClickOnceApplication.ps1` to your content location and run
```powershell
PS P01:\> New-CMClickOnceApplication.ps1 -Manifest "https://lovettsoftwarestorage.blob.core.windows.net/downloads/XmlNotepad/XmlNotepad.application" -ContentLocation '\\localhost\c\ClickOnce'
```
