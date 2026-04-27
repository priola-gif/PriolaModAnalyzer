#Requires -RunAsAdministrator
# MINECRAFT SCREENSHARE SCANNER v6.0 - GITHUB EDITION
# Remote Execution Ready

$ErrorActionPreference = "SilentlyContinue"

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command {$([scriptblock]::Create((Invoke-RestMethod -Uri $PSCommandPath)))}"
    exit
}

Clear-Host
Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  MINECRAFT SCREENSHARE SCANNER v6.0             ║" -ForegroundColor Cyan
Write-Host "║  GitHub Edition - Complete Forensics            ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

$paths = @("$env:APPDATA\.minecraft\mods")
Write-Host "Default Path: $($paths[0])" -ForegroundColor Green
$add = Read-Host "Add custom paths? (y/n)"

if ($add -eq "y") {
    Write-Host "`nEnter paths (Enter twice to finish):" -ForegroundColor Yellow
    while ($true) {
        $p = Read-Host "Path"
        if ([string]::IsNullOrWhiteSpace($p)) { break }
        if (Test-Path $p) { $paths += $p; Write-Host "  ✓ Added" -ForegroundColor Green }
        else { Write-Host "  ✗ Not found" -ForegroundColor Red }
    }
}

Write-Host "`n═════════════════════════════════════════════════════"
$paths | ForEach-Object { Write-Host "  • $_" -ForegroundColor Green }
Write-Host "═════════════════════════════════════════════════════`n"

$ok = Read-Host "Ready to scan? (y/n)"
if ($ok -ne "y") { Write-Host "Cancelled" -ForegroundColor Yellow; exit }

$CHEATS = @("doomsday", "novaclient", "riseclient", "vapeclient", "intent", "ClickCrystal", "Nova", "Meteor", "Wurst", "Impact", "Grim", "Liquidbounce", "Aristois", "argon", "prestige", "virgin", "skyclient", "lunar", "konas", "pika", "azura", "sigma")
$FEATURES = @("AutoCrystal", "AutoAnchor", "AutoTotem", "AutoPot", "AutoArmor", "ShieldBreaker", "TriggerBot", "FakeLag", "AutoClicker", "Antiknockback", "BaseFinder", "FastPlace", "Freecam", "NoClip", "NoFall", "KeyPearl", "CrystalAura", "AnchorAura", "PacketFly", "AntiKB")
$LEGIT = @("sodium", "lithium", "fabric", "optifine", "iris", "jei", "rei", "modmenu")

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$logfile = "$env:TEMP\Screenshare_$ts.txt"
$findings = @()
$crit = 0; $warn = 0

function Log($m) { Add-Content $logfile $m }
function Add-Finding($s, $t, $d) {
    $script:findings += @{Severity=$s; Title=$t; Details=$d}
    if ($s -eq "CRITICAL") { $script:crit++ } else { $script:warn++ }
}

Log "═══════════════════════════════════════════"; Log "SCAN: $(Get-Date)"; Log "═══════════════════════════════════════════"; Log ""

function Scan-JAR($j) {
    $r = @()
    try {
        Add-Type -AssemblyName System.IO.Compression
        $z = [System.IO.Compression.ZipFile]::OpenRead($j)
        foreach ($e in $z.Entries) {
            try {
                $s = $e.Open()
                $rd = New-Object System.IO.StreamReader($s, [System.Text.Encoding]::UTF8)
                $c = $rd.ReadToEnd(); $rd.Close(); $s.Close()
                foreach ($p in ($CHEATS + $FEATURES)) { if ($c -match [regex]::Escape($p)) { $r += $p } }
            } catch { }
        }
        $z.Dispose()
    } catch { }
    return ($r | Select-Object -Unique)
}

Write-Host "[1/8] Minecraft..." -ForegroundColor Yellow
if (Get-Process javaw -ErrorAction SilentlyContinue) { Write-Host "  ✓ Running" -ForegroundColor Green }
else { Write-Host "  ⚠ Not running" -ForegroundColor Yellow }
Log ""

Write-Host "[2/8] JAR files..." -ForegroundColor Yellow
Log "[2/8] JAR SCANNING"
$total = 0
foreach ($path in $paths) {
    if (-not (Test-Path $path)) { continue }
    Get-ChildItem $path -Filter "*.jar" -Recurse -Force | ForEach-Object {
        $total++
        $skip = $false
        foreach ($l in $LEGIT) { if ($_.Name.ToLower() -match [regex]::Escape($l)) { $skip = $true; break } }
        if ($skip) { return }
        $c = Scan-JAR $_.FullName
        if ($c.Count -gt 0) {
            Write-Host "  🚨 [$total] $($_.Name): $($c -join ',')" -ForegroundColor Red
            Add-Finding "CRITICAL" "Cheat JAR" $_.Name
            Log "  🚨 $($_.Name): $($c -join ',')"
        }
    }
}
Log ""

Write-Host "[3/8] USB drives..." -ForegroundColor Yellow
Log "[3/8] USB SCAN"
Get-Volume | Where-Object { $_.DriveType -eq "Removable" } | ForEach-Object {
    if ($_.DriveLetter) {
        Get-ChildItem "$($_.DriveLetter):\" -Filter "*.jar" -Recurse -Force | ForEach-Object {
            $c = Scan-JAR $_.FullName
            if ($c.Count -gt 0) {
                Write-Host "  🚨 USB: $($_.Name)" -ForegroundColor Red
                Add-Finding "CRITICAL" "USB Cheat" $_.Name
                Log "  🚨 USB: $($_.Name)"
            }
        }
    }
}
Log ""

Write-Host "[4/8] PowerShell history..." -ForegroundColor Yellow
Log "[4/8] PS HISTORY"
$hist = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
if (Test-Path $hist) {
    Get-Content $hist | Where-Object { $_ -match "Invoke-WebRequest.*cheat|Move-Item.*USB|Copy-Item.*USB|Remove-Item.*minecraft" } | ForEach-Object {
        Write-Host "  ⚠ Command: $($_.Substring(0, [Math]::Min(50, $_.Length)))" -ForegroundColor Yellow
        Add-Finding "WARNING" "PS History" "Suspicious command"
        Log "  ⚠ $_"
    }
}
Log ""

Write-Host "[5/8] Registry..." -ForegroundColor Yellow
Log "[5/8] REGISTRY"
try {
    Get-ChildItem "HKCU:\Software\" -Force | ForEach-Object {
        $n = $_.PSChildName.ToLower()
        foreach ($ch in $CHEATS) {
            if ($n -match [regex]::Escape($ch)) {
                $m = (Get-Item $_.PSPath -Force).LastWriteTime
                $a = ((Get-Date) - $m).Days
                Write-Host "  🚨 Registry: $($_.PSChildName) (Age: $a days)" -ForegroundColor Red
                Add-Finding "CRITICAL" "Registry Config" "$($_.PSChildName) ($a days old)"
                Log "  🚨 $($_.PSChildName) - $m"
                break
            }
        }
    }
} catch { }
Log ""

Write-Host "[6/8] Launcher profiles..." -ForegroundColor Yellow
Log "[6/8] LAUNCHER"
try {
    $lf = "$env:APPDATA\.minecraft\launcher_profiles.json"
    if (Test-Path $lf) {
        $j = Get-Content $lf -Raw | ConvertFrom-Json
        $pc = $j.profiles.PSObject.Properties.Count
        Write-Host "  Profiles: $pc" -ForegroundColor Cyan
        Log "  Profiles: $pc"
        if ($pc -gt 5) { Add-Finding "WARNING" "Launcher" "Unusual profile count" }
    }
} catch { }
Log ""

Write-Host "[7/8] USB timeline..." -ForegroundColor Yellow
Log "[7/8] USB TIMELINE"
try {
    $ud = @(Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR\" -Force).Count
    Write-Host "  USB devices: $ud" -ForegroundColor Cyan
    Log "  USB devices: $ud"
} catch { }
Log ""

Write-Host "[8/8] Recycle Bin..." -ForegroundColor Yellow
Log "[8/8] RECYCLE BIN"
try {
    Get-ChildItem -LiteralPath "$env:SystemDrive\`$Recycle.Bin" -File -Force -Recurse | Where-Object { $_.Name -match "\.jar" } | ForEach-Object {
        if ((Get-Date).Subtract($_.LastWriteTime).Days -lt 1) {
            Write-Host "  ⚠ Deleted: $($_.Name)" -ForegroundColor Yellow
            Add-Finding "WARNING" "Deleted JAR" $_.Name
            Log "  ⚠ $_"
        }
    }
} catch { }
Log ""

Write-Host "`n═════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "COMPLETE" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════════════════`n" -ForegroundColor Cyan

Write-Host "JARs scanned: $total" -ForegroundColor Yellow
Write-Host "Critical: $crit" -ForegroundColor Red
Write-Host "Warnings: $warn" -ForegroundColor Yellow
Write-Host ""

if ($crit -gt 0) {
    Write-Host "🚨 CHEAT FOUND - BAN RECOMMENDED!" -ForegroundColor Red
    $findings | Where-Object { $_.Severity -eq "CRITICAL" } | ForEach-Object {
        Write-Host "  [$($_.Title)] $($_.Details)" -ForegroundColor Red
    }
    Log "🚨 BAN RECOMMENDED"
} else {
    Write-Host "✓ CLEAN SCAN" -ForegroundColor Green
    Log "✓ CLEAN SCAN"
}

Write-Host ""
Write-Host "Report: $logfile" -ForegroundColor Cyan
Write-Host ""

Log ""; Log "═══════════════════════════════════════════"; Log "END SCAN"

Start-Process notepad $logfile
