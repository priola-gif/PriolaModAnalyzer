# Minecraft Screenshare Scanner v4.2 - PowerShell Edition
# USB History Forensics + File Samples
# Shows when USB was connected and what files were on it

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting admin privileges..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& '$PSCommandPath'`""
    exit
}

$ErrorActionPreference = "SilentlyContinue"

# ═══════════════════════════════════════════════════════════════
# CUSTOM MOD PATHS - Add your own mod folders here!
# ═══════════════════════════════════════════════════════════════
# Edit the paths below to scan custom mod locations
# Default: C:\Users\[Username]\AppData\Roaming\.minecraft\mods
# 
# Examples of other paths:
# "C:\Users\Bob\AppData\Roaming\.minecraft\mods"
# "D:\Games\MultiMC\instances\Crystal\mods"
# "D:\Games\Prism Launcher\instances\1.20.4\mods"
# "C:\Custom\Mods\Folder"
# "E:\Backup\Mods"

$CUSTOM_MOD_PATHS = @(
    # Add paths here, one per line in quotes:
    # "D:\MyMods",
    # "C:\Games\Mods"
)

# RED STRINGS - Critical Cheat Clients (150+)
$RED_STRINGS = @(
    "WalksyOptimizer", "ClickCrystal", "Doomsday", "Surge", "Wing Client",
    "Francium client", "Lumina client", "WingClient", "Nova client",
    "Argon client", "NovaClient", "Prestige client", "Scrim client",
    "Grim client", "Meteor client", "Skliggahack", "Grandline Client",
    "Virgin Client", "Catlean Client", "Thunderhack Client", "St-Api Client",
    "Grim cracked", "Krypton Client", "Gardenia client", "Shoreline client",
    "Minced client", "Jnic obfuscator", "Xyla Client", "Coffee Client",
    "NoWeakAttack Client", "Triggerbot Client", "hwid auth", "Wurst client module",
    "Lattia Client", "Ghost Bleach Client", "Asteria Client", "Xenon client",
    "Cyanide Client", "Crypt Client", "Vea Client", "Bape Client",
    "Misplace Client", "Private Client", "Yay Client", "Cocaina Client",
    "Xina Client", "Depression Client", "Small Cheat", "Kappa Client",
    "Purge Client", "Paralyzed Client", "Syphlex Client", "Dank Client",
    "Universal Client", "AutoClicker", "Impact Client", "Magenta Client",
    "CPSMod Client", "Sallos Client", "Tera Modifier", "Atom Client",
    "Cyanit Client", "Lyvell Client", "Skill Client", "Sampler Client",
    "S9 Client", "Irid Client", "Authority Client", "Syntax Client",
    "Aperture Client", "Xerxes Client", "Kyprak Client", "Def Client",
    "Grand0x Client", "InstaVape Mod", "Placebo Client", "Spook Client",
    "Spooky Caspar Client", "Omikron Client", "XTC Client", "Vape Client V2",
    "Incognito Client", "Fitchi Client", "WayClient", "Shadow Client",
    "Gorilla Client", "Harambe Client", "Kurium Client", "Merge Client",
    "Incide Client", "Xetha Client", "Veiv Client", "Conceal Client",
    "Ethylene Client", "Era Client", "Pandora Client", "Pepe Client",
    "Rebellion Client", "Phoenix Client", "Bit Client", "ghosted triggerbot",
    "Strafe Modifications", "FastPlace Mod", "SafeWalk Mod", "NoHacks Module",
    "MouseTweaks", "OCMC Reach", "Reach Modifications", "KnockBack Modifications",
    "Casper Client", "Drek Client", "KryptoB1 Client", "Adrigoron Client",
    "Wombo Client", "Lowser Client", "Fusk Client", "Ancient Client",
    "Bleach Client", "Sensation Client", "Willy Client", "Latch Client",
    "Integra Client", "Cheat Engine", "Random injection", "TipTap Client",
    "a.a.a.a", "virgin",
    "doomsday", "DoomsdayClient", "doomsdayclient.com", "com.doomsday", "net.doomsday",
    "doomsday.module", "DoomsdayMod", "DoomsdayCore", "DoomsdayLoader",
    "DOOMSDAY_HWID", "doomsday_config", "doomsday_auth", "DoomsdayKillAura",
    "DoomsdayESP", "DoomsdayFly", "doom_bypass", "DoomsdayAPI", "doomsday.bypass",
    "doomsday.aimbot", "doomsday.velocity", "DoomVelocity",
    "novaclient", "api.novaclient.lol",
    "riseclient", "rise.today", "RiseClient",
    "vape.gg", "vapeclient", "VapeLite",
    "intent.store", "IntentClient",
    "KillAura", "CrystalAura", "AnchorAura", "PacketFly", "AntiKB", "Disabler"
)

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logfile = "$env:TEMP\Screenshare_Scan_$timestamp.txt"
$red_count = 0
$usb_found = 0

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $logfile -Value $Message
}

Clear-Host
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   PROFESSIONAL SCREENSHARE SCANNER v4.2               ║" -ForegroundColor Cyan
Write-Host "║   USB History Forensics + File Samples                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Log "╔════════════════════════════════════════════════════════╗"
Write-Log "║   PROFESSIONAL SCREENSHARE SCANNER v4.2               ║"
Write-Log "║   USB History Forensics                               ║"
Write-Log "╚════════════════════════════════════════════════════════╝"
Write-Log "Scan Time: $(Get-Date)"
Write-Log ""

# Check Minecraft
Write-Host "[1/5] Detecting Minecraft..." -ForegroundColor Yellow
Write-Log "[1/6] MINECRAFT DETECTION"
$java_proc = Get-Process | Where-Object {$_.ProcessName -eq "javaw" -or $_.ProcessName -eq "java"} | Select-Object -First 1
if ($java_proc) {
    Write-Host "✓ Minecraft found" -ForegroundColor Green
    Write-Log "✓ Minecraft process found (PID: $($java_proc.Id))"
} else {
    Write-Host "✗ Minecraft not running" -ForegroundColor Red
    Write-Log "✗ Minecraft not running"
    Read-Host "Press Enter to exit"
    exit
}
Write-Log ""

# USB History from Registry
Write-Host "[2/6] Scanning USB device history..." -ForegroundColor Yellow
Write-Log "[2/6] USB DEVICE HISTORY (REGISTRY)"

$usb_devices = @()
try {
    # Check USB storage devices
    $reg_path = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"
    if (Test-Path $reg_path) {
        $usb_reg = Get-ChildItem $reg_path -ErrorAction SilentlyContinue
        
        foreach ($device in $usb_reg) {
            $serial = $device.PSChildName
            $device_info = Get-ItemProperty "$reg_path\$serial" -ErrorAction SilentlyContinue
            
            if ($device_info) {
                $usb_devices += @{
                    Serial = $serial
                    FriendlyName = $device_info.FriendlyName
                }
                Write-Log "  Device: $($device_info.FriendlyName) (Serial: $serial)"
                $usb_found++
            }
        }
    }
    
    if ($usb_found -gt 0) {
        Write-Host "⚠ Found $usb_found USB device(s) in history" -ForegroundColor Yellow
        Write-Log "⚠ Found $usb_found USB device(s) connected to system"
    } else {
        Write-Host "✓ No USB devices found in registry" -ForegroundColor Green
        Write-Log "✓ No USB history found"
    }
} catch {
    Write-Host "⚠ Could not access USB registry" -ForegroundColor Yellow
}
Write-Log ""

# USB Connection Times
Write-Host "[3/6] Retrieving USB connection history..." -ForegroundColor Yellow
Write-Log "[3/6] USB CONNECTION TIMELINE"

try {
    # Check Setup API logs for USB connections
    $setup_log = "C:\Windows\inf\setupapi.dev.log"
    if (Test-Path $setup_log) {
        $usb_connections = @(Get-Content $setup_log | Select-String -Pattern "USB" | Select-Object -Last 20)
        
        if ($usb_connections.Count -gt 0) {
            Write-Host "⚠ Found $($usb_connections.Count) USB connection records" -ForegroundColor Yellow
            Write-Log "⚠ Recent USB Connection Events:"
            foreach ($connection in $usb_connections) {
                Write-Log "  $($connection.Line)"
            }
        } else {
            Write-Host "✓ No recent USB connections logged" -ForegroundColor Green
            Write-Log "✓ No recent USB connections"
        }
    } else {
        Write-Host "ℹ Setup log not accessible" -ForegroundColor Cyan
        Write-Log "ℹ Setup log location not found"
    }
} catch {
    Write-Host "⚠ Could not read USB logs" -ForegroundColor Yellow
}
Write-Log ""

# Custom Mod Path Scanning
Write-Host "[4/5] Scanning custom mod paths..." -ForegroundColor Yellow
Write-Log "[4/5] CUSTOM MOD PATH SCANNING"

$all_mod_paths = @()
$minecraft_default = "$env:APPDATA\.minecraft\mods"

# Add default path
if (Test-Path $minecraft_default) {
    $all_mod_paths += $minecraft_default
}

# Add custom paths
foreach ($custom_path in $CUSTOM_MOD_PATHS) {
    if ($custom_path -and (Test-Path $custom_path)) {
        $all_mod_paths += $custom_path
    }
}

if ($all_mod_paths.Count -gt 0) {
    Write-Host "⚠ Scanning $($all_mod_paths.Count) mod folder(s)..." -ForegroundColor Yellow
    Write-Log "⚠ Scanning Mod Paths:"
    
    foreach ($mod_path in $all_mod_paths) {
        Write-Log "  Scanning: $mod_path"
        
        try {
            $mod_files = @(Get-ChildItem -Path $mod_path -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue)
            
            if ($mod_files.Count -gt 0) {
                Write-Log "  Found $($mod_files.Count) JAR files:"
                
                foreach ($jar in $mod_files | Select-Object -First 10) {
                    Write-Log "    - $($jar.Name) (Size: $([math]::Round($jar.Length/1KB, 2)) KB)"
                    $filename_lower = $jar.Name.ToLower()
                    
                    foreach ($red in $RED_STRINGS) {
                        if ($filename_lower.Contains($red.ToLower())) {
                            Write-Host "    🚨 CHEAT DETECTED: $($jar.Name)" -ForegroundColor Red
                            Write-Log "    🚨 CHEAT DETECTED: Matches '$red'"
                            $red_count++
                        }
                    }
                }
            } else {
                Write-Log "  ✓ No JAR files in this folder"
            }
        } catch {
            Write-Log "  ⚠ Could not scan this path"
        }
    }
} else {
    Write-Host "ℹ No mod paths configured (using USB scan only)" -ForegroundColor Cyan
    Write-Log "ℹ No custom mod paths found"
}
Write-Log ""

# Scan USB Drives - File Samples
Write-Host "[5/6] Scanning USB drives and collecting file samples..." -ForegroundColor Yellow
Write-Log "[5/6] USB FILE SAMPLE COLLECTION"

$usb_drives = @(Get-Volume | Where-Object {$_.DriveType -eq "Removable"})

if ($usb_drives.Count -gt 0) {
    Write-Host "⚠ Detected $($usb_drives.Count) USB drive(s) - Collecting samples" -ForegroundColor Yellow
    Write-Log "⚠ Detected $($usb_drives.Count) USB drive(s) connected NOW"
    
    foreach ($usb in $usb_drives) {
        if ($usb.DriveLetter) {
            $usb_path = "$($usb.DriveLetter):\"
            Write-Log ""
            Write-Log "═══════════════════════════════════════"
            Write-Log "USB DRIVE: $($usb.DriveLetter): - $($usb.FileSystemLabel)"
            Write-Log "═══════════════════════════════════════"
            
            try {
                # Get all files on USB
                $all_files = @(Get-ChildItem -Path $usb_path -Recurse -ErrorAction SilentlyContinue | 
                              Where-Object {-not $_.PSIsContainer})
                
                # Suspicious files
                $suspicious = @($all_files | Where-Object {$_.Extension -in @('.jar', '.exe', '.dll', '.zip', '.rar', '.7z')})
                
                Write-Log "Total Files: $($all_files.Count)"
                Write-Log "Suspicious Files: $($suspicious.Count)"
                Write-Log ""
                
                if ($suspicious.Count -gt 0) {
                    Write-Log "FILE SAMPLES (First 20):"
                    Write-Log "─────────────────────────"
                    
                    $sample_count = 0
                    foreach ($file in $suspicious | Select-Object -First 20) {
                        $sample_count++
                        $size_kb = [math]::Round($file.Length / 1KB, 2)
                        $modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                        
                        Write-Log "[$sample_count] $($file.Name)"
                        Write-Log "    Size: $size_kb KB"
                        Write-Log "    Modified: $modified"
                        Write-Log "    Path: $($file.FullName)"
                        
                        # Check for cheat signatures
                        $filename_lower = $file.Name.ToLower()
                        foreach ($red in $RED_STRINGS) {
                            if ($filename_lower.Contains($red.ToLower())) {
                                Write-Host "    🚨 CHEAT DETECTED: $($file.Name)" -ForegroundColor Red
                                Write-Log "    🚨 CHEAT DETECTED: Matches '$red'"
                                $red_count++
                            }
                        }
                        Write-Log ""
                    }
                    
                    # Show directory structure
                    Write-Log "DIRECTORY STRUCTURE:"
                    Write-Log "─────────────────────────"
                    $folders = @(Get-ChildItem -Path $usb_path -Recurse -ErrorAction SilentlyContinue | 
                                Where-Object {$_.PSIsContainer} | Select-Object -First 15)
                    
                    foreach ($folder in $folders) {
                        $depth = ($folder.FullName.Split('\').Count - $usb_path.Split('\').Count) * 2
                        Write-Log "$(' ' * $depth)├─ $($folder.Name)/"
                    }
                } else {
                    Write-Host "  ✓ No suspicious files on this drive" -ForegroundColor Green
                    Write-Log "✓ No suspicious files detected"
                }
            } catch {
                Write-Host "  ⚠ Error scanning this USB" -ForegroundColor Yellow
                Write-Log "⚠ Could not fully scan this USB drive"
            }
        }
    }
} else {
    Write-Host "✓ No USB drives currently connected" -ForegroundColor Green
    Write-Log "✓ No USB drives detected (none plugged in right now)"
}
Write-Log ""

# Summary
Write-Host "[6/6] Generating final report..." -ForegroundColor Yellow

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SCAN COMPLETE - USB FORENSICS RESULTS               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Log "╔════════════════════════════════════════════════════════╗"
Write-Log "║   SCAN COMPLETE - USB FORENSICS REPORT                ║"
Write-Log "╚════════════════════════════════════════════════════════╝"

Write-Host "USB Devices in History:  $usb_found" -ForegroundColor DarkYellow
Write-Host "CRITICAL FINDINGS:       $red_count" -ForegroundColor Red
Write-Log "USB Devices in History:  $usb_found"
Write-Log "Critical Findings:       $red_count"

Write-Host ""
if ($red_count -gt 0) {
    Write-Host "🚨 CHEAT FILES DETECTED ON USB - BAN IMMEDIATELY!" -ForegroundColor Red
    Write-Log "🚨 CHEAT FILES FOUND ON USB - EVIDENCE OF CHEATING"
} elseif ($usb_found -gt 0) {
    Write-Host "⚠ USB HISTORY DETECTED - PLAYER HAS USED USB DEVICES" -ForegroundColor Yellow
    Write-Log "⚠ Player has connected USB devices - Review samples above"
} else {
    Write-Host "✓ NO USB CHEATS DETECTED" -ForegroundColor Green
    Write-Log "✓ NO USB CHEAT EVIDENCE FOUND"
}

Write-Log ""
Write-Log "Full report: $logfile"
Write-Host ""
Write-Host "📄 Report saved to: $logfile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to open report..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

if (Test-Path $logfile) {
    Invoke-Item $logfile
}
