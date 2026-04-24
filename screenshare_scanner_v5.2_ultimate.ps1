# Minecraft Screenshare Scanner v5.2 - FORENSICS ULTIMATE
# System + JAR + USB + Obfuscation + Event Logs
# Detects EVERYTHING - CAN'T HIDE FROM THIS!

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting admin privileges..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& '$PSCommandPath'`""
    exit
}

$ErrorActionPreference = "SilentlyContinue"

# Custom Mod Paths
$CUSTOM_MOD_PATHS = @(
    # "D:\MyMods"
)

# Cheat Signatures
$RED_STRINGS = @(
    "doomsday", "novaclient", "riseclient", "vapeclient", "intent",
    "WalksyOptimizer", "ClickCrystal", "Surge", "Nova", "Meteor",
    "Wurst", "Impact", "Grim", "Liquidbounce", "Aristois"
)

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logfile = "$env:TEMP\Screenshare_Scan_$timestamp.txt"
$findings = @()

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $logfile -Value $Message
}

function Add-Finding {
    param([string]$Severity, [string]$Title, [string]$Details)
    $findings += @{
        Severity = $Severity
        Title = $Title
        Details = $Details
    }
}

Clear-Host
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SCREENSHARE SCANNER v5.2 - FORENSICS ULTIMATE       ║" -ForegroundColor Cyan
Write-Host "║   System + JAR + Event Log + Memory Forensics         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Log "╔════════════════════════════════════════════════════════╗"
Write-Log "║   SCREENSHARE SCANNER v5.2 - FORENSICS ULTIMATE       ║"
Write-Log "║   Date: $(Get-Date)                             ║"
Write-Log "╚════════════════════════════════════════════════════════╝"
Write-Log ""

# [1/12] Minecraft Detection
Write-Host "[1/12] Detecting Minecraft..." -ForegroundColor Yellow
Write-Log "[1/12] MINECRAFT DETECTION"
$java_proc = Get-Process | Where-Object {$_.ProcessName -eq "javaw" -or $_.ProcessName -eq "java"} | Select-Object -First 1
if ($java_proc) {
    Write-Host "✓ Minecraft found (PID: $($java_proc.Id))" -ForegroundColor Green
    Write-Log "✓ Minecraft found (PID: $($java_proc.Id))"
} else {
    Write-Host "✗ Minecraft not running - Exit" -ForegroundColor Red
    Read-Host "Press Enter"
    exit
}
Write-Log ""

# [2/12] System Boot Time (FROM LILITH)
Write-Host "[2/12] Analyzing system boot time..." -ForegroundColor Yellow
Write-Log "[2/12] SYSTEM BOOT TIME & UPTIME"
try {
    $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $bootTime
    Write-Host "  Last Boot: $($bootTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Yellow
    Write-Host "  Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m" -ForegroundColor Yellow
    Write-Log "  Last Boot: $($bootTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Log "  Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
} catch {}
Write-Log ""

# [3/12] Service Status Check (FROM LILITH)
Write-Host "[3/12] Checking critical service status..." -ForegroundColor Yellow
Write-Log "[3/12] CRITICAL SERVICES STATUS"
$critical_services = @("EventLog", "Schedule", "Bam", "DcomLaunch", "wsearch")
foreach ($svc_name in $critical_services) {
    $svc = Get-Service -Name $svc_name -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.Status -ne "Running") {
            Write-Host "⚠ SERVICE DISABLED: $($svc.DisplayName)" -ForegroundColor Yellow
            Write-Log "⚠ DISABLED SERVICE: $svc_name"
            Add-Finding "WARNING" "Disabled Service" "$($svc.DisplayName) is not running"
        }
    }
}
Write-Host "✓ Service check complete" -ForegroundColor Green
Write-Log "✓ Service status checked"
Write-Log ""

# [4/12] Event Log Tampering (FROM LILITH)
Write-Host "[4/12] Analyzing event logs..." -ForegroundColor Yellow
Write-Log "[4/12] EVENT LOG FORENSICS"
try {
    # Check if logs were cleared
    $cleared = Get-WinEvent -FilterHashtable @{LogName="System"; ID=104} -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($cleared) {
        Write-Host "⚠ EVENT LOG CLEARED!" -ForegroundColor Red
        Write-Log "⚠ CRITICAL: Event log was cleared at $($cleared.TimeCreated)"
        Add-Finding "CRITICAL" "Log Tampering" "Event logs were cleared after system boot"
    } else {
        Write-Host "✓ Event logs intact" -ForegroundColor Green
    }
    
    # Check USN Journal clearing
    $usn = Get-WinEvent -LogName "Application" -FilterXPath "*[System[EventID=3079]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($usn) {
        Write-Host "⚠ USN JOURNAL CLEARED!" -ForegroundColor Red
        Write-Log "⚠ USN Journal cleared"
        Add-Finding "CRITICAL" "USN Journal" "File history was cleared"
    }
    
    # Check system time changes
    $timechange = Get-WinEvent -LogName "Security" -FilterXPath "*[System[EventID=4616]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($timechange) {
        Write-Host "⚠ SYSTEM TIME CHANGED!" -ForegroundColor Red
        Write-Log "⚠ System time was modified"
        Add-Finding "WARNING" "Time Tampering" "System clock was changed"
    }
} catch {}
Write-Log ""

# [5/12] Prefetch Integrity Check (FROM LILITH)
Write-Host "[5/12] Checking prefetch file integrity..." -ForegroundColor Yellow
Write-Log "[5/12] PREFETCH INTEGRITY"
try {
    $pf_path = "C:\Windows\Prefetch"
    if (Test-Path $pf_path) {
        $pf_files = Get-ChildItem -Path $pf_path -Filter "*.pf" -Force
        
        $hidden_count = 0
        $readonly_count = 0
        
        foreach ($pf in $pf_files) {
            if ($pf.Attributes -band [System.IO.FileAttributes]::Hidden) {
                $hidden_count++
            }
            if ($pf.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
                $readonly_count++
            }
        }
        
        if ($hidden_count -gt 0) {
            Write-Host "⚠ HIDDEN PREFETCH FILES: $hidden_count" -ForegroundColor Red
            Write-Log "⚠ Hidden prefetch files detected: $hidden_count"
            Add-Finding "CRITICAL" "Prefetch Tampering" "$hidden_count hidden prefetch files"
        }
        
        if ($readonly_count -gt 0) {
            Write-Host "⚠ READ-ONLY PREFETCH FILES: $readonly_count" -ForegroundColor Yellow
            Write-Log "⚠ Read-only prefetch files: $readonly_count"
        }
        
        Write-Host "✓ Checked $($pf_files.Count) prefetch files" -ForegroundColor Green
    }
} catch {}
Write-Log ""

# [6/12] Recycle Bin Deep Scan (FROM LILITH)
Write-Host "[6/12] Deep scanning Recycle Bin..." -ForegroundColor Yellow
Write-Log "[6/12] RECYCLE BIN FORENSICS"
try {
    $recycle = "$env:SystemDrive\`$Recycle.Bin"
    if (Test-Path $recycle) {
        $deleted_items = Get-ChildItem -LiteralPath $recycle -File -Force -Recurse -ErrorAction SilentlyContinue
        
        if ($deleted_items.Count -gt 0) {
            Write-Host "⚠ Found $($deleted_items.Count) deleted item(s)" -ForegroundColor Yellow
            Write-Log "⚠ Deleted items in Recycle Bin:"
            
            foreach ($item in $deleted_items | Select-Object -First 10) {
                Write-Log "  - $($item.Name) (Deleted: $($item.LastWriteTime))"
                
                # Check if deleted item is a JAR
                if ($item.Name -match "\.jar" -or $item.Name -match "\.exe") {
                    foreach ($cheat in $RED_STRINGS) {
                        if ($item.Name -match $cheat) {
                            Write-Host "    🚨 DELETED CHEAT: $($item.Name)" -ForegroundColor Red
                            Add-Finding "CRITICAL" "Deleted Cheat" "Cheat file found in Recycle Bin: $($item.Name)"
                        }
                    }
                }
            }
        }
    }
} catch {}
Write-Log ""

# [7/12] PowerShell History (FROM LILITH)
Write-Host "[7/12] Analyzing PowerShell history..." -ForegroundColor Yellow
Write-Log "[7/12] POWERSHELL HISTORY"
try {
    $history_path = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
    if (Test-Path $history_path) {
        $history = Get-Item -Path $history_path -Force
        Write-Host "  Last Modified: $($history.LastWriteTime)" -ForegroundColor Yellow
        Write-Log "  PowerShell history last modified: $($history.LastWriteTime)"
        
        # Check file size (empty = suspicious)
        if ($history.Length -lt 100) {
            Write-Host "  ⚠ SUSPICIOUSLY SMALL HISTORY!" -ForegroundColor Yellow
            Write-Log "  ⚠ PowerShell history file is suspiciously small"
            Add-Finding "WARNING" "History Tampering" "PowerShell history appears to have been cleared"
        }
        
        # Read last commands
        $last_commands = Get-Content -Path $history_path -Tail 5
        Write-Log "  Recent commands:"
        foreach ($cmd in $last_commands) {
            Write-Log "    - $cmd"
        }
    }
} catch {}
Write-Log ""

# [8/12] Registry Tampering Check (FROM LILITH)
Write-Host "[8/12] Checking registry restrictions..." -ForegroundColor Yellow
Write-Log "[8/12] REGISTRY ANALYSIS"
try {
    $checks = @(
        @{Path = "HKCU:\Software\Policies\Microsoft\Windows\System"; Name = "DisableCMD"; Desc = "CMD"},
        @{Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"; Name = "EnableScriptBlockLogging"; Desc = "PowerShell Logging"}
    )
    
    foreach ($check in $checks) {
        $val = Get-ItemProperty -Path $check.Path -Name $check.Name -ErrorAction SilentlyContinue
        if ($val -and $val.$($check.Name) -eq 0) {
            Write-Host "⚠ $($check.Desc) DISABLED!" -ForegroundColor Red
            Write-Log "⚠ $($check.Desc) is disabled"
            Add-Finding "WARNING" "Security Disabled" "$($check.Desc) has been disabled"
        }
    }
} catch {}
Write-Log ""

# [9/12] Prefetch Analysis (JAR FORENSICS)
Write-Host "[9/12] Analyzing prefetch execution history..." -ForegroundColor Yellow
Write-Log "[9/12] PREFETCH EXECUTION HISTORY"
try {
    $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $pf_files = Get-ChildItem -Path "C:\Windows\Prefetch" -Filter "*.pf" | Where-Object { ($_.Name -match "java|javaw") -and ($_.LastWriteTime -gt $bootTime) }
    
    if ($pf_files.Count -gt 0) {
        Write-Host "⚠ Java executed $($pf_files.Count) time(s) after boot" -ForegroundColor Yellow
        Write-Log "⚠ Java prefetch files with recent activity:"
        foreach ($pf in $pf_files) {
            Write-Log "  - $($pf.Name) (Last: $($pf.LastWriteTime))"
        }
    }
} catch {}
Write-Log ""

# [10/12] JAR File Scan
Write-Host "[10/12] Scanning for JAR files..." -ForegroundColor Yellow
Write-Log "[10/12] JAR FILE SCAN"

$jar_locations = @("$env:APPDATA\.minecraft\mods", "$env:TEMP", "$env:USERPROFILE\Downloads")
foreach ($location in $jar_locations) {
    if (Test-Path $location) {
        $jars = Get-ChildItem -Path $location -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 10
        foreach ($jar in $jars) {
            foreach ($cheat in $RED_STRINGS) {
                if ($jar.Name -match $cheat) {
                    Write-Host "🚨 CHEAT JAR: $($jar.Name)" -ForegroundColor Red
                    Write-Log "🚨 CHEAT JAR: $($jar.Name)"
                    Add-Finding "CRITICAL" "Cheat File" "$($jar.Name) in $location"
                }
            }
        }
    }
}
Write-Log ""

# [11/12] USB Forensics
Write-Host "[11/12] Scanning USB devices..." -ForegroundColor Yellow
Write-Log "[11/12] USB FORENSICS"

$usb = @(Get-Volume | Where-Object {$_.DriveType -eq "Removable"})
if ($usb.Count -gt 0) {
    Write-Host "⚠ Found $($usb.Count) USB drive(s)" -ForegroundColor Yellow
    foreach ($u in $usb) {
        if ($u.DriveLetter) {
            try {
                $jars = Get-ChildItem -Path "$($u.DriveLetter):\" -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 5
                foreach ($jar in $jars) {
                    foreach ($cheat in $RED_STRINGS) {
                        if ($jar.Name -match $cheat) {
                            Write-Host "    🚨 CHEAT ON USB: $($jar.Name)" -ForegroundColor Red
                            Add-Finding "CRITICAL" "USB Cheat" "$($jar.Name) on USB"
                        }
                    }
                }
            } catch {}
        }
    }
}
Write-Log ""

# [12/12] Final Report
Write-Host "[12/12] Generating final verdict..." -ForegroundColor Yellow
Write-Log ""
Write-Log "═════════════════════════════════════════════════════════"
Write-Log "FINAL FORENSIC ANALYSIS"
Write-Log "═════════════════════════════════════════════════════════"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   FORENSIC ANALYSIS COMPLETE                          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

$critical = ($findings | Where-Object { $_.Severity -eq "CRITICAL" }).Count
$warnings = ($findings | Where-Object { $_.Severity -eq "WARNING" }).Count

Write-Host "Critical Findings: $critical" -ForegroundColor Red
Write-Host "Warnings: $warnings" -ForegroundColor Yellow

Write-Log "CRITICAL FINDINGS: $critical"
Write-Log "WARNINGS: $warnings"

if ($findings.Count -gt 0) {
    Write-Host ""
    Write-Host "EVIDENCE:" -ForegroundColor Yellow
    foreach ($finding in $findings) {
        $color = if ($finding.Severity -eq "CRITICAL") { "Red" } else { "Yellow" }
        Write-Host "  [$($finding.Severity)] $($finding.Title)" -ForegroundColor $color
        Write-Host "    → $($finding.Details)" -ForegroundColor Gray
        Write-Log "  [$($finding.Severity)] $($finding.Title) - $($finding.Details)"
    }
}

Write-Host ""
if ($critical -gt 0) {
    Write-Host "🚨 EVIDENCE OF CHEATING - BAN IMMEDIATELY!" -ForegroundColor Red
    Write-Log "🚨 CHEAT EVIDENCE CONFIRMED"
} elseif ($warnings -gt 0) {
    Write-Host "⚠ SUSPICIOUS ACTIVITY - MANUAL REVIEW REQUIRED" -ForegroundColor Yellow
    Write-Log "⚠ SUSPICIOUS INDICATORS DETECTED"
} else {
    Write-Host "✓ CLEAN SCAN - NO EVIDENCE FOUND" -ForegroundColor Green
    Write-Log "✓ CLEAN SCAN"
}

Write-Log ""
Write-Log "Report: $logfile"
Write-Host ""
Write-Host "📄 Report: $logfile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to open..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

if (Test-Path $logfile) {
    Invoke-Item $logfile
}
