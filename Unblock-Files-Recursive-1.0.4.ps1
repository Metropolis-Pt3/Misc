<#
.SUMMARY
    Unblock files recursively

.PARAMETERS
    -Location = location to unblock files

.NOTES
    Version = 1.0.4
    Date: 05.27.2026

    Changelog:
    5.27.2026
        - Initial script created. v1.0.2
        - Fixed logic and functions. v1.0.4

#>

[CmdletBinding(SupportsShouldProcess = $True)]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$Location
)

# VARIABLES
$ErrorActionPreference = "Stop"
$timestamp = (Get-Date).ToString("MM-dd-yyyy-HH:mm:ss")

# FUNCTION
function Get-TimeStamp {
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

# LOGGING
$LogPath = "$env:ProgramData\Unblock-Files-Recursive.log"
$LogDir = Split-Path $LogPath

if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

Start-Transcript -Path $LogPath -Append

# STATUS
$64Bit = [Environment]::Is64BitProcess
Write-Host "$(Get-TimeStamp) Is64BitProcess = $64Bit" -ForegroundColor Green

# MAIN LOGIC
if (Test-Path $Location) {
    Write-Host "$(Get-TimeStamp) Processing: $Location" -ForegroundColor Cyan
    
    Get-ChildItem -Path $Location -Recurse -File | Unblock-File
}
else {
    Write-Host "$(Get-TimeStamp) ERROR: Path not found: $Location" -ForegroundColor Red
}

Stop-Transcript

