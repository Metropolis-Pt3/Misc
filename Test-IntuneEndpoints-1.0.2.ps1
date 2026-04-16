
<#
.SUMMARY
  Tests DNS + network connectivity to Microsoft Intune endpoints referenced in:
  https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-endpoints?tabs=north-america

.DESCRIPTION
  - DNS: Resolve-DnsName (fallback to .NET DNS)
  - Network: TCP connect tests (80/443/etc) using Test-NetConnection when available, else TcpClient
  - Wildcards: "*.domain.com" can't be resolved directly; script tests "domain.com" and notes it
  - Outputs: Console table + optional CSV export

.PARAMETERS
  # From an elevated PowerShell prompt (recommended)
  .\Test-IntuneEndpoints-1.0.2.ps1

  # Export results to CSV
  .\Test-IntuneEndpoints-1.0.2.ps1 -CsvPath .\IntuneEndpointConnectivity.csv

.NOTES/REFERENCES
  Current Version = 1.0.2
  
  Windows PowerShell 5.1 compatible.
  Run in an elevated prompt if your environment restricts outbound testing.

  Changelog:
  4.14.2026 - Initial script created. v1.0.2

#>

[CmdletBinding()]
param(
  [int]$TimeoutMs = 3000,
  [string]$CsvPath = ""
)

# VARIABLES (RUN)
$ErrorActionPreference = "SilentlyContinue"
$timestamp = (Get-Date).ToString("MM-dd-yyyy-HH:mm:ss")

# START LOGGING
#Get-timestamp for logging
function Get-TimeStamp {  
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)  
}

#Log path/name/location
$LogPath = "c:\ESD\Logs\Test-IntuneEndpoints.log"
$LogDir = Split-Path $LogPath
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}
Start-Transcript -Path $logPath -Append

# RUNTIME STATUS
$64Bit=[Environment]::Is64BitProcess
Write-Host "$(Get-TimeStamp) Is64BitProcess = $64Bit" -ForegroundColor Green

function Resolve-Host {
  param([Parameter(Mandatory)] [string]$Host)

  # Try Resolve-DnsName first
  try {
    $r = Resolve-DnsName -Name $Host -ErrorAction Stop |
      Where-Object { $_.IPAddress } |
      Select-Object -ExpandProperty IPAddress -Unique
    if ($r) { return @($r) }
  } catch {}

  # Fallback: .NET DNS
  try {
    $ips = [System.Net.Dns]::GetHostAddresses($Host) | ForEach-Object { $_.IPAddressToString } | Select-Object -Unique
    if ($ips) { return @($ips) }
  } catch {}

  return @()
}

function Test-TcpPort {
  param(
    [Parameter(Mandatory)] [string]$Host,
    [Parameter(Mandatory)] [int]$Port,
    [int]$TimeoutMs = 3000
  )

  # Prefer Test-NetConnection when present
  $tnc = Get-Command Test-NetConnection -ErrorAction SilentlyContinue
  if ($tnc) {
    try {
      $res = Test-NetConnection -ComputerName $Host -Port $Port -WarningAction SilentlyContinue -InformationLevel Quiet
      return [bool]$res
    } catch {
      return $false
    }
  }

  # Fallback: TcpClient with timeout
  try {
    $client = New-Object System.Net.Sockets.TcpClient
    $iar = $client.BeginConnect($Host, $Port, $null, $null)
    if (-not $iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
      $client.Close()
      return $false
    }
    $client.EndConnect($iar)
    $client.Close()
    return $true
  } catch {
    return $false
  }
}

function Normalize-HostForWildcard {
  param([Parameter(Mandatory)] [string]$Host)

  if ($Host -like "*`**") {
    # wildcard like *.manage.microsoft.com => manage.microsoft.com
    return ($Host -replace "^\*\.", "")
  }
  return $Host
}

# Endpoints and ports pulled from the Intune endpoints article (North America tab).
# Includes the entries shown under:
# - Intune core service (manage/dm/EnterpriseEnrollment) TCP 80,443
# - MDM Delivery Optimization TCP 80,443
# - MEM Win32Apps CDN TCP 80,443
# - Auth dependencies login.microsoftonline.com / graph.windows.net TCP 80,443
# - enterpriseregistration.windows.net / certauth... TCP 80,443
# - WNS *.notify.windows.com/*.wns.windows.com TCP 443
# - Remote Help (selected list) TCP 443
# - Autopilot: Windows Update endpoints TCP 80,443; NTP UDP 123; Autopilot WNS deps TCP 443; Intel/AMD/TPM endpoints TCP 443
# - MAA attestation endpoints listed for North America (https://intunemaapeX....attest.azure.net)
# Source: Microsoft Learn article. [1](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/intune-endpoints)

$Targets = @(
  # Intune core service (FQDNs)
  @{ Host="*.manage.microsoft.com"; Ports=@(80,443); Area="Intune core service" },
  @{ Host="manage.microsoft.com";  Ports=@(80,443); Area="Intune core service" },
  @{ Host="*.dm.microsoft.com";    Ports=@(80,443); Area="Intune core service" },
  @{ Host="EnterpriseEnrollment.manage.microsoft.com"; Ports=@(80,443); Area="Intune core service" },

  # Delivery Optimization
  @{ Host="*.do.dsp.mp.microsoft.com"; Ports=@(80,443); Area="Delivery Optimization" },
  @{ Host="*.dl.delivery.mp.microsoft.com"; Ports=@(80,443); Area="Delivery Optimization" },

  # Win32 Apps CDN endpoints
  @{ Host="swda01-mscdn.manage.microsoft.com"; Ports=@(80,443); Area="Win32Apps CDN" },
  @{ Host="swda02-mscdn.manage.microsoft.com"; Ports=@(80,443); Area="Win32Apps CDN" },
  @{ Host="swdb01-mscdn.manage.microsoft.com"; Ports=@(80,443); Area="Win32Apps CDN" },
  @{ Host="swdb02-mscdn.manage.microsoft.com"; Ports=@(80,443); Area="Win32Apps CDN" },
  @{ Host="swdc01-mscdn.manage.microsoft.com"; Ports=@(80,443); Area="Win32Apps CDN" },
  @{ Host="swdc02-mscdn.manage.microsoft.com"; Ports=@(80,443); Area="Win32Apps CDN" },
  @{ Host="swdd01-mscdn.manage.microsoft.com"; Ports=@(80,443); Area="Win32Apps CDN" },
  @{ Host="swdd02-mscdn.manage.microsoft.com"; Ports=@(80,443); Area="Win32Apps CDN" },
  @{ Host="swdin01-mscdn.manage.microsoft.com"; Ports=@(80,443); Area="Win32Apps CDN" },
  @{ Host="swdin02-mscdn.manage.microsoft.com"; Ports=@(80,443); Area="Win32Apps CDN" },

  # Authentication dependencies
  @{ Host="login.microsoftonline.com"; Ports=@(80,443); Area="Auth dependencies" },
  @{ Host="graph.windows.net";         Ports=@(80,443); Area="Auth dependencies" },
  @{ Host="enterpriseregistration.windows.net"; Ports=@(80,443); Area="Auth dependencies" },
  @{ Host="certauth.enterpriseregistration.windows.net"; Ports=@(80,443); Area="Auth dependencies" },

  # Endpoint discovery / general dependency
  @{ Host="go.microsoft.com"; Ports=@(80,443); Area="Endpoint discovery" },

  # WNS dependencies
  @{ Host="*.notify.windows.com"; Ports=@(443); Area="WNS" },
  @{ Host="*.wns.windows.com";    Ports=@(443); Area="WNS" },
  @{ Host="sin.notify.windows.com"; Ports=@(443); Area="WNS" },
  @{ Host="sinwns1011421.wns.windows.com"; Ports=@(443); Area="WNS" },

  # Remote Help (selected list from article)
  @{ Host="*.support.services.microsoft.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="remoteassistance.support.services.microsoft.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="teams.microsoft.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="remoteassistanceprodacs.communication.azure.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="edge.skype.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="aadcdn.msftauth.net"; Ports=@(443); Area="Remote Help" },
  @{ Host="aadcdn.msauth.net"; Ports=@(443); Area="Remote Help" },
  @{ Host="alcdn.msauth.net"; Ports=@(443); Area="Remote Help" },
  @{ Host="wcpstatic.microsoft.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="*.aria.microsoft.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="browser.pipe.aria.microsoft.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="*.events.data.microsoft.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="js.monitor.azure.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="edge.microsoft.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="remotehelp.microsoft.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="api.flightproxy.skype.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="ecs.communication.microsoft.com"; Ports=@(443); Area="Remote Help" },
  @{ Host="*.webpubsub.azure.com"; Ports=@(443); Area="Remote Help (web pubsub)" },

  # Autopilot dependencies
  @{ Host="*.windowsupdate.com"; Ports=@(80,443); Area="Autopilot (WU)" },
  @{ Host="*.dl.delivery.mp.microsoft.com"; Ports=@(80,443); Area="Autopilot (WU/DO)" },
  @{ Host="*.prod.do.dsp.mp.microsoft.com"; Ports=@(80,443); Area="Autopilot (WU/DO)" },
  @{ Host="*.delivery.mp.microsoft.com"; Ports=@(80,443); Area="Autopilot (WU/DO)" },
  @{ Host="*.update.microsoft.com"; Ports=@(80,443); Area="Autopilot (WU)" },
  @{ Host="tsfe.trafficshaping.dsp.mp.microsoft.com"; Ports=@(80,443); Area="Autopilot (WU/Traffic shaping)" },
  @{ Host="adl.windows.com"; Ports=@(80,443); Area="Autopilot (WU)" },

  @{ Host="time.windows.com"; Ports=@(123); Area="Autopilot (NTP UDP 123)" }, # we will treat as TCP test (see note below)

  @{ Host="clientconfig.passport.net"; Ports=@(443); Area="Autopilot (WNS deps)" },
  @{ Host="windowsphone.com"; Ports=@(443); Area="Autopilot (WNS deps)" },
  @{ Host="*.s-microsoft.com"; Ports=@(443); Area="Autopilot (WNS deps)" },
  @{ Host="c.s-microsoft.com"; Ports=@(443); Area="Autopilot (WNS deps)" },

  @{ Host="ekop.intel.com"; Ports=@(443); Area="Autopilot (3rd-party deployment deps)" },
  @{ Host="ekcert.spserv.microsoft.com"; Ports=@(443); Area="Autopilot (3rd-party deployment deps)" },
  @{ Host="ftpm.amd.com"; Ports=@(443); Area="Autopilot (3rd-party deployment deps)" },

  # North America Azure Attestation endpoints (as listed in the article’s DHA/MAA section)
  @{ Host="intunemaape3.cus.attest.azure.net"; Ports=@(443); Area="MAA (NA)" },
  @{ Host="intunemaape4.wus.attest.azure.net"; Ports=@(443); Area="MAA (NA)" },
  @{ Host="intunemaape5.scus.attest.azure.net"; Ports=@(443); Area="MAA (NA)" },
  @{ Host="intunmaape6.ncus.attest.azure.net"; Ports=@(443); Area="MAA (NA)" }
)

$results = New-Object System.Collections.Generic.List[object]

foreach ($t in $Targets) {
  $originalHost = $t.Host
  $hostToTest   = Normalize-HostForWildcard -Host $originalHost
  $isWildcard   = ($originalHost -like "*`**")

  $ips = Resolve-Host -Host $hostToTest
  $dnsOk = ($ips.Count -gt 0)

  foreach ($p in $t.Ports) {
    # Note: time.windows.com uses UDP 123 for NTP in the doc; PS 5.1 doesn't have a universally reliable UDP probe.
    # We'll mark UDP requirement but do a TCP check only (best-effort) unless Test-NetConnection -Udp is available.
    $proto = "TCP"
    $portOk = $false
    $note = ""

    if ($hostToTest -eq "time.windows.com" -and $p -eq 123) {
      $proto = "UDP (required)"
      $tnc = Get-Command Test-NetConnection -ErrorAction SilentlyContinue
      if ($tnc) {
        try {
          # If your OS build supports it, this will do UDP.
          $portOk = [bool](Test-NetConnection -ComputerName $hostToTest -Port 123 -Udp -WarningAction SilentlyContinue -InformationLevel Quiet)
        } catch {
          $portOk = $false
          $note = "UDP probe not supported on this OS/PS; validate UDP/123 via firewall/NTP tooling."
        }
      } else {
        $note = "No UDP probe available; validate UDP/123 via firewall/NTP tooling."
      }
    } else {
      $portOk = Test-TcpPort -Host $hostToTest -Port $p -TimeoutMs $TimeoutMs
    }

    $results.Add([pscustomobject]@{
      Area          = $t.Area
      HostOriginal  = $originalHost
      HostTested    = $hostToTest
      Wildcard      = $isWildcard
      DNS_OK        = $dnsOk
      IPs           = ($ips -join ",")
      Protocol      = $proto
      Port          = $p
      Port_OK       = $portOk
      Notes         = if ($isWildcard) { "Wildcard cannot be resolved directly; tested base domain instead." } else { $note }
    }) | Out-Null
  }
}

# Output
$results |
  Sort-Object Area, HostTested, Port |
  Format-Table -AutoSize Area, HostOriginal, HostTested, DNS_OK, Protocol, Port, Port_OK, Notes

if ($CsvPath) {
  $results | Export-Csv -NoTypeInformation -Path $CsvPath -Encoding UTF8
  Write-Host "CSV written to: $CsvPath"
}

Stop-Transcript
