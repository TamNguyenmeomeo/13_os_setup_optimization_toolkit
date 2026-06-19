[CmdletBinding()]
param(
    [switch]$DryRun
)

# Configure-Windows.ps1
# Automated Windows Configuration & Optimization Toolkit — v2.1 Interactive Menu
# Designed for IT Support and SysAdmin deployment configurations.

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "IT OS Setup & Optimization Toolkit"

# ── Color helpers ─────────────────────────────────────────────────────────────
function Write-Header {
    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║   🛠️  Windows IT Setup & Optimization Toolkit  v2.1      ║" -ForegroundColor Cyan
    Write-Host "║   Automated SysAdmin toolset for IT Support teams        ║" -ForegroundColor DarkCyan
    Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    if ($DryRun) {
        Write-Host "   ⚠️ DRY RUN MODE ACTIVE — No changes will be applied ⚠️" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Write-MenuOption($num, $label) {
    Write-Host "  [" -NoNewline -ForegroundColor DarkGray
    Write-Host "$num" -NoNewline -ForegroundColor Yellow
    Write-Host "]  $label" -ForegroundColor White
}

function Test-IsAdmin {
    $user = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $user.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ── Log to file ───────────────────────────────────────────────────────────────
$LogFile = "$PSScriptRoot\toolkit_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$LogBuffer = [System.Collections.Generic.List[string]]::new()

function Log($msg) {
    $LogBuffer.Add($msg)
    Write-Host $msg
}

# ── Action 1: System Info ─────────────────────────────────────────────────────
function Show-SystemInfo {
    Write-Host "`n[1] Gathering System Diagnostics..." -ForegroundColor Yellow
    $os       = Get-CimInstance Win32_OperatingSystem
    $computer = Get-CimInstance Win32_ComputerSystem
    $cpu      = Get-CimInstance Win32_Processor | Select-Object -First 1
    $disk     = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"

    Log " -> OS Name:       $($os.Caption)"
    Log " -> OS Version:    $($os.Version)"
    Log " -> System Model:  $($computer.Model)"
    Log " -> CPU:           $($cpu.Name)"
    Log " -> Total RAM:     $([Math]::Round($computer.TotalPhysicalMemory / 1GB, 2)) GB"
    Log " -> C: Free Space: $([Math]::Round($disk.FreeSpace / 1GB, 2)) GB of $([Math]::Round($disk.Size / 1GB, 2)) GB"
}

# ── Action 2: Clean Temp Files ────────────────────────────────────────────────
function Clean-TempFiles {
    Write-Host "`n[2] Cleaning Temporary System Files..." -ForegroundColor Yellow
    if ($DryRun) { Write-Host " -> [Dry Run Mode Active]" -ForegroundColor Green }
    $tempPaths = @("$env:TEMP")
    if (Test-IsAdmin) { $tempPaths += "C:\Windows\Temp" }
    else { Log " -> [Notice] Running non-admin: C:\Windows\Temp skipped." }

    $freedBytes = 0
    $limitCount = 0
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue
            foreach ($f in $files) {
                try {
                    $freedBytes += $f.Length
                    if (-not $DryRun) {
                        Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
                    } else {
                        if ($limitCount -lt 10) {
                            Log "    [Dry-run] Would delete: $($f.FullName)"
                            $limitCount++
                        }
                    }
                } catch {}
            }
        }
    }
    if ($DryRun -and $limitCount -eq 10) {
        Log "    ... (only first 10 files listed in Dry-run to avoid flood)"
    }
    $statusText = if ($DryRun) { "Would recover" } else { "recovered" }
    Log " -> Cleaning simulation complete. Space $statusText: $([Math]::Round($freedBytes / 1MB, 2)) MB"
}

# ── Action 3: Firewall Status ─────────────────────────────────────────────────
function Test-FirewallStatus {
    Write-Host "`n[3] Checking Windows Firewall Status..." -ForegroundColor Yellow
    try {
        $profiles = Get-NetFirewallProfile | Select-Object Name, Enabled
        foreach ($p in $profiles) {
            $statusStr   = if ($p.Enabled) { "ENABLED ✔" } else { "DISABLED ✘" }
            $statusColor = if ($p.Enabled) { "Green" }   else { "Red" }
            Write-Host " -> Profile [$($p.Name)]: " -NoNewline
            Write-Host $statusStr -ForegroundColor $statusColor
            $LogBuffer.Add(" -> Profile [$($p.Name)]: $statusStr")
        }
    } catch { Log " -> Unable to query Firewall (requires elevated privileges)." }
}

# ── Action 4: Network Diagnostics ────────────────────────────────────────────
function Test-NetworkConnectivity {
    Write-Host "`n[4] Running Network Diagnostics..." -ForegroundColor Yellow
    $dnsTest  = Test-Connection -ComputerName google.com -Count 1 -ErrorAction SilentlyContinue
    $pingTest = Test-Connection -ComputerName 8.8.8.8   -Count 2 -ErrorAction SilentlyContinue

    $dnsResult  = if ($dnsTest)  { "SUCCESS ✔" } else { "FAILED ✘" }
    $pingResult = if ($pingTest) {
        $avg = ($pingTest | Measure-Object -Property ResponseTime -Average).Average
        "SUCCESS ✔  (Avg: $avg ms)"
    } else { "FAILED ✘" }

    $dnsColor  = if ($dnsTest)  { "Green" } else { "Red" }
    $pingColor = if ($pingTest) { "Green" } else { "Red" }
    Write-Host " -> DNS Resolution (google.com):  " -NoNewline; Write-Host $dnsResult  -ForegroundColor $dnsColor
    Write-Host " -> Ping 8.8.8.8 (Google):        " -NoNewline; Write-Host $pingResult -ForegroundColor $pingColor
    $LogBuffer.Add(" -> DNS: $dnsResult | Ping: $pingResult")
}

# ── Action 5: List Installed Software ────────────────────────────────────────
function Show-InstalledSoftware {
    Write-Host "`n[5] Listing Installed Applications via Winget..." -ForegroundColor Yellow
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget list | Select-Object -First 20
    } else {
        Log " -> Winget not found. Please install from Microsoft Store."
    }
}

# ── Action 6: Auto Software Installer ────────────────────────────────────────
function Install-CommonSoftware {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host " -> Winget not found. Cannot proceed with auto-install." -ForegroundColor Red
        return
    }
    Write-Host "`n[6] Auto Software Installer (Winget)" -ForegroundColor Yellow
    Write-Host "     Select software to install (comma-separated numbers, e.g. 1,3,5):" -ForegroundColor Cyan

    $catalog = @(
        @{ id="Google.Chrome";          name="Google Chrome" },
        @{ id="Microsoft.VisualStudioCode"; name="VS Code" },
        @{ id="Git.Git";               name="Git" },
        @{ id="Python.Python.3.12";    name="Python 3.12" },
        @{ id="7zip.7zip";             name="7-Zip" },
        @{ id="Notepad++.Notepad++";   name="Notepad++" },
        @{ id="Discord.Discord";       name="Discord" },
        @{ id="VideoLAN.VLC";          name="VLC Media Player" }
    )

    for ($i = 0; $i -lt $catalog.Count; $i++) {
        Write-Host "   [$($i+1)] $($catalog[$i].name)" -ForegroundColor White
    }
    Write-Host "   [0] Cancel" -ForegroundColor DarkGray

    $input = Read-Host "`n   Your choice"
    if ($input -eq "0" -or $input -eq "") { return }

    $choices = $input -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "^\d+$" }
    foreach ($choice in $choices) {
        $idx = [int]$choice - 1
        if ($idx -ge 0 -and $idx -lt $catalog.Count) {
            $pkg = $catalog[$idx]
            if (-not $DryRun) {
                Write-Host "`n   -> Installing $($pkg.name)..." -ForegroundColor Cyan
                winget install --id $pkg.id --silent --accept-source-agreements --accept-package-agreements
                Log "   -> Installed: $($pkg.name) [$($pkg.id)]"
            } else {
                Write-Host "`n   -> [Dry-run] Would install $($pkg.name) [$($pkg.id)]..." -ForegroundColor Green
                Log "   -> [Dry-run] Simulated installation of $($pkg.name)"
            }
        }
    }
}

# ── Action 7: Save Report ─────────────────────────────────────────────────────
function Save-Report {
    $LogBuffer | Set-Content -Path $LogFile -Encoding UTF8
    Write-Host "`n   -> Report saved to: $LogFile" -ForegroundColor Green
}

# ── Main Menu Loop ────────────────────────────────────────────────────────────
do {
    Write-Header
    Write-Host "  Select an action:" -ForegroundColor Cyan
    Write-Host ""
    Write-MenuOption "1" "System Information & Diagnostics"
    Write-MenuOption "2" "Clean Temporary Files"
    Write-MenuOption "3" "Check Windows Firewall Status"
    Write-MenuOption "4" "Network Connectivity Test"
    Write-MenuOption "5" "List Installed Software (Winget)"
    Write-MenuOption "6" "Auto Install Common Software"
    Write-MenuOption "7" "Save Diagnostic Report to File"
    Write-MenuOption "A" "Run All Diagnostics (1-5)"
    Write-MenuOption "0" "Exit"
    Write-Host ""

    $choice = Read-Host "  Enter your choice"

    switch ($choice.ToUpper()) {
        "1" { Show-SystemInfo;        Read-Host "`n  Press Enter to continue" }
        "2" { Clean-TempFiles;        Read-Host "`n  Press Enter to continue" }
        "3" { Test-FirewallStatus;    Read-Host "`n  Press Enter to continue" }
        "4" { Test-NetworkConnectivity; Read-Host "`n  Press Enter to continue" }
        "5" { Show-InstalledSoftware; Read-Host "`n  Press Enter to continue" }
        "6" { Install-CommonSoftware; Read-Host "`n  Press Enter to continue" }
        "7" { Save-Report;            Read-Host "`n  Press Enter to continue" }
        "A" {
            Show-SystemInfo
            Clean-TempFiles
            Test-FirewallStatus
            Test-NetworkConnectivity
            Show-InstalledSoftware
            Read-Host "`n  All tasks complete. Press Enter to continue"
        }
        "0" {
            Write-Host "`n  Goodbye! Stay optimized. 🚀" -ForegroundColor Green
        }
        default {
            Write-Host "`n  Invalid option. Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($choice.ToUpper() -ne "0")
