# =====================================================================
# Microsoft Autopilot / Intune / Entra ID Connectivity Validation
# Author: Microsoft Endpoint Validation Script
# =====================================================================

$OutputFolder = "C:\Temp"
$CsvFile = Join-Path $OutputFolder "Autopilot_Intune_Connectivity_$(Get-Date -Format yyyyMMdd_HHmmss).csv"

if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null
}

$Endpoints = @(

    # ---------------------------
    # Autopilot
    # ---------------------------
    "ztd.dds.microsoft.com",
    "cs.dds.microsoft.com",

    # ---------------------------
    # Entra ID Authentication
    # ---------------------------
    "login.microsoftonline.com",
    "device.login.microsoftonline.com",
    "enterpriseregistration.windows.net",
    "login.live.com",

    # ---------------------------
    # Intune
    # ---------------------------
    "manage.microsoft.com",
    "graph.microsoft.com",

    # ---------------------------
    # Device Management
    # ---------------------------
    "enrollment.manage.microsoft.com",
    "portal.manage.microsoft.com",

    # ---------------------------
    # Device Metadata
    # ---------------------------
    "dmd.metaservices.microsoft.com",

    # ---------------------------
    # Windows Activation
    # ---------------------------
    "activation.sls.microsoft.com",
    "activation-v2.sls.microsoft.com",
    "validation.sls.microsoft.com",
    "validation-v2.sls.microsoft.com",
    "licensing.mp.microsoft.com",

    # ---------------------------
    # Device Registration
    # ---------------------------
    "device.login.microsoftonline.com",

    # ---------------------------
    # Common Microsoft Endpoints
    # ---------------------------
    "www.msftconnecttest.com",
    "www.msftncsi.com",
    "officecdn.microsoft.com",
    "config.office.com",

    # ---------------------------
    # Windows Store / CDN
    # ---------------------------
    "storeedgefd.dsx.mp.microsoft.com",

    # ---------------------------
    # TPM Attestation
    # ---------------------------
    "ekop.intel.com",
    "ekcert.spserv.microsoft.com",
    "ftpm.amd.com"

)

$Results = @()

foreach ($Endpoint in $Endpoints) {

    Write-Host "Testing $Endpoint..." -ForegroundColor Cyan

    $DNSResult = $null
    $PortStatus = $false
    $IPAddress = $null
    $Latency = $null
    $CertSubject = $null
    $ErrorText = $null

    try {

        $Dns = Resolve-DnsName $Endpoint -ErrorAction Stop |
            Where-Object {$_.Type -eq "A"} |
            Select-Object -First 1

        $IPAddress = $Dns.IPAddress
        $DNSResult = "Success"

    }
    catch {
        $DNSResult = "Failed"
        $ErrorText = $_.Exception.Message
    }

    try {

        $Test = Test-NetConnection `
            -ComputerName $Endpoint `
            -Port 443 `
            -WarningAction SilentlyContinue

        $PortStatus = $Test.TcpTestSucceeded

        if ($Test.PingSucceeded) {
            $Latency = $Test.PingReplyDetails.RoundtripTime
        }

    }
    catch {
        if (-not $ErrorText) {
            $ErrorText = $_.Exception.Message
        }
    }

    try {

        $Request = [System.Net.HttpWebRequest]::Create("https://$Endpoint")
        $Request.Timeout = 10000
        $Request.Method = "HEAD"

        $Response = $Request.GetResponse()
        $Certificate = $Request.ServicePoint.Certificate

        if ($Certificate) {
            $CertSubject = $Certificate.Subject
        }

        $Response.Close()
    }
    catch {
        # Expected for some Microsoft services
    }

    $Results += [PSCustomObject]@{
        Endpoint        = $Endpoint
        DNS_Status      = $DNSResult
        IPAddress       = $IPAddress
        TCP443_Reachable= $PortStatus
        LatencyMS       = $Latency
        Certificate     = $CertSubject
        Error           = $ErrorText
        TestedOn        = Get-Date
    }
}

$Results | Export-Csv -Path $CsvFile -NoTypeInformation -Encoding UTF8

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "Connectivity Test Complete" -ForegroundColor Green
Write-Host "Results saved to:" -ForegroundColor Green
Write-Host $CsvFile -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""

$Results | Sort-Object Endpoint | Format-Table -AutoSize