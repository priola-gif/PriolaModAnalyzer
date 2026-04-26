# ═══════════════════════════════════════════════════════════════
# MINECRAFT SCREENSHARE SCANNER v6.0 - DEEP JAR SCANNING
# Scans EVERY JAR in USB + Mods | No file limits | Complete inspection
# ═══════════════════════════════════════════════════════════════

$ErrorActionPreference = "SilentlyContinue"

# ═══════════════════════════════════════════════════════════════
# DETECTION DATABASES
# ═══════════════════════════════════════════════════════════════

$LEGITIMATE_MODS = @(
    "sodium", "lithium", "phosphor", "starlight", "hydrogen",
    "feather", "c2me", "fabric", "optifine", "iris", "oculus",
    "mousewheelie", "inventory", "tweakeroo", "itemscroller"
)

$RED_STRINGS = @(
    "doomsday", "novaclient", "riseclient", "vapeclient", "intent",
    "ClickCrystal", "Nova", "Meteor", "Wurst", "Impact", "Grim",
    "Liquidbounce", "Aristois", "argon", "prestige", "virgin",
    "skyclient", "lunar", "konas", "pika", "azura", "sigma"
)

$MEOW_PATTERNS = @(
    "AutoCrystal", "AutoAnchor", "AutoTotem", "AutoPot", "AutoArmor",
    "ShieldBreaker", "AimAssist", "TriggerBot", "FakeLag", "AutoClicker",
    "PackSpoof", "Antiknockback", "BaseFinder", "FastPlace", "WebMacro",
    "A.utomatically hit-crystals", "arePeopleAimingAtBlockAndHoldingCrystals",
    "nearbyCrystals", "TriggerListenerMap", "CallbackInjector"
)

$FULLWIDTH_PATTERNS = @(
    "Ａ．ｃｔｉｖａｔｅ", "Ａ．ｎｃｈｏｒ", "Ａ．ｕｔｏ", "Ａ．ｒｍｏｒ",
    "Ｃ．ｌｉｃｋ", "Ｃ．ｒｙｓｔａｌ", "Ｄ．ｏｕｂｌｅ", "Ｅ．ｘｐｌｏｄｅ",
    "Ｆ．ｏｒｃｅ", "Ｈ．ｏｖｅｒ", "Ｔ．ｏｔｅｍ", "Ａ．ｎｔｉ",
    "Ａ．ｃｔｉｖａｔｅ Ｋｅｙ", "Ａ．ｎｃｈｏｒ Ｍａｃｒｏ"
)

$CURSEFORGE_CHEAT_MODS = @(
    "freecam", "noclip", "xray", "autototem", "autopotion",
    "autoarmor", "autoeat", "baritone", "duplication", "kill-aura"
)

# ═══════════════════════════════════════════════════════════════
# LOGGING & FINDINGS
# ═══════════════════════════════════════════════════════════════

$findings = @()
$critical_count = 0
$warn_count = 0
$total_jars_scanned = 0
$logfile = "$env:TEMP\screenshare_scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$custom_mod_paths = @()

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
# DEEP JAR SCANNING - COMPLETE FILE INSPECTION
# ═══════════════════════════════════════════════════════════════

function Scan-JAR-Deeply {
    param([string]$jar_path)
    
    $results = @{
        Found = @()
        Details = ""
    }
    
    try {
        Add-Type -AssemblyName System.IO.Compression
        $jar = [System.IO.Compression.ZipFile]::OpenRead($jar_path)
        
        # SCAN EVERY ENTRY IN JAR - NO LIMITS
        foreach ($entry in $jar.Entries) {
            try {
                # Read all files as text
                $stream = $entry.Open()
                $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
                $content = $reader.ReadToEnd()
                $reader.Close()
                $stream.Close()
                
                # Check all patterns
                foreach ($pattern in $RED_STRINGS) {
                    if ($content -match [regex]::Escape($pattern)) {
                        $results.Found += "$pattern (in $($entry.Name))"
                    }
                }
                
                foreach ($pattern in $MEOW_PATTERNS) {
                    if ($content -match [regex]::Escape($pattern)) {
                        $results.Found += "$pattern (in $($entry.Name))"
                    }
                }
                
                foreach ($pattern in $FULLWIDTH_PATTERNS) {
                    if ($content -match [regex]::Escape($pattern)) {
                        $results.Found += "$pattern (in $($entry.Name))"
                    }
                }
            } catch { }
        }
        
        $jar.Dispose()
        
        $results.Found = $results.Found | Select-Object -Unique
        
    } catch {
        $results.Details = "Error reading JAR"
    }
    
    return $results
}

# ═══════════════════════════════════════════════════════════════
# MODRINTH HASH VERIFICATION
# ═══════════════════════════════════════════════════════════════

function Check-Modrinth-Hash {
    param([string]$jar_path, [string]$mod_name)
    
    $result = @{ Tampered = $false; Details = "" }
    
    try {
        $jar_hash = (Get-FileHash -Path $jar_path -Algorithm SHA256).Hash
        $search = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/search?query=$([System.Web.HttpUtility]::UrlEncode($mod_name))&limit=1"
        
        if ($search.hits.Count -gt 0) {
            $mod = $search.hits[0]
            $versions = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/project/$($mod.project_id)/versions"
            
            foreach ($ver in $versions) {
                if ($ver.files.Count -gt 0) {
                    $file = $ver.files[0]
                    $official_hash = $file.hashes.sha256
                    
                    if ($official_hash -and $jar_hash -ne $official_hash) {
                        $result.Tampered = $true
                        $result.Details = "Hash mismatch (SHA256)"
                    } else {
                        $result.Details = "Verified"
                    }
                    break
                }
            }
        }
    } catch { }
    
    return $result
}

# ═══════════════════════════════════════════════════════════════
# USB TIMELINE
# ═══════════════════════════════════════════════════════════════

function Get-USB-History {
    $timeline = @()
    try {
        $reg = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR" -ErrorAction SilentlyContinue
        foreach ($device in $reg) {
            $props = Get-ItemProperty -Path $device.PSPath
            if ($props.FriendlyName) {
                $timeline += $props.FriendlyName
            }
        }
    } catch { }
    return $timeline
}

# ═══════════════════════════════════════════════════════════════
# MAIN SCAN
# ═══════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "╔═════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  MINECRAFT SCREENSHARE SCANNER v6.0               ║" -ForegroundColor Cyan
Write-Host "║  Deep JAR Scanning | Every File | No Limits       ║" -ForegroundColor Cyan
Write-Host "╚═════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# CUSTOM PATHS
Write-Host "Add custom mod folder paths? (y/n): " -ForegroundColor Yellow -NoNewline
$response = Read-Host

if ($response -eq "y") {
    do {
        $path = Read-Host "Enter path"
        if (Test-Path $path) {
            $custom_mod_paths += $path
            Write-Host "  ✓ Added: $path" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Not found" -ForegroundColor Red
        }
        $response = Read-Host "Add another? (y/n)"
    } while ($response -eq "y")
}

Write-Log "═════════════════════════════════════════════════════"
Write-Log "DEEP JAR SCAN: $(Get-Date)"
Write-Log "═════════════════════════════════════════════════════"

# [1] MINECRAFT
Write-Host "[1/5] Checking Minecraft..." -ForegroundColor Yellow
if (Get-Process javaw -ErrorAction SilentlyContinue) {
    Write-Host "  ✓ Running" -ForegroundColor Green
}

# [2] DEEP SCAN MODS FOLDER
Write-Host "[2/5] Deep scanning MODS FOLDER (ALL JARs)..." -ForegroundColor Yellow
Write-Log "[2/5] MODS FOLDER DEEP SCAN"

$mods_path = "$env:APPDATA\.minecraft\mods"
if (Test-Path $mods_path) {
    # GET ALL JARS - NO LIMITS
    $all_jars = Get-ChildItem -Path $mods_path -Filter "*.jar" -Recurse -Force
    Write-Log "  Total JARs found in mods: $($all_jars.Count)"
    
    foreach ($jar in $all_jars) {
        $script:total_jars_scanned++
        $jar_name_lower = $jar.Name.ToLower()
        
        # Skip legitimate mods
        $skip = $false
        foreach ($legit in $LEGITIMATE_MODS) {
            if ($jar_name_lower -match [regex]::Escape($legit)) {
                $skip = $true
                break
            }
        }
        if ($skip) { continue }
        
        Write-Host "  [$script:total_jars_scanned] Scanning: $($jar.Name)..." -ForegroundColor Cyan
        Write-Log "  [$script:total_jars_scanned] $($jar.Name)"
        
        # DEEP SCAN
        $scan = Scan-JAR-Deeply -jar_path $jar.FullName
        
        if ($scan.Found.Count -gt 0) {
            Write-Host "    🚨 CHEAT FOUND!" -ForegroundColor Red
            foreach ($finding in $scan.Found) {
                Write-Host "      → $finding" -ForegroundColor Red
                Write-Log "      🚨 $finding"
            }
            Add-Finding "CRITICAL" "Cheat in $($jar.Name)" "$($scan.Found -join ' | ')"
        }
        
        # Hash check
        $hash = Check-Modrinth-Hash -jar_path $jar.FullName -mod_name ($jar.Name -replace '\.jar$', '')
        if ($hash.Tampered) {
            Write-Host "    🚨 TAMPERED: $($hash.Details)" -ForegroundColor Red
            Add-Finding "CRITICAL" "Tampered $($jar.Name)" "$($hash.Details)"
            Write-Log "      🚨 TAMPERED: $($hash.Details)"
        }
    }
} else {
    Write-Host "  ⚠ Mods folder not found" -ForegroundColor Yellow
}
Write-Log ""

# [3] CUSTOM PATHS
if ($custom_mod_paths.Count -gt 0) {
    Write-Host "[3/5] Deep scanning CUSTOM PATHS..." -ForegroundColor Yellow
    Write-Log "[3/5] CUSTOM PATHS"
    
    foreach ($custom_path in $custom_mod_paths) {
        Write-Host "  Scanning: $custom_path" -ForegroundColor Cyan
        Write-Log "  Scanning: $custom_path"
        
        $all_jars = Get-ChildItem -Path $custom_path -Filter "*.jar" -Recurse -Force
        Write-Log "  Total JARs: $($all_jars.Count)"
        
        foreach ($jar in $all_jars) {
            $script:total_jars_scanned++
            $jar_name_lower = $jar.Name.ToLower()
            
            $skip = $false
            foreach ($legit in $LEGITIMATE_MODS) {
                if ($jar_name_lower -match [regex]::Escape($legit)) {
                    $skip = $true
                    break
                }
            }
            if ($skip) { continue }
            
            Write-Host "    [$script:total_jars_scanned] $($jar.Name)..." -ForegroundColor Cyan
            
            $scan = Scan-JAR-Deeply -jar_path $jar.FullName
            if ($scan.Found.Count -gt 0) {
                Write-Host "      🚨 CHEAT: $($scan.Found -join ', ')" -ForegroundColor Red
                Add-Finding "CRITICAL" "Cheat in $($jar.Name)" "$($scan.Found -join ' | ')"
                Write-Log "    🚨 $($jar.Name): $($scan.Found -join ' | ')"
            }
        }
    }
    Write-Log ""
}

# [4] USB DRIVES
Write-Host "[4/5] Deep scanning USB DRIVES (ALL JARs)..." -ForegroundColor Yellow
Write-Log "[4/5] USB DRIVES DEEP SCAN"

$usb_drives = Get-Volume | Where-Object { $_.DriveType -eq "Removable" }
$usb_count = 0

foreach ($usb in $usb_drives) {
    if (-not $usb.DriveLetter) { continue }
    
    $usb_path = "$($usb.DriveLetter):\"
    Write-Host "  USB: $($usb.FileSystemLabel) ($usb_path)" -ForegroundColor Yellow
    Write-Log "  USB: $($usb.FileSystemLabel)"
    
    # GET ALL JARS ON USB - NO LIMITS
    $all_usb_jars = Get-ChildItem -Path $usb_path -Filter "*.jar" -Recurse -Force
    Write-Host "    Found $($all_usb_jars.Count) JAR files" -ForegroundColor Yellow
    Write-Log "    Total JARs: $($all_usb_jars.Count)"
    
    foreach ($jar in $all_usb_jars) {
        $script:total_jars_scanned++
        $usb_count++
        $jar_name_lower = $jar.Name.ToLower()
        
        Write-Host "    [$usb_count] Deep scanning: $($jar.Name)..." -ForegroundColor Cyan
        Write-Log "    [$usb_count] $($jar.Name)"
        
        # DEEP SCAN
        $scan = Scan-JAR-Deeply -jar_path $jar.FullName
        
        if ($scan.Found.Count -gt 0) {
            Write-Host "      🚨 CHEAT FOUND ON USB!" -ForegroundColor Red
            foreach ($finding in $scan.Found) {
                Write-Host "        → $finding" -ForegroundColor Red
                Write-Log "      🚨 $finding"
            }
            Add-Finding "CRITICAL" "USB Cheat: $($jar.Name)" "$($scan.Found -join ' | ')"
        }
    }
}
Write-Log ""

# [5] USB TIMELINE
Write-Host "[5/5] USB Timeline..." -ForegroundColor Yellow
Write-Log "[5/5] USB TIMELINE"

$usb_history = Get-USB-History
if ($usb_history.Count -gt 0) {
    Write-Host "  USB devices connected:" -ForegroundColor Yellow
    foreach ($device in $usb_history) {
        Write-Host "    • $device" -ForegroundColor Cyan
        Write-Log "  Device: $device"
    }
}
Write-Log ""

# FINAL REPORT
Write-Host ""
Write-Host "═════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "SCAN COMPLETE" -ForegroundColor Cyan
Write-Host "═════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total JARs scanned: $script:total_jars_scanned" -ForegroundColor Yellow
Write-Host "Critical findings: $script:critical_count" -ForegroundColor Red
Write-Host "Warnings: $script:warn_count" -ForegroundColor Yellow
Write-Host ""

if ($critical_count -gt 0) {
    Write-Host "🚨 CHEAT EVIDENCE FOUND:" -ForegroundColor Red
    foreach ($f in $findings | Where-Object { $_.Severity -eq "CRITICAL" }) {
        Write-Host "  [CRITICAL] $($f.Title)" -ForegroundColor Red
        Write-Host "    → $($f.Details)" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "🚨 BAN RECOMMENDED!" -ForegroundColor Red
    Write-Log "🚨 BAN RECOMMENDED"
} else {
    Write-Host "✓ NO CHEATS DETECTED" -ForegroundColor Green
    Write-Log "✓ CLEAN SCAN"
}

Write-Host ""
Write-Host "Report: $logfile" -ForegroundColor Cyan
Write-Host ""
