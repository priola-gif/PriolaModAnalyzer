# Minecraft Screenshare Scanner v6.0 IMPROVED - STRING FINDER EDITION
# Integrated: v5.2 + USBView + MeowModAnalyzer + System Tools
# WITH WORKING STRING DETECTION & DISPLAY

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting admin..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"& '$PSCommandPath'`""
    exit
}

$ErrorActionPreference = "SilentlyContinue"

# ═══════════════════════════════════════════════════════════════
# INTERACTIVE MOD PATH CONFIGURATION
Clear-Host
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SCREENSHARE SCANNER v6.0 - MOD PATH SETUP           ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$CUSTOM_MOD_PATHS = @()
$default_path = "$env:APPDATA\.minecraft\mods"

Write-Host "Default Mod Path: $default_path" -ForegroundColor Green
Write-Host ""

$add_custom = Read-Host "Add custom mod paths? (y/n)"

if ($add_custom -eq "y" -or $add_custom -eq "yes") {
    Write-Host ""
    Write-Host "Enter custom mod paths (one per line, press Enter twice to finish):" -ForegroundColor Yellow
    Write-Host ""
    
    while ($true) {
        $path = Read-Host "Path"
        
        if ([string]::IsNullOrWhiteSpace($path)) {
            break
        }
        
        if (Test-Path $path) {
            $CUSTOM_MOD_PATHS += $path
            Write-Host "  ✓ Added: $path" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Path not found: $path" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "═════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "Paths to scan:" -ForegroundColor Cyan
Write-Host "  • $default_path (default)" -ForegroundColor Green

if ($CUSTOM_MOD_PATHS.Count -gt 0) {
    foreach ($p in $CUSTOM_MOD_PATHS) {
        Write-Host "  • $p" -ForegroundColor Green
    }
}

Write-Host "═════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$confirm = Read-Host "Ready to scan? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "yes") {
    Write-Host "Cancelled" -ForegroundColor Yellow
    exit
}

# ═══════════════════════════════════════════════════════════════
# CHEAT SIGNATURES
$RED_STRINGS = @(
    "doomsday", "novaclient", "riseclient", "vapeclient", "intent",
    "WalksyOptimizer", "ClickCrystal", "Nova", "Meteor",
    "Wurst", "Impact", "Grim", "Liquidbounce", "Aristois", "Skliggahack"
)

$MEOW_PATTERNS = @(
    "AutoCrystal", "autocrystal", "auto crystal", "AutoAnchor", "autoanchor",
    "AutoTotem", "autototem", "AutoPot", "autopot", "AutoArmor", "autoarmor",
    "ShieldBreaker", "ShieldDisabler", "AutoDoubleHand", "autodoublehand",
    "AimAssist", "aimassist", "TriggerBot", "triggerbot", "FakeLag", "FakeInv",
    "AutoClicker", "PackSpoof", "Antiknockback", "BaseFinder", "invsee",
    "FastPlace", "WebMacro", "FreezePlayer", "ElytraSwap", "FastXP",
    "MaceSwap", "JumpReset", "AxeSpam", "axespam", "AutoMace",
    "InventoryTotem", "HoverTotem", "LegitTotem", "AutoArmor",
    "Freecam", "NoClip", "NoFall", "nofall", "KeyPearl", "LootYeeter",
    "AutoBreach", "AntiWeb", "AutoWeb", "WalksyCrystalOptimizerMod",
    "lvstrng", "dqrkis", "selfdestruct", "PingSpoof", "pingspoof",
    "CrystalAura", "AnchorAura", "PacketFly", "AntiKB", "Disabler",
    
    # OBFUSCATED STRINGS FROM CONFIGPLUS ANALYSIS
    "A.utomatically hit-crystals", "hit-crystals", "Automatically attacks while falling with mace",
    "arePeopleAimingAtBlockAndHoldingCrystals", "arePeopleAimingAtBlock",
    "nearbyCrystals", "TriggerListenerMap", "FishingHookHelper", "CallbackInjector",
    "onInitializeClient", "lambda$arePeopleAimingAtBlockAndHoldingCrystals",
    "lambda$nearbyCrystals", "lambda$arePeopleAimingAtBlock",
    "TriggerListenerMap.java", "FishingHookHelper.java", "CallbackInjector.java",
    "arePeopleAimingAtBlock$6", "arePeopleAimingAtBlock$7", "nearbyCrystals$5",
    "arePeopleAimingAtBlockAndHoldingCrystals$8", "arePeopleAimingAtBlockAndHoldingCrystals$9",
    "arePeopleAimingAtBlockAndHoldingCrystals$10", "onInitializeClient$0",
    
    # SUSPICIOUS INJECTION/HOOK PATTERNS
    "CallbackInfo", "CallbackInfoReturnable", "Inject", "At",
    "MixinPriority", "mixins", "entrypoints", "fabricmc",
    "RenderC", "BindA", "PackB", "SortC", "UtilD", "RenderE",
    "DataB", "EventC", "CacheD", "LoadE", "SyncF", "ParseG", "BuildH", "CheckJ", "ConfigA",
    
    # OBFUSCATION INDICATORS
    "lithium", "Lithium", "optimization", "C16d71e5042", "C8254494e5e",
    "CB78c6cdbbd", "C52adbecbef", "CEa2948d7e7", "CA0b4ad126b"
)

$FULLWIDTH_PATTERNS = @(
    # Original patterns
    "ＡｕｔｏＣｒｙｓｔａｌ", "Ａｕｔｏ Ｃｒｙｓｔａｌ",
    "ＡｕｔｏＡｎｃｈｏｒ", "Ａｕｔｏ Ａｎｃｈｏｒ",
    "ＤｏｕｂｌｅＡｎｃｈｏｒ", "ＡｕｔｏＴｏｔｅｍ", "ＨｏｖｅｒＴｏｔｅｍ",
    
    # User-added obfuscation patterns (40+)
    "Ａ．ｃｔｉｖａｔｅ Ｋｅｙ", "Ａ．ｎｃｈｏｒ Ｍａｃｒｏ", "Ａ．ｎｃｈｏｒ Ｍａｃｒｏ Ｖ２",
    "Ａ．ｕｔｏ Ｃｒｙｓｔａｌ", "Ａ．ｕｔｏ Ｄｏｕｂｌｅ Ｈａｎｄ", "Ａ．ｕｔｏ Ｈｉｔ Ｃｒｙｓｔａｌ",
    "Ａ．ｕｔｏ Ｉｎｖｅｎｔｏｒｙ Ｔｏｔｅｍ", "Ａ．ｕｔｏ Ｔｏｔｅｍ Ｈｉｔ", "Ａ．ｕｔｏＣｒｙｓｔａｌＬＶ２",
    "Ｃ．ｌｉｃｋ Ｓｉｍｕｌａｔｉｏｎ", "Ｄ．ｏｕｂｌｅ Ａｎｃｈｏｒ", "Ｅ．ｘｐｌｏｄｅ Ｃｈａｎｃｅ",
    "Ｅ．ｘｐｌｏｄｅ Ｄｅｌａｙ", "Ｅ．ｘｐｌｏｄｅ Ｓｌｏｔ", "Ｆ．ｏｒｃｅ Ｔｏｔｅｍ",
    "Ｇ．ｌｏｗｓｔｏｎｅ Ｃｈａｎｃｅ", "Ｇ．ｌｏｗｓｔｏｎｅ Ｄｅｌａｙ", "Ｈ．ｏｖｅｒ",
    "Ｈ．ｏｖｅｒ Ｔｏｔｅｍ", "isDeadBodyNearby", "Ｏ．ｎｌｙ Ｃｈａｒｇｅ",
    "Ｏ．ｎｌｙ Ｏｗｎ", "Ｐ．ｌａｃｅ Ｃｈａｎｃｅ", "Ｒ．ａｎｄｏｍ Ｇｌｏｗｓｔｏｎｅ",
    "Ｓ．ａｆｅＡｎｃｈｏｒ", "Ｓ．ｔｏｐ ｏｎ Ｋｉｌｌ", "Ｓ．ｗｉｔｃｈ Ｄｅｌａｙ",
    "Ｓ．ｗｔｃｈ Ｃｈａｎｃｅ", "Ｔ．ｏｔｅｍ Ｆｉｒｓｔ", "Ｔ．ｏｔｅｍ Ｏｆｆｈａｎｄ",
    "Ｔ．ｏｔｅｍ Ｓｌｏｔ", "Ｗ．ｈｉｌｅ Ｕｓｅ", "Ｗ．ｏｒｋ Ｗｉｔｈ Ｔｏｔｅｍ"
)

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logfile = "$env:TEMP\Screenshare_Scan_$timestamp.txt"
$findings = @()
$critical_count = 0
$warn_count = 0

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $logfile -Value $Message
}

function Add-Finding {
    param([string]$Severity, [string]$Title, [string]$Details)
    $findings += @{ Severity = $Severity; Title = $Title; Details = $Details }
    if ($Severity -eq "CRITICAL") { $script:critical_count++ }
    else { $script:warn_count++ }
}

# ═══════════════════════════════════════════════════════════════
# MODRINTH MOD VERIFICATION FUNCTION
function Check-ModrinthMod {
    param([string]$JarPath, [string]$ModName)
    
    $results = @{
        Found = $false
        Official = $false
        VersionMatch = $false
        SizeMatch = $false
        FileMatch = $false
        Suspicious = $false
        Details = @()
    }
    
    try {
        # Get JAR file size
        $jar_size = (Get-Item $JarPath).Length
        $jar_filename = Split-Path $JarPath -Leaf
        
        # Search Modrinth API for mod
        $search_url = "https://api.modrinth.com/v2/search?query=$([System.Web.HttpUtility]::UrlEncode($ModName))&limit=5"
        $search_response = Invoke-RestMethod -Uri $search_url -ErrorAction SilentlyContinue
        
        if ($search_response.hits -and $search_response.hits.Count -gt 0) {
            $results.Found = $true
            
            # Check first result (most relevant)
            $mod = $search_response.hits[0]
            $mod_id = $mod.project_id
            $mod_name = $mod.title
            $mod_version = $mod.latest_version
            
            $results.Details += "Modrinth mod found: $mod_name (v$mod_version)"
            
            # Get detailed project info
            $project_url = "https://api.modrinth.com/v2/project/$mod_id/versions"
            $versions_response = Invoke-RestMethod -Uri $project_url -ErrorAction SilentlyContinue
            
            if ($versions_response) {
                foreach ($version in $versions_response) {
                    # Check version match
                    if ($version.version_number -match [regex]::Escape($mod_version)) {
                        $results.VersionMatch = $true
                        
                        # Check file details
                        if ($version.files -and $version.files.Count -gt 0) {
                            foreach ($file in $version.files) {
                                $official_size = $file.size
                                $official_filename = $file.filename
                                
                                # Compare sizes (allow 5% variance)
                                $size_variance = [math]::Abs($jar_size - $official_size)
                                $size_percent = ($size_variance / $official_size) * 100
                                
                                if ($size_percent -lt 5) {
                                    $results.SizeMatch = $true
                                    $results.Details += "Size match: $jar_size bytes (official: $official_size bytes)"
                                } else {
                                    $results.Suspicious = $true
                                    $results.Details += "⚠ SIZE MISMATCH: $jar_size bytes vs official $official_size bytes ($([math]::Round($size_percent, 2))%)"
                                }
                                
                                # Compare filenames
                                if ($jar_filename -eq $official_filename) {
                                    $results.FileMatch = $true
                                    $results.Details += "Filename match: $jar_filename"
                                } else {
                                    $results.Suspicious = $true
                                    $results.Details += "⚠ FILENAME MISMATCH: Found '$jar_filename' vs official '$official_filename'"
                                }
                                
                                $results.Official = $true
                                break
                            }
                        }
                    }
                    
                    if ($results.Official) { break }
                }
            }
        } else {
            $results.Details += "⚠ Mod not found on Modrinth (possible fake/private)"
            $results.Suspicious = $true
        }
    } catch {
        $results.Details += "Could not verify with Modrinth (API error)"
    }
    
    return $results
}
function Find-StringsInJAR {
    param([string]$JarPath)
    
    $found_strings = @()
    
    try {
        # Add ZIP assembly
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        
        # Open JAR as ZIP
        $zip = [System.IO.Compression.ZipFile]::OpenRead($JarPath)
        
        # Read all entries
        foreach ($entry in $zip.Entries) {
            $name = $entry.Name.ToLower()
            
            # Check ALL files (not just specific types) - strings can be anywhere
            try {
                # Extract to memory
                $stream = $entry.Open()
                $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8, $true)
                $content = $reader.ReadToEnd()
                $reader.Dispose()
                
                # Search for RED strings
                foreach ($red in $RED_STRINGS) {
                    if ($content -match [regex]::Escape($red)) {
                        if ($found_strings -notcontains $red) {
                            $found_strings += $red
                        }
                    }
                }
                
                # Search for MEOW patterns
                foreach ($pattern in $MEOW_PATTERNS) {
                    if ($content -match [regex]::Escape($pattern)) {
                        if ($found_strings -notcontains $pattern) {
                            $found_strings += $pattern
                        }
                    }
                }
                
                # Search for FULLWIDTH UNICODE patterns
                foreach ($fullwidth in $FULLWIDTH_PATTERNS) {
                    if ($content -match [regex]::Escape($fullwidth)) {
                        if ($found_strings -notcontains $fullwidth) {
                            $found_strings += $fullwidth
                        }
                    }
                }
            } catch {}
        }
        
        $zip.Dispose()
    } catch {}
    
    return $found_strings
}

# ═══════════════════════════════════════════════════════════════
Clear-Host
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SCREENSHARE SCANNER v6.0 - COMPLETE SUITE           ║" -ForegroundColor Cyan
Write-Host "║   WITH STRING DETECTION & DISPLAY                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Log "SCREENSHARE SCANNER v6.0 IMPROVED - $(Get-Date)"
Write-Log ""

# [1/15] Minecraft
Write-Host "[1/15] Detecting Minecraft..." -ForegroundColor Yellow
$java_proc = Get-Process | Where-Object {$_.ProcessName -match "java"} | Select-Object -First 1
if (-not $java_proc) {
    Write-Host "✗ Minecraft not running - EXIT" -ForegroundColor Red
    Read-Host "Press Enter"
    exit
}
Write-Host "✓ Minecraft found (PID: $($java_proc.Id))" -ForegroundColor Green
Write-Log "✓ Minecraft detected (PID: $($java_proc.Id))"
Write-Log ""

# [2/15] System Boot & Services
Write-Host "[2/15] Analyzing system boot and services..." -ForegroundColor Yellow
Write-Log "[2/15] SYSTEM BOOT & SERVICES"
try {
    $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $uptime = (Get-Date) - $bootTime
    Write-Log "  Boot Time: $($bootTime.ToString('yyyy-MM-dd HH:mm:ss'))"
    
    $critical_services = @("EventLog", "Schedule")
    foreach ($svc_name in $critical_services) {
        $svc = Get-Service -Name $svc_name -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -ne "Running") {
            Write-Host "⚠ SERVICE DISABLED: $($svc.DisplayName)" -ForegroundColor Red
            Add-Finding "CRITICAL" "Service Disabled" "$($svc.DisplayName)"
        }
    }
} catch {}
Write-Log ""

# [3/15] Event Log Tampering
Write-Host "[3/15] Checking event logs..." -ForegroundColor Yellow
Write-Log "[3/15] EVENT LOG ANALYSIS"
try {
    $cleared = Get-WinEvent -FilterHashtable @{LogName="System"; ID=104} -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($cleared) {
        Write-Host "🚨 EVENT LOG CLEARED!" -ForegroundColor Red
        Write-Log "🚨 Event log cleared"
        Add-Finding "CRITICAL" "Log Tampering" "Event logs were cleared"
    }
} catch {}
Write-Log ""

# [4/15] Prefetch Integrity
Write-Host "[4/15] Checking prefetch integrity..." -ForegroundColor Yellow
Write-Log "[4/15] PREFETCH INTEGRITY"
try {
    $pf_files = Get-ChildItem -Path "C:\Windows\Prefetch" -Filter "*.pf" -Force | Where-Object {
        $_.Attributes -band [System.IO.FileAttributes]::Hidden
    }
    if ($pf_files.Count -gt 0) {
        Write-Host "🚨 HIDDEN PREFETCH FILES: $($pf_files.Count)" -ForegroundColor Red
        Add-Finding "CRITICAL" "Prefetch Tampering" "$($pf_files.Count) hidden prefetch files"
    }
} catch {}
Write-Log ""

# [5/15] Recycle Bin
Write-Host "[5/15] Deep scanning Recycle Bin..." -ForegroundColor Yellow
Write-Log "[5/15] RECYCLE BIN FORENSICS"
try {
    $recycle = "$env:SystemDrive\`$Recycle.Bin"
    if (Test-Path $recycle) {
        $deleted = Get-ChildItem -LiteralPath $recycle -File -Force -Recurse | Select-Object -First 20
        foreach ($item in $deleted) {
            foreach ($cheat in $RED_STRINGS) {
                if ($item.Name -match [regex]::Escape($cheat)) {
                    Write-Host "🚨 DELETED CHEAT: $($item.Name)" -ForegroundColor Red
                    Write-Log "🚨 Deleted cheat in Recycle Bin: $($item.Name)"
                    Add-Finding "CRITICAL" "Deleted Cheat" "$($item.Name)"
                }
            }
        }
    }
} catch {}
Write-Log ""

# [6/15] PowerShell History
Write-Host "[6/15] Analyzing PowerShell history..." -ForegroundColor Yellow
Write-Log "[6/15] POWERSHELL HISTORY"
try {
    $history_path = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
    if (Test-Path $history_path) {
        $size = (Get-Item $history_path).Length
        if ($size -lt 100) {
            Write-Host "⚠ HISTORY CLEARED" -ForegroundColor Yellow
            Write-Log "⚠ PowerShell history suspiciously small"
            Add-Finding "WARNING" "History Tampering" "PowerShell history appears cleared"
        }
    }
} catch {}
Write-Log ""

# [7/15] Prefetch Execution
Write-Host "[7/15] Analyzing prefetch execution..." -ForegroundColor Yellow
Write-Log "[7/15] PREFETCH EXECUTION HISTORY"
try {
    $bootTime = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    $java_pf = Get-ChildItem -Path "C:\Windows\Prefetch" -Filter "*java*.pf" -ErrorAction SilentlyContinue |
               Where-Object { $_.LastWriteTime -gt $bootTime }
    if ($java_pf.Count -gt 0) {
        Write-Host "⚠ Java executed $($java_pf.Count) time(s)" -ForegroundColor Yellow
        Write-Log "⚠ Java prefetch files with recent activity: $($java_pf.Count)"
    }
} catch {}
Write-Log ""

# [8/16] Modrinth Mod Verification
Write-Host "[8/16] Verifying mods with Modrinth..." -ForegroundColor Yellow
Write-Log "[8/16] MODRINTH MOD VERIFICATION"

$all_jar_paths = @($default_path) + $CUSTOM_MOD_PATHS
$jar_locations = @("$env:TEMP", "$env:USERPROFILE\Downloads")
$all_jar_paths += $jar_locations

foreach ($location in $all_jar_paths) {
    if (Test-Path $location) {
        Write-Log "  Verifying mods in: $location"
        $jars = Get-ChildItem -Path $location -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 10
        
        foreach ($jar in $jars) {
            $mod_name = $jar.Name -replace '\.jar$', ''
            Write-Host "  Checking: $($jar.Name)..." -ForegroundColor Cyan
            
            $modrinth_check = Check-ModrinthMod -JarPath $jar.FullName -ModName $mod_name
            
            if ($modrinth_check.Suspicious) {
                Write-Host "    ⚠ SUSPICIOUS MOD - VERIFICATION FAILED" -ForegroundColor Red
                foreach ($detail in $modrinth_check.Details) {
                    Write-Host "      → $detail" -ForegroundColor Yellow
                    Write-Log "      $detail"
                }
                Add-Finding "CRITICAL" "Fake/Modified Mod" "$($jar.Name) - Modrinth verification failed"
            } elseif ($modrinth_check.Found -and $modrinth_check.Official) {
                Write-Host "    ✓ Verified official mod" -ForegroundColor Green
                Write-Log "    ✓ Verified: $($jar.Name)"
            } else {
                Write-Host "    ⚠ Could not verify on Modrinth" -ForegroundColor Yellow
                Write-Log "    ⚠ Unverified mod: $($jar.Name)"
            }
        }
    }
}
Write-Log ""

# [9/16] JAR FILE SCANNING WITH STRING DETECTION
Write-Host "[8/15] Scanning JAR files with string detection..." -ForegroundColor Yellow
Write-Log "[8/15] JAR FILE SCANNING WITH STRING ANALYSIS"

$all_jar_paths = @($default_path) + $CUSTOM_MOD_PATHS
$jar_locations = @("$env:TEMP", "$env:USERPROFILE\Downloads")
$all_jar_paths += $jar_locations

foreach ($location in $all_jar_paths) {
    if (Test-Path $location) {
        Write-Log "  Scanning: $location"
        $jars = Get-ChildItem -Path $location -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 15
        
        foreach ($jar in $jars) {
            $jar_name = $jar.Name
            $jar_path = $jar.FullName
            
            # Check filename first
            $name_lower = $jar_name.ToLower()
            $found_filename = $false
            
            foreach ($cheat in $RED_STRINGS) {
                if ($name_lower -match [regex]::Escape($cheat.ToLower())) {
                    Write-Host "🚨 CHEAT JAR DETECTED: $jar_name" -ForegroundColor Red
                    Write-Host "   Location: $location" -ForegroundColor Red
                    Write-Log "🚨 CHEAT JAR: $jar_name"
                    Write-Log "   Signature in filename: $cheat"
                    Add-Finding "CRITICAL" "Cheat File" "$jar_name in $location (Signature: $cheat)"
                    $found_filename = $true
                    break
                }
            }
            
            # If filename check passed, check JAR contents for strings
            if (-not $found_filename) {
                Write-Host "  Checking strings in: $jar_name..." -ForegroundColor Cyan
                $found_strings = Find-StringsInJAR -JarPath $jar_path
                
                if ($found_strings.Count -gt 0) {
                    Write-Host "    🚨 CHEAT STRINGS FOUND IN JAR!" -ForegroundColor Red
                    Write-Log "🚨 Cheat strings found in: $jar_name"
                    
                    foreach ($string in $found_strings) {
                        Write-Host "      → $string" -ForegroundColor Red
                        Write-Log "      STRING FOUND: $string"
                    }
                    
                    Add-Finding "CRITICAL" "Cheat Strings" "$jar_name contains cheat signatures: $($found_strings -join ', ')"
                }
            }
        }
    }
}
Write-Log ""

# [10/16] Fullwidth Unicode Detection
Write-Host "[10/16] Checking for obfuscation..." -ForegroundColor Yellow
Write-Log "[10/16] OBFUSCATION DETECTION"
$mod_path = "$env:APPDATA\.minecraft\mods"
if (Test-Path $mod_path) {
    $jars = Get-ChildItem -Path $mod_path -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue
    foreach ($jar in $jars) {
        foreach ($pattern in $FULLWIDTH_PATTERNS) {
            if ($jar.Name -match [regex]::Escape($pattern)) {
                Write-Host "🚨 OBFUSCATED CHEAT: $($jar.Name)" -ForegroundColor Red
                Write-Log "🚨 Fullwidth obfuscation: $($jar.Name)"
                Add-Finding "CRITICAL" "Obfuscated Cheat" "$($jar.Name)"
            }
        }
    }
}
Write-Log ""

# [11/16] USB Device History
Write-Host "[11/16] Scanning USB device history..." -ForegroundColor Yellow
Write-Log "[11/16] USB DEVICE HISTORY"
try {
    $usbstor = "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR"
    if (Test-Path $usbstor) {
        $devices = Get-ChildItem $usbstor -ErrorAction SilentlyContinue
        if ($devices.Count -gt 0) {
            Write-Host "⚠ Found $($devices.Count) USB device(s) in history" -ForegroundColor Yellow
            Write-Log "⚠ USB history found:"
            foreach ($device in $devices | Select-Object -First 10) {
                Write-Log "  - $($device.PSChildName)"
            }
            Add-Finding "WARNING" "USB History" "$($devices.Count) devices connected"
        }
    }
} catch {}
Write-Log ""

# [12/16] Current USB Drives
Write-Host "[12/16] Checking connected USB drives..." -ForegroundColor Yellow
Write-Log "[12/16] CURRENT USB DRIVES"
try {
    $usb_drives = @(Get-Volume | Where-Object {$_.DriveType -eq "Removable"})
    if ($usb_drives.Count -gt 0) {
        Write-Host "⚠ Found $($usb_drives.Count) USB drive(s)" -ForegroundColor Yellow
        foreach ($usb in $usb_drives) {
            if ($usb.DriveLetter) {
                $usb_path = "$($usb.DriveLetter):\"
                $usb_jars = Get-ChildItem -Path $usb_path -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 5
                foreach ($jar in $usb_jars) {
                    Write-Host "  Checking USB JAR: $($jar.Name)..." -ForegroundColor Cyan
                    $found_usb = Find-StringsInJAR -JarPath $jar.FullName
                    
                    if ($found_usb.Count -gt 0) {
                        Write-Host "    🚨 CHEAT ON USB: $($jar.Name)" -ForegroundColor Red
                        Write-Log "    🚨 Cheat strings on USB: $($jar.Name)"
                        foreach ($str in $found_usb) {
                            Write-Host "      → $str" -ForegroundColor Red
                            Write-Log "      STRING: $str"
                        }
                        Add-Finding "CRITICAL" "USB Cheat" "$($jar.Name) on USB contains: $($found_usb -join ', ')"
                    }
                }
            }
        }
    }
} catch {}
Write-Log ""

# [13/16] Registry Tampering
Write-Host "[13/16] Checking registry..." -ForegroundColor Yellow
Write-Log "[13/16] REGISTRY ANALYSIS"
try {
    $checks = @(
        @{Path = "HKCU:\Software\Policies\Microsoft\Windows\System"; Name = "DisableCMD"},
        @{Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System"; Name = "DisableTaskMgr"}
    )
    foreach ($check in $checks) {
        $val = Get-ItemProperty -Path $check.Path -Name $check.Name -ErrorAction SilentlyContinue
        if ($val) {
            Write-Host "⚠ REGISTRY MODIFIED" -ForegroundColor Yellow
            Write-Log "⚠ Registry restriction: $($check.Name)"
            Add-Finding "WARNING" "Registry Tampering" "Security feature disabled"
        }
    }
} catch {}
Write-Log ""

# [14/16] Defender Exclusions
Write-Host "[14/16] Checking Defender exclusions..." -ForegroundColor Yellow
Write-Log "[14/16] WINDOWS DEFENDER"
try {
    $exclusions = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths" -ErrorAction SilentlyContinue
    if ($exclusions) {
        $exclusions.PSObject.Properties | Where-Object { $_.Name -notmatch "PS" } | ForEach-Object {
            if ($_.Value -match "minecraft|java|mods") {
                Write-Host "⚠ SUSPICIOUS EXCLUSION" -ForegroundColor Yellow
                Write-Log "⚠ Defender exclusion: $($_.Value)"
                Add-Finding "WARNING" "Defender Exclusion" "$($_.Value)"
            }
        }
    }
} catch {}
Write-Log ""

# [15/16] Memory Analysis
Write-Host "[15/16] Analyzing Java process memory..." -ForegroundColor Yellow
Write-Log "[15/16] PROCESS MEMORY ANALYSIS"
try {
    $wmi = Get-WmiObject Win32_Process | Where-Object { $_.ProcessName -match "java" }
    if ($wmi) {
        foreach ($proc in $wmi) {
            if ($proc.CommandLine -match "-javaagent|-Xbootclasspath|agentlib|noverify") {
                Write-Host "⚠ SUSPICIOUS JVM ARGUMENTS" -ForegroundColor Yellow
                Write-Log "⚠ JVM injection detected"
                Add-Finding "WARNING" "JVM Injection" "Suspicious JVM arguments found"
            }
        }
    }
} catch {}
Write-Log ""

# [16/16] Summary
Write-Host "[16/16] Generating final verdict..." -ForegroundColor Yellow
Write-Log ""
Write-Log "═════════════════════════════════════════════════════════"
Write-Log "FINAL FORENSIC ANALYSIS - v6.0 IMPROVED"
Write-Log "═════════════════════════════════════════════════════════"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   COMPLETE FORENSICS ANALYSIS FINISHED                 ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

Write-Host ""
Write-Host "Critical Findings: $critical_count" -ForegroundColor Red
Write-Host "Warnings:          $warn_count" -ForegroundColor Yellow

Write-Log "CRITICAL FINDINGS: $critical_count"
Write-Log "WARNINGS: $warn_count"

if ($findings.Count -gt 0) {
    Write-Host ""
    Write-Host "EVIDENCE:" -ForegroundColor Yellow
    foreach ($f in $findings) {
        $col = if ($f.Severity -eq "CRITICAL") { "Red" } else { "Yellow" }
        Write-Host "  [$($f.Severity)] $($f.Title)" -ForegroundColor $col
        Write-Host "    → $($f.Details)" -ForegroundColor Gray
        Write-Log "  [$($f.Severity)] $($f.Title): $($f.Details)"
    }
}

Write-Host ""
if ($critical_count -gt 0) {
    Write-Host "🚨 CHEAT EVIDENCE FOUND - RECOMMEND IMMEDIATE BAN!" -ForegroundColor Red
    Write-Log "🚨 CRITICAL EVIDENCE - RECOMMEND BAN"
} elseif ($warn_count -gt 2) {
    Write-Host "⚠ SUSPICIOUS ACTIVITY - FURTHER INVESTIGATION NEEDED" -ForegroundColor Yellow
    Write-Log "⚠ SUSPICIOUS - REVIEW RECOMMENDED"
} else {
    Write-Host "✓ NO EVIDENCE OF CHEATING - CLEAN SCAN" -ForegroundColor Green
    Write-Log "✓ CLEAN SCAN"
}

Write-Log ""
Write-Log "Report saved: $logfile"
Write-Host ""
Write-Host "📄 Report: $logfile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to open report..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

if (Test-Path $logfile) {
    Invoke-Item $logfile
}
