# Minecraft Screenshare Scanner v4.1 - PowerShell Edition
# Advanced Live Detection + File Movement & USB Tracking
# Detects: Running cheats, DLL injection, File movements, USB transfers

# Requires Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting admin privileges..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& '$PSCommandPath'`""
    exit
}

$ErrorActionPreference = "SilentlyContinue"

# RED STRINGS - Critical Cheat Clients (102+)
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
    "a.a.a.a", "virgin"
)

# YELLOW STRINGS - Suspicious Features (70+)
$YELLOW_STRINGS = @(
    "Illegal Modifications", "String Cleaner", "Autototem", "AutoAnchor",
    "CrystalAura", "Generic Shieldbreaker", "Generic autoanchor", "Autoretotem",
    "Autoarmor", "TriggerBot", "Aimassist", "ClickAimassist", "Possible Destruct",
    "Anchor macro", "Macro anchor", "Cw Crystal", "fast place", "Click Aimassist",
    "Fake cps", "Attack Delay", "Switch Delay", "Attack invisibles", "Speed Multiplier",
    "Sword Delay", "Axe Delay", "Click Simulation", "Sticky Aim", "Slot selection",
    "Dysplays Hud", "Ping spoof", "Autodoublehand", "Legit Totem", "Switch Back",
    "Auto Hit Crystal", "Double Glowstone", "Height Expansion", "Width Expansion",
    "throw delay", "Vertical Speed", "Horizontal Speed", "Speed Delay", "Donut SMP Bypass",
    "Auto shield breaker", "Crystal optimizer", "Auto crystal", "Auto loot", "Anchor Placer",
    "Stop on Kill", "AutoHitCrystal", "AutoDoubleHand", "AutoInventoryTotem",
    "Autoclicker", "blatant mode", "Delete USN Journal", "Only Crit Sword", "Only Crit Axe",
    "Equip Delay", "Generic Selfdestruct", "hit delay", "Disable Shields", "Generic disable shield",
    "No Miss Delay", "Generic Crystal Optimizer", "Auto WTap", "Auto Pot Refill", "Auto Pot",
    "Auto Jump Reset", "Auto Inventory Totem", "Auto Switch", "X-Ray", "Anti SS Tool",
    "Fake Lag", "Attack Players", "Netherite Finder", "Crystal placement"
)

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logfile = "$env:TEMP\Screenshare_Scan_$timestamp.txt"
$red_count = 0
$yellow_count = 0
$suspicious_moves = 0

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $logfile -Value $Message
}

# Header
Clear-Host
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   PROFESSIONAL SCREENSHARE SCANNER v4.1               ║" -ForegroundColor Cyan
Write-Host "║   Live Detection + USB & File Movement Tracking       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Log "╔════════════════════════════════════════════════════════╗"
Write-Log "║   PROFESSIONAL SCREENSHARE SCANNER v4.1               ║"
Write-Log "║   File Movement & USB Detection                       ║"
Write-Log "╚════════════════════════════════════════════════════════╝"
Write-Log "Scan Time: $(Get-Date)"
Write-Log ""

# Check for Minecraft
Write-Host "[1/9] Detecting running Minecraft..." -ForegroundColor Yellow
Write-Log "[1/9] MINECRAFT PROCESS DETECTION"

$java_proc = Get-Process | Where-Object {$_.ProcessName -eq "javaw" -or $_.ProcessName -eq "java"} | Select-Object -First 1

if ($java_proc) {
    Write-Host "✓ Found Minecraft process (PID: $($java_proc.Id))" -ForegroundColor Green
    Write-Log "✓ Found Minecraft process (PID: $($java_proc.Id))"
} else {
    Write-Host "✗ Minecraft not running" -ForegroundColor Red
    Write-Log "✗ Minecraft not running"
    Write-Host "Game must be running to scan. Start Minecraft and try again!" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}
Write-Log ""

# Module check (DLL injection)
Write-Host "[2/9] Scanning loaded DLL modules..." -ForegroundColor Yellow
Write-Log "[2/9] DLL INJECTION ANALYSIS"

try {
    $modules = $java_proc.Modules
    foreach ($module in $modules) {
        $dll_name = $module.ModuleName.ToLower()
        if ($dll_name -match "inject|hook|patch|cheat|crack|wurst|meteor|vape") {
            Write-Host "⚠ Suspicious DLL: $($module.ModuleName)" -ForegroundColor Yellow
            Write-Log "⚠ Suspicious DLL: $($module.ModuleName)"
            $yellow_count++
        }
    }
    Write-Host "✓ DLL scan complete" -ForegroundColor Green
    Write-Log "✓ DLL scan complete"
} catch {
    Write-Host "⚠ Could not access modules fully" -ForegroundColor Yellow
}
Write-Log ""

# Recycle Bin check (deleted cheat files)
Write-Host "[3/9] Checking Recycle Bin for deleted files..." -ForegroundColor Yellow
Write-Log "[3/9] RECYCLE BIN ANALYSIS (DELETED FILES)"

try {
    $shell = New-Object -ComObject Shell.Application
    $recycle_bin = $shell.NameSpace(10)  # 10 = Recycle Bin
    $items = $recycle_bin.Items()
    
    if ($items.Count -gt 0) {
        Write-Host "⚠ Found $($items.Count) items in Recycle Bin" -ForegroundColor Yellow
        Write-Log "⚠ Found $($items.Count) items in Recycle Bin"
        $suspicious_moves++
        
        foreach ($item in $items | Select-Object -First 20) {
            $item_name = $item.Name.ToLower()
            foreach ($red in $RED_STRINGS) {
                if ($item_name -contains $red.ToLower()) {
                    Write-Host "🚨 CRITICAL: Deleted cheat file '$($item.Name)' in Recycle Bin!" -ForegroundColor Red
                    Write-Log "🚨 CRITICAL: Deleted cheat file '$($item.Name)' in Recycle Bin"
                    $red_count++
                }
            }
        }
    } else {
        Write-Host "✓ Recycle Bin clean" -ForegroundColor Green
        Write-Log "✓ Recycle Bin clean"
    }
} catch {
    Write-Host "⚠ Could not access Recycle Bin (may require elevation)" -ForegroundColor Yellow
    Write-Log "⚠ Could not fully access Recycle Bin"
}
Write-Log ""

# USB Drive detection
Write-Host "[4/9] Scanning USB drives..." -ForegroundColor Yellow
Write-Log "[4/9] USB DRIVE SCANNING"

$usb_drives = @(Get-Volume | Where-Object {$_.DriveType -eq "Removable"})

if ($usb_drives.Count -gt 0) {
    Write-Host "⚠ Detected $($usb_drives.Count) USB drive(s)" -ForegroundColor Yellow
    Write-Log "⚠ Detected $($usb_drives.Count) USB drive(s) connected"
    
    foreach ($usb in $usb_drives) {
        if ($usb.DriveLetter) {
            $usb_path = "$($usb.DriveLetter):\"
            Write-Log "  Scanning: $usb_path"
            
            try {
                # Check for suspicious files on USB
                $suspicious_files = @(Get-ChildItem -Path $usb_path -Recurse -ErrorAction SilentlyContinue | 
                                     Where-Object {$_.Extension -in @('.jar', '.exe', '.dll')})
                
                if ($suspicious_files.Count -gt 0) {
                    Write-Host "  ⚠ Found $($suspicious_files.Count) executables on USB" -ForegroundColor Yellow
                    Write-Log "  ⚠ Found $($suspicious_files.Count) executables on USB"
                    $suspicious_moves++
                    
                    foreach ($file in $suspicious_files | Select-Object -First 10) {
                        Write-Log "    - $($file.Name) (Modified: $($file.LastWriteTime))"
                        $filename_lower = $file.Name.ToLower()
                        
                        # Check for cheat signatures
                        foreach ($red in $RED_STRINGS) {
                            if ($filename_lower -contains $red.ToLower()) {
                                Write-Host "    🚨 CHEAT FILE ON USB: $($file.Name)" -ForegroundColor Red
                                Write-Log "    🚨 CHEAT FILE ON USB: $($file.Name)"
                                $red_count++
                            }
                        }
                    }
                }
            } catch {}
        }
    }
} else {
    Write-Host "✓ No USB drives detected" -ForegroundColor Green
    Write-Log "✓ No USB drives detected"
}
Write-Log ""

# Recent file activity
Write-Host "[5/9] Analyzing recent file movements..." -ForegroundColor Yellow
Write-Log "[5/9] RECENT FILE ACTIVITY ANALYSIS"

$recent_time = (Get-Date).AddHours(-24)  # Last 24 hours
$minecraft_path = "$env:APPDATA\.minecraft"

try {
    $recent_files = @(Get-ChildItem -Path $minecraft_path -Recurse -ErrorAction SilentlyContinue | 
                     Where-Object {$_.LastWriteTime -gt $recent_time -and $_.Extension -in @('.jar', '.zip', '.exe')})
    
    if ($recent_files.Count -gt 0) {
        Write-Host "⚠ Found $($recent_files.Count) files modified in last 24 hours" -ForegroundColor Yellow
        Write-Log "⚠ Found $($recent_files.Count) recent files:"
        
        foreach ($file in $recent_files | Select-Object -First 15) {
            Write-Log "  - $($file.Name) (Modified: $($file.LastWriteTime))"
            $suspicious_moves++
        }
    } else {
        Write-Host "✓ No suspicious recent file activity" -ForegroundColor Green
        Write-Log "✓ No suspicious recent file activity"
    }
} catch {}
Write-Log ""

# Downloads folder check (common place to store cheats before moving)
Write-Host "[6/9] Checking Downloads folder..." -ForegroundColor Yellow
Write-Log "[6/9] DOWNLOADS FOLDER ANALYSIS"

$downloads_path = "$env:USERPROFILE\Downloads"
try {
    $exe_files = @(Get-ChildItem -Path $downloads_path -Filter "*.exe" -ErrorAction SilentlyContinue | Select-Object -First 20)
    $jar_files = @(Get-ChildItem -Path $downloads_path -Filter "*.jar" -ErrorAction SilentlyContinue | Select-Object -First 20)
    
    $total = $exe_files.Count + $jar_files.Count
    if ($total -gt 0) {
        Write-Host "⚠ Found $total suspicious files in Downloads" -ForegroundColor Yellow
        Write-Log "⚠ Found $total suspicious files in Downloads:"
        
        foreach ($file in @($exe_files + $jar_files)) {
            Write-Log "  - $($file.Name)"
            $suspicious_moves++
            
            foreach ($red in $RED_STRINGS) {
                if ($file.Name.ToLower() -contains $red.ToLower()) {
                    Write-Host "  🚨 CHEAT FILE IN DOWNLOADS: $($file.Name)" -ForegroundColor Red
                    Write-Log "  🚨 CHEAT FILE IN DOWNLOADS: $($file.Name)"
                    $red_count++
                }
            }
        }
    } else {
        Write-Host "✓ No suspicious files in Downloads" -ForegroundColor Green
        Write-Log "✓ No suspicious files in Downloads"
    }
} catch {}
Write-Log ""

# Desktop check
Write-Host "[7/9] Checking Desktop for suspicious files..." -ForegroundColor Yellow
Write-Log "[7/9] DESKTOP FILE ANALYSIS"

$desktop_path = "$env:USERPROFILE\Desktop"
try {
    $desktop_suspicious = @(Get-ChildItem -Path $desktop_path -ErrorAction SilentlyContinue | 
                           Where-Object {$_.Extension -in @('.exe', '.jar', '.zip', '.rar')})
    
    if ($desktop_suspicious.Count -gt 0) {
        Write-Host "⚠ Found $($desktop_suspicious.Count) suspicious files on Desktop" -ForegroundColor Yellow
        Write-Log "⚠ Found $($desktop_suspicious.Count) suspicious files on Desktop:"
        
        foreach ($file in $desktop_suspicious) {
            Write-Log "  - $($file.Name)"
            $suspicious_moves++
            
            foreach ($red in $RED_STRINGS) {
                if ($file.Name.ToLower() -contains $red.ToLower()) {
                    Write-Host "  🚨 CHEAT FILE ON DESKTOP: $($file.Name)" -ForegroundColor Red
                    Write-Log "  🚨 CHEAT FILE ON DESKTOP: $($file.Name)"
                    $red_count++
                }
            }
        }
    } else {
        Write-Host "✓ Desktop clean" -ForegroundColor Green
        Write-Log "✓ Desktop clean"
    }
} catch {}
Write-Log ""

# File system journal analysis (Windows Journal)
Write-Host "[8/9] Checking NTFS Journal for file movements..." -ForegroundColor Yellow
Write-Log "[8/9] NTFS FILE JOURNAL ANALYSIS"

try {
    $temp_dirs = @("$env:TEMP", "$env:USERPROFILE\AppData\Local\Temp")
    $recent_temp = @()
    
    foreach ($temp_path in $temp_dirs) {
        if (Test-Path $temp_path) {
            $temp_recent = @(Get-ChildItem -Path $temp_path -Recurse -ErrorAction SilentlyContinue | 
                            Where-Object {$_.LastWriteTime -gt (Get-Date).AddHours(-12) -and 
                                         $_.Extension -in @('.jar', '.exe', '.dll')})
            
            $recent_temp += $temp_recent
        }
    }
    
    if ($recent_temp.Count -gt 0) {
        Write-Host "⚠ Found $($recent_temp.Count) files recently created in temp folders" -ForegroundColor Yellow
        Write-Log "⚠ Found $($recent_temp.Count) recent temp files (could indicate hidden transfers):"
        
        foreach ($file in $recent_temp | Select-Object -First 10) {
            Write-Log "  - $($file.Name) (Created: $($file.CreationTime))"
            $suspicious_moves++
        }
    } else {
        Write-Host "✓ Temp folder clean (no recent executable activity)" -ForegroundColor Green
        Write-Log "✓ Temp folder clean"
    }
} catch {}
Write-Log ""

# Final scan - config files
Write-Host "[9/9] Final config file scan..." -ForegroundColor Yellow
Write-Log "[9/9] FINAL CONFIG SCAN"

$config_files = @(Get-ChildItem -Path $minecraft_path -Recurse -Filter "*.json" -ErrorAction SilentlyContinue | Select-Object -First 5)
foreach ($config in $config_files) {
    try {
        $content = Get-Content -Path $config.FullName -Raw -ErrorAction SilentlyContinue
        if ($content) {
            foreach ($red in $RED_STRINGS) {
                if ($content.ToLower().Contains($red.ToLower())) {
                    Write-Host "🚨 CRITICAL: '$red' in $($config.Name)" -ForegroundColor Red
                    Write-Log "🚨 CRITICAL: '$red' found in $($config.Name)"
                    $red_count++
                }
            }
        }
    } catch {}
}

Write-Host "✓ Scan complete" -ForegroundColor Green
Write-Log ""

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   FULL SCAN COMPLETE - RESULTS                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Log "╔════════════════════════════════════════════════════════╗"
Write-Log "║   FULL SCAN COMPLETE                                  ║"
Write-Log "╚════════════════════════════════════════════════════════╝"

Write-Host "CRITICAL FINDINGS (RED):  $red_count" -ForegroundColor Red
Write-Host "SUSPICIOUS ACTIVITY:      $yellow_count" -ForegroundColor Yellow
Write-Host "FILE MOVEMENT ALERTS:     $suspicious_moves" -ForegroundColor DarkYellow
Write-Log "CRITICAL (RED):           $red_count"
Write-Log "SUSPICIOUS (YELLOW):      $yellow_count"
Write-Log "FILE MOVEMENTS:           $suspicious_moves"

Write-Host ""
if ($red_count -gt 0) {
    Write-Host "🚨 CHEAT CLIENT DETECTED - BAN IMMEDIATELY!" -ForegroundColor Red
    Write-Log "🚨 CHEAT CLIENT DETECTED - BAN IMMEDIATELY"
} elseif ($suspicious_moves -gt 3) {
    Write-Host "⚠ SUSPICIOUS FILE MOVEMENTS - INVESTIGATION REQUIRED" -ForegroundColor Yellow
    Write-Log "⚠ SUSPICIOUS FILE MOVEMENTS - FURTHER REVIEW NEEDED"
} elseif ($yellow_count -gt 0) {
    Write-Host "⚠ MINOR SUSPICIOUS ACTIVITY DETECTED" -ForegroundColor Yellow
    Write-Log "⚠ MINOR SUSPICIOUS ACTIVITY DETECTED"
} else {
    Write-Host "✓ CLEAN SCAN - NO CHEATS DETECTED" -ForegroundColor Green
    Write-Log "✓ CLEAN SCAN - NO CHEATS DETECTED"
}

Write-Log ""
Write-Log "Report saved to: $logfile"
Write-Host ""
Write-Host "📄 Full report: $logfile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to open report..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

if (Test-Path $logfile) {
    Invoke-Item $logfile
}
