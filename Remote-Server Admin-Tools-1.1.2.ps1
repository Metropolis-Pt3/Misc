
<#
.SUMMARY
    Install Remote Server Administration Tools (RSAT)

.PARAMETERS
    .\Remote-Server-Admin-Tools-1.1.2.ps1

    -RSAT All = Install all defined RSAT tools in the list

    -AD = Install Active Directory AD/DS Tools

    -GPO = Installs Group Policy Management Tools

    -DNS = Installs DNS Management Tools

    -DHCP = Installs DHCP Management Tools

    -Server = Installs Server Manager Tools

    -Cert = Install Certificate Management Tools

    -HyperV = Intstalls Hypver-V Management Console and Tools

    -VolAct = Install Volume Activation Tools

    -WSUS = Install Windows software Update Service Tools

    Example
    .\Remote-Server-Admin-Tools-1.1.2.ps1 -RSAT ALL = Installs all RSAT tools defined in this script.

    .\Remote-Server-Admin-Tools-1.1.2.ps1 -AD -GPO = Installs only the Active Directory Directory Service and Group Policy Management Tools. Add switches to include more products.

.NOTES/REFERENCES
    Current Version = v1.1.2

    Changelog
    4.29.206 - Initial script created. v1.0.2
    4.30.2026 - Add function logic for installation as a suite. v1.1.2

#>

[CmdletBinding(SupportsShouldProcess = $true)]
Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("All")]
    [string]$RSAT,

    [switch]$AD,
    [switch]$GPO,
    [switch]$DNS,
    [switch]$DHCP,
    [switch]$Server,
    [switch]$Cert,
    [switch]$HyperV,
    [switch]$VolAct,
    [switch]$WSUS
)

# Helper function
function Install-RSATCapability {
    param ([string]$Name)

    if ($PSCmdlet.ShouldProcess($Name, "Install RSAT capability")) {
        Add-WindowsCapability -Online -Name $Name
    }
}

# ---- Install ALL RSAT ----
if ($RSAT -eq "All") {
    Install-RSATCapability "RSAT.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
    Install-RSATCapability "RSAT.GroupPolicy.Management.Tools~~~~0.0.1.0"
    Install-RSATCapability "RSAT.DNS.Tools~~~~0.0.1.0"
    Install-RSATCapability "RSAT.DHCP.Tools~~~~0.0.1.0"
    Install-RSATCapability "RSAT.ServerManager.Tools~~~~0.0.1.0"
    Install-RSATCapability "RSAT.CertificateServices.Tools~~~~0.0.1.0"
    Install-RSATCapability "RSAT.Hyper-V.Tools~~~~0.0.1.0"
    Install-RSATCapability "RSAT.VolumeActivation.Tools~~~~0.0.1.0"
    Install-RSATCapability "RSAT.WSUS.Tools~~~~0.0.1.0"
    return
}

# ---- Selective installs ----
if ($AD) {
    Install-RSATCapability "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
}

if ($GPO) {
    Install-RSATCapability "RSAT.GroupPolicy.Management.Tools~~~~0.0.1.0"
}

if ($DNS) {
    Install-RSATCapability "RSAT.DNS.Tools~~~~0.0.1.0"
}

if ($DHCP) {
    Install-RSATCapability "RSAT.DHCP.Tools~~~~0.0.1.0"
}

if ($Server) {
    Install-RSATCapability "RSAT.ServerManager.Tools~~~~0.0.1.0"
}

if ($Cert) {
    Install-RSATCapability "RSAT.CertificateServices.Tools~~~~0.0.1.0"
}

if ($HyperV) {
    Install-RSATCapability "RSAT.Hyper-V.Tools~~~~0.0.1.0"
}

if ($VolAct) {
    Install-RSATCapability "RSAT.VolumeActivation.Tools~~~~0.0.1.0"
}

if ($WSUS) {
    Install-RSATCapability "RSAT.WSUS.Tools~~~~0.0.1.0"
}

