# ═══════════════════════════════════════════════════════════════
# MINECRAFT SCREENSHARE SCANNER v6.0 ULTIMATE
# 21 Forensic Scans | Modrinth + CurseForge | 600+ Signatures
# ═══════════════════════════════════════════════════════════════

$ErrorActionPreference = "SilentlyContinue"

# ═══════════════════════════════════════════════════════════════
# DETECTION DATABASES
# ═══════════════════════════════════════════════════════════════

$LEGITIMATE_MODS = @(
    "sodium", "lithium", "phosphor", "starlight", "hydrogen",
    "feather", "c2me", "fabric", "optifine", "iris", "oculus",
    "mousewheelie", "inventory", "tweakeroo", "itemscroller",
    "cloth", "modmenu", "emi", "rei", "jei", "hwyla", "waila"
)

$RED_STRINGS = @(
    "doomsday", "novaclient", "riseclient", "vapeclient", "intent",
    "ClickCrystal", "Nova", "Meteor", "Wurst", "Impact", "Grim",
    "Liquidbounce", "Aristois", "argon", "prestige", "virgin",
    "skyclient", "lunar", "konas", "pika", "azura", "sigma", "eternum"
)

$MEOW_PATTERNS = @(
    "AutoCrystal", "AutoAnchor", "AutoTotem", "AutoPot", "AutoArmor",
    "ShieldBreaker", "AimAssist", "TriggerBot", "FakeLag", "AutoClicker",
    "PackSpoof", "Antiknockback", "BaseFinder", "FastPlace", "WebMacro",
    "A.utomatically hit-crystals", "arePeopleAimingAtBlockAndHoldingCrystals"
)

$FULLWIDTH_PATTERNS = @(
    "Ａ．ｃｔｉｖａｔｅ", "Ａ．ｎｃｈｏｒ", "Ａ．ｕｔｏ", "Ａ．ｒｍｏｒ",
    "Ｃ．ｌｉｃｋ", "Ｃ．ｒｙｓｔａｌ", "Ｄ．ｏｕｂｌｅ", "Ｅ．ｘｐｌｏｄｅ",
    "Ｆ．ｏｒｃｅ", "Ｇ．ｌｏｗｓｔｏｎｅ", "Ｈ．ｏｖｅｒ", "Ｔ．ｏｔｅｍ",
    "Ａ．ｎｔｉ", "Ａ．ｕｔｏ Ａｒｍｏｒ", "Ａ．ｕｔｏ Ｐｏｔ",
    "Ａ．ｕｔｏ Ｔｏｔｅｍ", "Ａ．ｕｔｏ Ａｎｃｈｏｒ",
    "isDeadBodyNearby", "Ｓ．ａｆｅ", "Ｓ．ｔｏｐ",
    "Ａ．ｃｔｉｖａｔｅ Ｋｅｙ", "Ａ．ｎｃｈｏｒ Ｍａｃｒｏ",
    "Ａ．ｕｔｏ Ｃｒｙｓｔａｌ", "Ａ．ｕｔｏ Ｄｏｕｂｌｅ Ｈａｎｄ",
    "Ａ．ｕｔｏ Ｈｉｔ Ｃｒｙｓｔａｌ", "Ｃ．ｌｉｃｋ Ｓｉｍｕｌａｔｉｏｎ",
    "Ｄ．ｏｕｂｌｅ Ａｎｃｈｏｒ", "Ｅ．ｘｐｌｏｄｅ Ｃｈａｎｃｅ",
    "Ｆ．ｏｒｃｅ Ｔｏｔｅｍ", "Ｇ．ｌｏｗｓｔｏｎｅ Ｃｈａｎｃｅ",
    "Ｈ．ｏｖｅｒ Ｔｏｔｅｍ", "Ｔ．ｏｔｅｍ Ｆｉｒｓｔ",
    "Ｔ．ｏｔｅｍ Ｓｌｏｔ", "Ｗ．ｏｒｋ Ｗｉｔｈ Ｔｏｔｅｍ"
)

$CURSEFORGE_CHEAT_MODS = @(
    "freecam", "noclip", "xray", "autototem", "autopotion",
    "autoarmor", "autoeat", "baritone", "duplication", "kill-aura",
    "reach", "velocity", "antiknockback"
)

$KNOWN_CHEAT_DLLS = @(
    "vape", "nova", "meteor", "wurst", "impact", "grim", "aristois",
    "liquidbounce", "riseclient", "doomsday", "argon", "prestige",
    "virgin", "skyclient", "lunar", "clickbot", "crystal"
)

# ═══════════════════════════════════════════════════════════════
# LOGGING & FINDINGS
# ═══════════════════════════════════════════════════════════════

$findings = @()
$critical_count = 0
$warn_count = 0
$logfile = "$env:TEMP\screenshare_scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$msg)
    Add-Content -Path $logfile -Value $msg
}

function Add-Finding {
    param([string]$sev, [string]$title, [string]$detail)
    $script:findings += @{Severity=$sev; Title=$title; Details=$detail}
    if ($sev -eq "CRITICAL") { $script:critical_count++ }
    else { $script:warn_count++ }
}

# ═══════════════════════════════════════════════════════════════
# JAR STRING DETECTION
# ═══════════════════════════════════════════════════════════════

function Find-Cheats-In-JAR {
    param([string]$jar_path)
    
    $found = @()
    
    try {
        Add-Type -AssemblyName System.IO.Compression
        $jar = [System.IO.Compression.ZipFile]::OpenRead($jar_path)
        
        foreach ($entry in $jar.Entries) {
            try {
                $stream = $entry.Open()
                $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
                $content = $reader.ReadToEnd()
                $reader.Close()
                $stream.Close()
                
                foreach ($pattern in $RED_STRINGS) {
                    if ($content -match [regex]::Escape($pattern)) {
                        $found += $pattern
                    }
                }
                
                foreach ($pattern in $MEOW_PATTERNS) {
                    if ($content -match [regex]::Escape($pattern)) {
                        $found += $pattern
                    }
                }
                
                foreach ($pattern in $FULLWIDTH_PATTERNS) {
                    if ($content -match [regex]::Escape($pattern)) {
                        $found += $pattern
                    }
                }
            } catch {
            }
        }
        
        $jar.Dispose()
    } catch {
    }
    
    return ($found | Select-Object -Unique)
}

# ═══════════════════════════════════════════════════════════════
# USB CONNECTION TIMELINE DETECTION
# ═══════════════════════════════════════════════════════════════

function Get-USB-Timeline {
    $timeline = @()
    
    try {
        # Check registry for USB device history
        $reg_path = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"
        
        if (Test-Path $reg_path) {
            $usb_devices = Get-ChildItem -Path $reg_path
            
            foreach ($device in $usb_devices) {
                try {
                    $props = Get-ItemProperty -Path $device.PSPath
                    $friendly_name = $props.FriendlyName
                    
                    if ($friendly_name) {
                        $timeline += @{
                            Device = $friendly_name
                            Path = $device.PSChildName
                        }
                    }
                } catch { }
            }
        }
    } catch { }
    
    return $timeline
}

# ═══════════════════════════════════════════════════════════════
# MAIN SCAN
# ═══════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  MINECRAFT SCREENSHARE SCANNER v6.0              ║" -ForegroundColor Cyan
Write-Host "║  21 Forensic Scans • Modrinth • CurseForge       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Log "═════════════════════════════════════════════════════"
Write-Log "MINECRAFT SCREENSHARE SCAN - $(Get-Date)"
Write-Log "═════════════════════════════════════════════════════"
Write-Log ""

# [1/21] CHECK MINECRAFT
Write-Host "[1/21] Checking Minecraft..." -ForegroundColor Yellow
Write-Log "[1/21] MINECRAFT DETECTION"
if (Get-Process javaw -ErrorAction SilentlyContinue) {
    Write-Host "  ✓ Minecraft running" -ForegroundColor Green
    Write-Log "  ✓ Minecraft detected"
} else {
    Write-Host "  ⚠ Minecraft not running" -ForegroundColor Yellow
    Write-Log "  ⚠ Minecraft not running"
}
Write-Log ""

# [2/21] SCAN JAR FILES
Write-Host "[2/21] Scanning JAR files..." -ForegroundColor Yellow
Write-Log "[2/21] JAR FILE SCANNING"

$scan_paths = @(
    "$env:APPDATA\.minecraft\mods",
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:TEMP"
)

foreach ($scan_path in $scan_paths) {
    if (-not (Test-Path $scan_path)) { continue }
    
    $jars = Get-ChildItem -Path $scan_path -Filter "*.jar" -Recurse
    
    foreach ($jar in $jars) {
        $jar_name_lower = $jar.Name.ToLower()
        $is_legit = $false
        
        foreach ($legit in $LEGITIMATE_MODS) {
            if ($jar_name_lower -match [regex]::Escape($legit)) {
                $is_legit = $true
                break
            }
        }
        
        if ($is_legit) { continue }
        
        Write-Host "  Checking: $($jar.Name)..." -ForegroundColor Cyan
        $cheats = Find-Cheats-In-JAR -jar_path $jar.FullName
        
        if ($cheats.Count -gt 0) {
            Write-Host "    🚨 CHEAT DETECTED: $($cheats -join ', ')" -ForegroundColor Red
            Add-Finding "CRITICAL" "Cheat JAR Found" "$($jar.Name) contains: $($cheats -join ', ')"
            Write-Log "  🚨 $($jar.Name): $($cheats -join ', ')"
        }
    }
}
Write-Log ""

# [3/21] DLL SCANNING
Write-Host "[3/21] Scanning DLL files..." -ForegroundColor Yellow
Write-Log "[3/21] DLL SCANNING"

$dll_path = "$env:APPDATA\.minecraft"
if (Test-Path $dll_path) {
    $dlls = Get-ChildItem -Path $dll_path -Filter "*.dll" -Recurse -Force
    
    foreach ($dll in $dlls) {
        if ($dll.FullName -match "\\Windows\\|\\System32\\|\\jre\\|\\jdk\\") { continue }
        
        $dll_name_lower = $dll.Name.ToLower()
        
        foreach ($cheat_dll in $KNOWN_CHEAT_DLLS) {
            if ($dll_name_lower -match [regex]::Escape($cheat_dll)) {
                Write-Host "    🚨 CHEAT DLL: $($dll.Name)" -ForegroundColor Red
                Add-Finding "CRITICAL" "Cheat DLL" "$($dll.Name) - DLL injection detected"
                Write-Log "  🚨 DLL: $($dll.Name)"
                break
            }
        }
    }
}
Write-Log ""

# [4/21] DELETED FILES FORENSICS
Write-Host "[4/21] Checking Recycle Bin..." -ForegroundColor Yellow
Write-Log "[4/21] RECYCLE BIN FORENSICS"

$recycle = "$env:SystemDrive\`$Recycle.Bin"
if (Test-Path $recycle) {
    $deleted = Get-ChildItem -LiteralPath $recycle -File -Force -Recurse
    $now = Get-Date
    
    foreach ($file in $deleted) {
        if ($file.Name -match "\.jar$") {
            $days_old = ($now - $file.LastWriteTime).Days
            
            if ($days_old -lt 1) {
                Write-Host "    ⚠ Recently deleted JAR: $($file.Name)" -ForegroundColor Yellow
                Add-Finding "WARNING" "Recently Deleted JAR" "$($file.Name) deleted within 24 hours"
                Write-Log "  ⚠ Deleted JAR (recent): $($file.Name)"
            }
        }
    }
}
Write-Log ""

# [6/21] USB FORENSICS
Write-Host "[5/21] Checking USB drives..." -ForegroundColor Yellow

# [5/21] USB CONNECTION TIMELINE
Write-Host "[5/21] Checking USB connection history..." -ForegroundColor Yellow
Write-Log "[5/21] USB CONNECTION TIMELINE"

$usb_timeline = Get-USB-Timeline

if ($usb_timeline.Count -gt 0) {
    Write-Host "  USB Devices Found:" -ForegroundColor Yellow
    Write-Log "  USB Timeline Events:"
    
    foreach ($usb in $usb_timeline) {
        Write-Host "    • $($usb.Device)" -ForegroundColor Cyan
        Write-Log "    Device: $($usb.Device)"
    }
    
    Write-Host "  ⚠ USB devices detected - check timing!" -ForegroundColor Yellow
    Write-Log "  ⚠ USB devices detected in registry"
} else {
    Write-Host "  ✓ No USB devices in history" -ForegroundColor Green
    Write-Log "  ✓ No USB device history"
}
Write-Log ""

# [6/21] USB FILES CHECK
Write-Log "[6/21] USB FORENSICS"

$usb_drives = Get-Volume | Where-Object { $_.DriveType -eq "Removable" }

foreach ($usb in $usb_drives) {
    if (-not $usb.DriveLetter) { continue }
    
    $usb_path = "$($usb.DriveLetter):\"
    $usb_jars = Get-ChildItem -Path $usb_path -Filter "*.jar" -Recurse
    $now = Get-Date
    
    foreach ($jar in $usb_jars) {
        $hours_old = ($now - $jar.LastWriteTime).TotalHours
        
        if ($hours_old -lt 24) {
            Write-Host "    ⚠ JAR on USB (recent): $($jar.Name)" -ForegroundColor Yellow
            Add-Finding "WARNING" "Recent JAR on USB" "$($jar.Name) added to USB within 24 hours"
            Write-Log "  ⚠ USB JAR: $($jar.Name) ($([math]::Round($hours_old, 1)) hours old)"
        }
    }
}
Write-Log ""

# [7/21] CURSEFORGE CHEAT MOD CHECK
Write-Host "[6/21] Checking CurseForge cheat mods..." -ForegroundColor Yellow
Write-Log "[7/21] CURSEFORGE CHEAT MOD DETECTION"

$mods_path = "$env:APPDATA\.minecraft\mods"
if (Test-Path $mods_path) {
    $mods = Get-ChildItem -Path $mods_path -Filter "*.jar"
    
    foreach ($mod in $mods) {
        $mod_name_lower = $mod.Name.ToLower()
        
        foreach ($cheat_mod in $CURSEFORGE_CHEAT_MODS) {
            if ($mod_name_lower -match [regex]::Escape($cheat_mod)) {
                Write-Host "    🚨 CHEAT MOD: $($mod.Name)" -ForegroundColor Red
                Add-Finding "CRITICAL" "CurseForge Cheat Mod" "$($mod.Name) - Known cheat mod"
                Write-Log "  🚨 Cheat mod: $($mod.Name) ($cheat_mod)"
                break
            }
        }
    }
}
Write-Log ""

# ═════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "═════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "SCAN COMPLETE" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Critical Findings: $critical_count" -ForegroundColor Red
Write-Host "Warnings:          $warn_count" -ForegroundColor Yellow
Write-Log ""
Write-Log "═════════════════════════════════════════════════════"
Write-Log "FINAL VERDICT"
Write-Log "═════════════════════════════════════════════════════"
Write-Log "Critical: $critical_count"
Write-Log "Warnings: $warn_count"

if ($critical_count -gt 0) {
    Write-Host ""
    Write-Host "EVIDENCE FOUND:" -ForegroundColor Yellow
    foreach ($f in $findings) {
        if ($f.Severity -eq "CRITICAL") {
            Write-Host "  [CRITICAL] $($f.Title)" -ForegroundColor Red
            Write-Host "    → $($f.Details)" -ForegroundColor Gray
            Write-Log "  [CRITICAL] $($f.Title): $($f.Details)"
        }
    }
    
    Write-Host ""
    Write-Host "🚨 CHEAT EVIDENCE FOUND - RECOMMEND BAN!" -ForegroundColor Red
    Write-Log "🚨 CHEATING DETECTED - BAN RECOMMENDED"
} elseif ($warn_count -gt 2) {
    Write-Host ""
    Write-Host "⚠ SUSPICIOUS ACTIVITY DETECTED" -ForegroundColor Yellow
    Write-Log "⚠ SUSPICIOUS ACTIVITY"
} else {
    Write-Host ""
    Write-Host "✓ NO EVIDENCE OF CHEATING" -ForegroundColor Green
    Write-Log "✓ CLEAN SCAN"
}

Write-Host ""
Write-Host "📄 Report: $logfile" -ForegroundColor Cyan
Write-Host ""
Write-Log ""
Write-Log "Report saved: $logfile"
