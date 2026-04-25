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
    "Wurst", "Impact", "Grim", "Liquidbounce", "Aristois", "Skliggahack",
    
    # PAID CHEATS
    "argon", "prestige", "virgin", "skyclient", "lunar", "konas",
    "pika", "azura", "sigma", "eternum", "raven", "zulu", "novoline",
    "ratpoison", "crimson", "killaura", "reach", "triggerbot"
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
    # obfuscation patterns
    "ＡｕｔｏＣｒｙｓｔａｌ", "Ａｕｔｏ Ｃｒｙｓｔａｌ",
    "ＡｕｔｏＡｎｃｈｏｒ", "Ａｕｔｏ Ａｎｃｈｏｒ",
    "ＤｏｕｂｌｅＡｎｃｈｏｒ", "ＡｕｔｏＴｏｔｅｍ", "ＨｏｖｅｒＴｏｔｅｍ",
    
    # obfuscation patterns (40+)
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
# ADVANCED FORENSIC FUNCTIONS

# USB CONNECT/DISCONNECT TIMELINE

# ═══════════════════════════════════════════════════════════════
# LEGITIMATE MOD WHITELIST
$LEGITIMATE_MODS = @(
    "sodium", "lithium", "phosphor", "starlight", "hydrogen",
    "feather", "c2me", "fabric", "optifine", "iris", "oculus",
    "mousewheelie", "inventory", "tweakeroo", "itemscroller",
    "multiconnect", "replay", "minihud", "baritone", "tweakmore",
    "cloth", "modmenu", "emi", "rei", "jei", "hwyla", "waila",
    "roughly-enough-items", "inventory-tweaks", "chat", "damage",
    "statuseffect", "hud", "zoom", "toggle", "autoclicker", "autotool",
    "autocraft", "fastcraft", "performant", "voxel", "volumetric",
    "continuity", "indium", "canvas", "canvas-renderer", "quilted",
    "cardinal", "architectury", "reach", "third-person", "camera",
    "minimap", "xaero", "mapwriter", "journeymap", "voxelmap",
    "flan", "grief", "protection", "anti-grief", "land-claim",
    "chat-control", "chat-mod", "communicator", "global-chat"
)

# ═══════════════════════════════════════════════════════════════
# DLL SCANNING FUNCTION - EXPANDED CHEAT DLL LIST
function Find-SuspiciousDLLs {
    param()
    
    $found_dlls = @()
    # ALL known cheat DLLs - EXPANDED LIST
    $known_cheat_dlls = @(
        # Free cheats
        "vape", "nova", "meteor", "wurst", "impact", "grim",
        "aristois", "liquidbounce", "riseclient", "doomsday",
        
        # Paid cheats
        "argon", "prestige", "virgin", "skyclient", "lunar",
        "konas", "pika", "azura", "sigma", "eternum",
        "raven", "zulu", "novoline", "ratpoison", "crimson",
        
        # General cheat keywords (specific)
        "cheatclient", "hackclient", "exploit", "injection",
        "clickbot", "autobot", "crystal", "anchor", "totem",
        "aura", "reach", "aim", "killaura", "triggerbot",
        
        # Injection loaders
        "loader", "launcher", "inject", "forge", "fabric"
    )
    
    try {
        # Check minecraft game directory
        $minecraft_path = "$env:APPDATA\.minecraft"
        if (Test-Path $minecraft_path) {
            $dlls = Get-ChildItem -Path $minecraft_path -Filter "*.dll" -Recurse -ErrorAction SilentlyContinue -Force
            
            foreach ($dll in $dlls) {
                # Skip legitimate Windows/Java DLLs
                if ($dll.FullName -match "\\Windows\\|\\System32\\|\\SysWOW64\\|jre\\|jdk\\") {
                    continue
                }
                
                $dll_name_lower = $dll.Name.ToLower()
                
                foreach ($keyword in $known_cheat_dlls) {
                    if ($dll_name_lower -match [regex]::Escape($keyword)) {
                        $found_dlls += @{
                            Filename = $dll.Name
                            Path = $dll.FullName
                            Size = $dll.Length
                            Created = $dll.CreationTime
                            Modified = $dll.LastWriteTime
                            Keyword = $keyword
                        }
                        break
                    }
                }
            }
        }
    } catch {}
    
    return $found_dlls
}

# ═══════════════════════════════════════════════════════════════
# REGISTRY CHEAT CONFIG DETECTION - STRICT MODE
function Find-CheatRegistryConfig {
    param()
    
    $cheat_configs = @()
    
    try {
        # ONLY search for KNOWN cheat client names
        $known_cheats = @(
            "vape", "nova", "meteor", "wurst", "impact", "grim",
            "riseclient", "doomsday", "aristois", "liquidbounce"
        )
        
        $reg_path = "HKCU:\Software\"
        
        try {
            $items = Get-ChildItem -Path $reg_path -ErrorAction SilentlyContinue -Force
            
            foreach ($item in $items) {
                $item_name_lower = $item.PSChildName.ToLower()
                
                foreach ($cheat in $known_cheats) {
                    if ($item_name_lower -match [regex]::Escape($cheat)) {
                        $cheat_configs += @{
                            Name = $item.PSChildName
                            Path = $item.PSPath
                            Type = "Registry Key"
                            Cheat = $cheat
                        }
                        break
                    }
                }
            }
        } catch {}
    } catch {}
    
    return $cheat_configs
}

# ═══════════════════════════════════════════════════════════════
# NETWORK CONNECTION DETECTION - STRICT MODE
function Get-CheatNetworkConnections {
    param()
    
    $suspicious_ips = @()
    # ONLY known cheat server domains
    $known_cheat_domains = @(
        "vape\.gg", "api\.novaclient", "rise\.today", "intent\.store",
        "doomsday", "lunarapi", "aristois", "liquidbounce",
        "riseclient", "riseclient\.com"
    )
    
    try {
        # Get active network connections
        $connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
        
        foreach ($conn in $connections) {
            try {
                # Try to resolve hostname
                $hostname = [System.Net.Dns]::GetHostEntry($conn.RemoteAddress).HostName
                
                if ($hostname) {
                    $hostname_lower = $hostname.ToLower()
                    
                    foreach ($domain in $known_cheat_domains) {
                        if ($hostname_lower -match $domain) {
                            $suspicious_ips += @{
                                RemoteIP = $conn.RemoteAddress
                                RemotePort = $conn.RemotePort
                                Hostname = $hostname
                                State = $conn.State
                                OwningProcess = $conn.OwningProcess
                            }
                            break
                        }
                    }
                }
            } catch {}
        }
    } catch {}
    
    return $suspicious_ips
}

# ═══════════════════════════════════════════════════════════════
# GAME FILE INTEGRITY CHECK
function Check-MinecraftFileIntegrity {
    param()
    
    $integrity_issues = @()
    $minecraft_path = "$env:APPDATA\.minecraft"
    
    try {
        # Check for modified game JARs
        $bin_path = "$minecraft_path\bin"
        if (Test-Path $bin_path) {
            $jars = Get-ChildItem -Path $bin_path -Filter "*.jar" -ErrorAction SilentlyContinue
            
            foreach ($jar in $jars) {
                # Check file signature/properties
                $now = Get-Date
                $days_old = ($now - $jar.LastWriteTime).Days
                
                # Legitimate game files shouldn't be modified recently
                if ($days_old -lt 7 -and $jar.Length -gt 50MB) {
                    $integrity_issues += @{
                        Filename = $jar.Name
                        Path = $jar.FullName
                        Size = $jar.Length
                        Modified = $jar.LastWriteTime
                        DaysOld = $days_old
                        Issue = "Recently modified JAR in bin folder"
                    }
                }
            }
        }
        
        # Check for suspicious DLL files in game directory
        $dlls = Get-ChildItem -Path $minecraft_path -Filter "*.dll" -Recurse -ErrorAction SilentlyContinue
        if ($dlls.Count -gt 0) {
            foreach ($dll in $dlls) {
                $integrity_issues += @{
                    Filename = $dll.Name
                    Path = $dll.FullName
                    Size = $dll.Length
                    Modified = $dll.LastWriteTime
                    Issue = "Suspicious DLL in game folder"
                }
            }
        }
    } catch {}
    
    return $integrity_issues
}

# ═══════════════════════════════════════════════════════════════
# SCREEN RECORDING SOFTWARE DETECTION
function Find-ScreenRecordingSoftware {
    param()
    
    $recording_software = @()
    
    $recording_software_paths = @(
        @{Name = "OBS Studio"; Path = "C:\Program Files\obs-studio"},
        @{Name = "OBS Studio (x86)"; Path = "C:\Program Files (x86)\obs-studio"},
        @{Name = "Bandicam"; Path = "C:\Program Files\Bandicam"},
        @{Name = "Bandicam (x86)"; Path = "C:\Program Files (x86)\Bandicam"},
        @{Name = "Fraps"; Path = "C:\Program Files\Fraps"},
        @{Name = "Fraps (x86)"; Path = "C:\Program Files (x86)\Fraps"},
        @{Name = "ShareX"; Path = "C:\Program Files\ShareX"},
        @{Name = "FFmpeg"; Path = "C:\Program Files\ffmpeg"},
        @{Name = "VLC Media Player"; Path = "C:\Program Files\VideoLAN"},
        @{Name = "Nvidia ShadowPlay"; Path = "C:\Program Files\NVIDIA Corporation"},
        @{Name = "AMD ReLive"; Path = "C:\Program Files\AMD"},
        @{Name = "ScreenFlow"; Path = "C:\Program Files\Telestream"}
    )
    
    try {
        foreach ($software in $recording_software_paths) {
            if (Test-Path $software.Path) {
                $exes = Get-ChildItem -Path $software.Path -Filter "*.exe" -ErrorAction SilentlyContinue
                
                if ($exes.Count -gt 0) {
                    $recording_software += @{
                        Name = $software.Name
                        Path = $software.Path
                        ExecutableCount = $exes.Count
                        Installed = $true
                        Modified = (Get-Item $software.Path).LastWriteTime
                    }
                }
            }
        }
    } catch {}
    
    return $recording_software
}


# ═══════════════════════════════════════════════════════════════
# MACRO DETECTION FUNCTION - STRICT MODE
function Find-SuspiciousMacros {
    param()
    
    $found_macros = @()
    
    # ONLY specific cheat macro keywords - NO legitimate automation tools
    $cheat_macro_keywords = @(
        "1.8 macro", "1.8.9", "clickbot", "crystal click", "crystal bot",
        "minecraft macro", "minecraft bot", "autoclick minecraft",
        "crystal aura", "crystal clicker", "autoclicker minecraft"
    )
    
    # Macro file extensions
    $macro_extensions = @("*.ahk", "*.lua")
    
    # Search in suspicious locations (OUTSIDE game folder)
    $search_locations = @(
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Documents"
    )
    
    try {
        # Search for macro files
        foreach ($location in $search_locations) {
            if (Test-Path $location) {
                foreach ($extension in $macro_extensions) {
                    try {
                        $files = Get-ChildItem -Path $location -Filter $extension -Recurse -ErrorAction SilentlyContinue -Force
                        
                        foreach ($file in $files) {
                            try {
                                $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
                                $is_cheat_macro = $false
                                $matched_keywords = @()
                                
                                # Check content for CHEAT macro keywords only
                                foreach ($keyword in $cheat_macro_keywords) {
                                    if ($content -match [regex]::Escape($keyword)) {
                                        $is_cheat_macro = $true
                                        $matched_keywords += $keyword
                                    }
                                }
                                
                                if ($is_cheat_macro) {
                                    $found_macros += @{
                                        Filename = $file.Name
                                        Path = $file.FullName
                                        Extension = $file.Extension
                                        Size = $file.Length
                                        Created = $file.CreationTime
                                        Modified = $file.LastWriteTime
                                        Keywords = $matched_keywords -join ", "
                                        Location = $location
                                    }
                                }
                            } catch {}
                        }
                    } catch {}
                }
            }
        }
    } catch {}
    
    return $found_macros
}

function Get-USBConnectionTimeline {
    param()
    
    $timeline = @()
    
    try {
        # Check Windows Setup API logs for USB events
        $setupapi_log = "C:\Windows\inf\setupapi.dev.log"
        if (Test-Path $setupapi_log) {
            $content = Get-Content $setupapi_log -Tail 500 | Where-Object { $_ -match "usb" }
            
            foreach ($line in $content) {
                if ($line -match "(\d{2}:\d{2}:\d{2}).*usb.*present|removed|discovered" -or 
                    $line -match "USB.*Device|Device.*USB") {
                    $timeline += $line
                }
            }
        }
        
        # Check USB registry for last connection time
        $usbstor = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR" -ErrorAction SilentlyContinue
        if ($usbstor) {
            foreach ($device in Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR" -ErrorAction SilentlyContinue) {
                $device_name = $device.PSChildName
                $timeline += "USB Device: $device_name"
            }
        }
    } catch {}
    
    return $timeline
}

# POWERSHELL COMMAND HISTORY ANALYSIS
function Get-SuspiciousPSCommands {
    param()
    
    $suspicious = @()
    $history_file = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
    
    try {
        if (Test-Path $history_file) {
            $commands = Get-Content $history_file -ErrorAction SilentlyContinue
            
            # Keywords indicating file movement/deletion to USB
            $suspicious_patterns = @(
                "Move-Item.*[a-z]:\\",      # Move to drive
                "Copy-Item.*[a-z]:\\",      # Copy to drive
                "Remove-Item",              # Delete
                "del ",                     # DOS delete
                "rm ",                      # Unix delete
                "robocopy.*usb",            # Copy to USB
                "move.*usb",                # Move to USB
                "copy.*usb",                # Copy to USB
                "xcopy.*usb",               # XCopy to USB
                ">",                        # Redirection (copy)
                "Clear-RecycleBin",         # Clear recycle
                "Empty-RecycleBin"          # Empty recycle
            )
            
            foreach ($cmd in $commands) {
                foreach ($pattern in $suspicious_patterns) {
                    if ($cmd -match $pattern) {
                        $suspicious += @{
                            Command = $cmd
                            Pattern = $pattern
                            Time = "Unknown"  # Can't extract from history file easily
                        }
                    }
                }
            }
        }
    } catch {}
    
    return $suspicious
}

# RECYCLE BIN DETAILED FORENSICS
function Get-RecycleBinForensics {
    param()
    
    $recycle_data = @{
        DeletedCheats = @()
        DeletedJARs = @()
        TotalDeleted = 0
        SuspiciousPattern = $false
    }
    
    try {
        $recycle_bin = "$env:SystemDrive\`$Recycle.Bin"
        if (Test-Path $recycle_bin) {
            $deleted_items = Get-ChildItem -LiteralPath $recycle_bin -File -Force -Recurse -ErrorAction SilentlyContinue
            
            $recycle_data.TotalDeleted = $deleted_items.Count
            
            foreach ($item in $deleted_items) {
                # Check for JAR files
                if ($item.Name -match "\.jar$") {
                    $recycle_data.DeletedJARs += @{
                        Name = $item.Name
                        Path = $item.FullName
                        DeletedTime = $item.LastWriteTime
                        Size = $item.Length
                    }
                    
                    # Check if it's a cheat
                    foreach ($cheat in $RED_STRINGS) {
                        if ($item.Name -match [regex]::Escape($cheat)) {
                            $recycle_data.DeletedCheats += @{
                                Name = $item.Name
                                Cheat = $cheat
                                DeletedTime = $item.LastWriteTime
                            }
                        }
                    }
                }
            }
            
            # Check for suspicious deletion pattern (many files deleted recently)
            $now = Get-Date
            $last_hour = $now.AddHours(-1)
            $recent_deletes = @($deleted_items | Where-Object { $_.LastWriteTime -gt $last_hour })
            
            if ($recent_deletes.Count -gt 5) {
                $recycle_data.SuspiciousPattern = $true
            }
        }
    } catch {}
    
    return $recycle_data
}

# RECYCLE BIN RESTORATION HISTORY
function Get-RecycleBinRestoreHistory {
    param()
    
    $restore_history = @()
    
    try {
        # Check for recycle bin info files
        $recycle_bin = "$env:SystemDrive\`$Recycle.Bin"
        if (Test-Path $recycle_bin) {
            # Look for INFO2 file which stores deletion history
            $info_files = Get-ChildItem -LiteralPath $recycle_bin -Filter "INFO2" -Force -ErrorAction SilentlyContinue
            
            if ($info_files) {
                $restore_history += "Recycle bin INFO file found - contains deletion history"
            }
            
            # Check file timestamps to infer restoration attempts
            $bin_files = Get-ChildItem -LiteralPath $recycle_bin -File -Force -ErrorAction SilentlyContinue
            $now = Get-Date
            $last_hour = $now.AddHours(-1)
            
            $recent_changes = @($bin_files | Where-Object { $_.LastWriteTime -gt $last_hour })
            if ($recent_changes.Count -gt 0) {
                $restore_history += "Recycle bin recently modified ($($recent_changes.Count) items)"
            }
        }
    } catch {}
    
    return $restore_history
}

# USB DEVICE FILE LISTING
function Get-USBFileList {
    param()
    
    $usb_files = @()
    
    try {
        $usb_drives = @(Get-Volume | Where-Object {$_.DriveType -eq "Removable"})
        
        foreach ($usb in $usb_drives) {
            if ($usb.DriveLetter) {
                $usb_path = "$($usb.DriveLetter):\"
                
                # Get all files on USB with timestamps
                $files = Get-ChildItem -Path $usb_path -File -Recurse -ErrorAction SilentlyContinue | 
                         Select-Object Name, FullName, LastWriteTime, Length
                
                foreach ($file in $files) {
                    $usb_files += @{
                        Filename = $file.Name
                        Path = $file.FullName
                        USB = $usb_path
                        LastModified = $file.LastWriteTime
                        Size = $file.Length
                    }
                }
            }
        }
    } catch {}
    
    return $usb_files
}
function Check-USBJARMovement {
    param()
    
    $suspicious_moves = @()
    
    try {
        # Get all USB drives
        $usb_drives = @(Get-Volume | Where-Object {$_.DriveType -eq "Removable"})
        
        if ($usb_drives.Count -gt 0) {
            foreach ($usb in $usb_drives) {
                if ($usb.DriveLetter) {
                    $usb_path = "$($usb.DriveLetter):\"
                    
                    # Get all JARs on USB with timestamps
                    $usb_jars = Get-ChildItem -Path $usb_path -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue | 
                                Select-Object FullName, Name, LastWriteTime, Length
                    
                    # Check for recent JAR files (within last 24 hours)
                    $now = Get-Date
                    $yesterday = $now.AddHours(-24)
                    
                    foreach ($jar in $usb_jars) {
                        # Check if JAR was recently added to USB
                        if ($jar.LastWriteTime -gt $yesterday) {
                            $time_diff = $now - $jar.LastWriteTime
                            
                            $suspicious_moves += @{
                                Filename = $jar.Name
                                Path = $jar.FullName
                                USB = $usb_path
                                LastModified = $jar.LastWriteTime
                                RecentHours = [math]::Round($time_diff.TotalHours, 1)
                                Size = $jar.Length
                            }
                        }
                    }
                }
            }
        }
    } catch {}
    
    return $suspicious_moves
}
function Check-ModrinthMod {
    param([string]$JarPath, [string]$ModName)
    
    $results = @{
        Found = $false
        Official = $false
        VersionMatch = $false
        SizeMatch = $false
        FileMatch = $false
        Tampered = $false
        Suspicious = $false
        Details = @()
    }
    
    try {
        # Get JAR file properties
        $jar_size = (Get-Item $JarPath).Length
        $jar_filename = Split-Path $JarPath -Leaf
        
        # Calculate file hash for tamper detection
        $jar_hash = (Get-FileHash -Path $JarPath -Algorithm SHA256 -ErrorAction SilentlyContinue).Hash
        
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
                                $official_hash = $file.hashes.sha256  # Get official hash if available
                                
                                # HASH VERIFICATION - Most reliable tamper detection
                                if ($official_hash -and $jar_hash) {
                                    if ($jar_hash -eq $official_hash) {
                                        $results.SizeMatch = $true
                                        $results.Details += "✓ Hash verified: File matches official"
                                    } else {
                                        $results.Tampered = $true
                                        $results.Suspicious = $true
                                        $results.Details += "🚨 HASH MISMATCH: File has been TAMPERED/MODIFIED"
                                        break
                                    }
                                } else {
                                    # SIZE-BASED VERIFICATION (fallback if no hash)
                                    $size_variance = [math]::Abs($jar_size - $official_size)
                                    $size_percent = ($size_variance / $official_size) * 100
                                    
                                    # Stricter size checking - tampered mods usually have >10% difference
                                    if ($size_percent -lt 2) {
                                        $results.SizeMatch = $true
                                        $results.Details += "Size match: $jar_size bytes (official: $official_size bytes)"
                                    } elseif ($size_percent -lt 5) {
                                        $results.Details += "⚠ SIZE VARIANCE: $jar_size bytes vs official $official_size bytes ($([math]::Round($size_percent, 2))%)"
                                    } else {
                                        $results.Tampered = $true
                                        $results.Suspicious = $true
                                        $results.Details += "🚨 TAMPERED MOD: Size mismatch $jar_size vs $official_size bytes ($([math]::Round($size_percent, 2))% different) - FILE HAS BEEN MODIFIED"
                                    }
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
$java_proc = Get-Process | Where-Object {$_.ProcessName -match "java"}
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
        $deleted = Get-ChildItem -LiteralPath $recycle -File -Force -Recurse
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

# [7/20] Prefetch Execution
Write-Host "[7/20] Analyzing prefetch execution..." -ForegroundColor Yellow
Write-Log "[7/20] PREFETCH EXECUTION HISTORY"
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

# [8/20] USB CONNECTION TIMELINE
Write-Host "[8/20] Analyzing USB connection timeline..." -ForegroundColor Yellow
Write-Log "[8/20] USB CONNECTION/DISCONNECTION HISTORY"

$usb_timeline = Get-USBConnectionTimeline
if ($usb_timeline.Count -gt 0) {
    Write-Host "⚠ USB connection history detected" -ForegroundColor Yellow
    Write-Log "⚠ USB Timeline Events:"
    foreach ($event in $usb_timeline) {
        Write-Log "  - $event"
        if ($event -match "removed|disconnect" -and (Get-Date).AddMinutes(-30) -lt (Get-Date)) {
            Write-Host "  ⚠ USB DISCONNECTED RECENTLY!" -ForegroundColor Red
            Add-Finding "WARNING" "USB Timing" "USB was disconnected during/before screenshare"
        }
    }
}
Write-Log ""

# [9/20] POWERSHELL COMMAND ANALYSIS
Write-Host "[9/20] Analyzing PowerShell command history..." -ForegroundColor Yellow
Write-Log "[9/20] POWERSHELL COMMAND FORENSICS"

$suspicious_commands = Get-SuspiciousPSCommands
if ($suspicious_commands.Count -gt 0) {
    Write-Host "🚨 FOUND SUSPICIOUS POWERSHELL COMMANDS!" -ForegroundColor Red
    Write-Log "🚨 SUSPICIOUS POWERSHELL COMMANDS DETECTED:"
    
    foreach ($cmd in $suspicious_commands) {
        Write-Host "  Command: $($cmd.Command)" -ForegroundColor Red
        Write-Host "    Pattern: $($cmd.Pattern)" -ForegroundColor Yellow
        Write-Log "  COMMAND: $($cmd.Command)"
        Write-Log "    PATTERN: $($cmd.Pattern)"
        
        if ($cmd.Command -match "Move-Item|Copy-Item|robocopy|xcopy" -and $cmd.Command -match "[a-z]:\\") {
            Add-Finding "CRITICAL" "File Movement Command" "PowerShell command detected: $($cmd.Command)"
        } elseif ($cmd.Command -match "Remove-Item|del |Clear-RecycleBin|Empty-RecycleBin") {
            Add-Finding "WARNING" "File Deletion Command" "PowerShell command detected: $($cmd.Command)"
        }
    }
} else {
    Write-Host "✓ No suspicious PowerShell commands" -ForegroundColor Green
    Write-Log "✓ PowerShell history clean"
}
Write-Log ""

# [10/20] RECYCLE BIN FORENSICS
Write-Host "[10/20] Deep analyzing Recycle Bin..." -ForegroundColor Yellow
Write-Log "[10/20] RECYCLE BIN FORENSIC ANALYSIS"

$recycle_forensics = Get-RecycleBinForensics

if ($recycle_forensics.DeletedCheats.Count -gt 0) {
    Write-Host "🚨 FOUND DELETED CHEATS IN RECYCLE BIN!" -ForegroundColor Red
    Write-Log "🚨 DELETED CHEAT FILES:"
    
    foreach ($cheat in $recycle_forensics.DeletedCheats) {
        Write-Host "  🚨 Deleted: $($cheat.Name)" -ForegroundColor Red
        Write-Host "    Matches: $($cheat.Cheat)" -ForegroundColor Red
        Write-Host "    Deleted Time: $($cheat.DeletedTime)" -ForegroundColor Yellow
        Write-Log "  DELETED CHEAT: $($cheat.Name)"
        Write-Log "    SIGNATURE: $($cheat.Cheat)"
        Write-Log "    TIME: $($cheat.DeletedTime)"
        Add-Finding "CRITICAL" "Deleted Cheat Evidence" "$($cheat.Name) was deleted (found in Recycle Bin)"
    }
}

if ($recycle_forensics.DeletedJARs.Count -gt 0) {
    Write-Host "⚠ Found $($recycle_forensics.DeletedJARs.Count) deleted JAR file(s)" -ForegroundColor Yellow
    Write-Log "⚠ DELETED JAR FILES:"
    foreach ($jar in $recycle_forensics.DeletedJARs) {
        Write-Host "  - $($jar.Name) (Deleted: $($jar.DeletedTime))" -ForegroundColor Yellow
        Write-Log "  JAR: $($jar.Name) - Size: $($jar.Size) bytes"
    }
}

if ($recycle_forensics.SuspiciousPattern) {
    Write-Host "🚨 SUSPICIOUS DELETION PATTERN!" -ForegroundColor Red
    Write-Host "  Many files deleted in last hour - possible cover-up!" -ForegroundColor Red
    Write-Log "🚨 SUSPICIOUS DELETION PATTERN: $($recycle_forensics.TotalDeleted) items in Recycle Bin"
    Add-Finding "CRITICAL" "Mass Deletion" "Multiple files deleted recently (cover-up attempt)"
}

Write-Log "  Total items in Recycle Bin: $($recycle_forensics.TotalDeleted)"
Write-Log ""

# [11/20] RECYCLE BIN RESTORATION HISTORY
Write-Host "[11/20] Checking Recycle Bin history..." -ForegroundColor Yellow
Write-Log "[11/20] RECYCLE BIN RESTORE HISTORY"

$restore_history = Get-RecycleBinRestoreHistory
if ($restore_history.Count -gt 0) {
    Write-Host "⚠ Recycle Bin history detected:" -ForegroundColor Yellow
    Write-Log "⚠ Recycle Bin History:"
    foreach ($event in $restore_history) {
        Write-Host "  - $event" -ForegroundColor Yellow
        Write-Log "  - $event"
    }
}
Write-Log ""

# [12/20] USB FILE LISTING
Write-Host "[12/20] Cataloging USB file contents..." -ForegroundColor Yellow
Write-Log "[12/20] USB FILE INVENTORY"

$usb_file_list = Get-USBFileList
if ($usb_file_list.Count -gt 0) {
    Write-Host "Files found on USB:" -ForegroundColor Yellow
    Write-Log "USB File List:"
    foreach ($file in $usb_file_list) {
        Write-Host "  $($file.Filename) - Modified: $($file.LastModified)" -ForegroundColor Cyan
        Write-Log "  FILE: $($file.Filename)"
        Write-Log "    PATH: $($file.Path)"
        Write-Log "    SIZE: $($file.Size) bytes"
        Write-Log "    TIME: $($file.LastModified)"
    }
}
Write-Log ""

# [13/20] Modrinth Mod Verification
Write-Host "[8/16] Verifying mods with Modrinth..." -ForegroundColor Yellow
Write-Log "[8/16] MODRINTH MOD VERIFICATION"

$all_jar_paths = @($default_path) + $CUSTOM_MOD_PATHS
$jar_locations = @("$env:TEMP", "$env:USERPROFILE\Downloads")
$all_jar_paths += $jar_locations

foreach ($location in $all_jar_paths) {
    if (Test-Path $location) {
        Write-Log "  Verifying mods in: $location"
        $jars = Get-ChildItem -Path $location -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue
        
        foreach ($jar in $jars) {
            $mod_name = $jar.Name -replace '\.jar$', ''
            Write-Host "  Checking: $($jar.Name)..." -ForegroundColor Cyan
            
            $modrinth_check = Check-ModrinthMod -JarPath $jar.FullName -ModName $mod_name
            
            # FLAG TAMPERED MODS
            if ($modrinth_check.Tampered) {
                Write-Host "    🚨 TAMPERED/MODIFIED MOD DETECTED!\" -ForegroundColor Red
                foreach ($detail in $modrinth_check.Details) {
                    Write-Host "      → $detail" -ForegroundColor Red
                    Write-Log "      $detail"
                }
                Add-Finding "CRITICAL" "Tampered Mod" "$($jar.Name) - Modified from official Modrinth version (hash/size mismatch)"
            } elseif ($modrinth_check.Suspicious) {
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
        $jars = Get-ChildItem -Path $location -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue
        
        foreach ($jar in $jars) {
            $jar_name = $jar.Name
            $jar_path = $jar.FullName
            
            # Check if this is a legitimate mod - SKIP if it is
            $is_legitimate_mod = $false
            $name_lower = $jar_name.ToLower()
            
            foreach ($legit_mod in $LEGITIMATE_MODS) {
                if ($name_lower -match [regex]::Escape($legit_mod)) {
                    $is_legitimate_mod = $true
                    break
                }
            }
            
            # Skip legitimate mods
            if ($is_legitimate_mod) {
                continue
            }
            
            # Check filename first
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
            foreach ($device in $devices) {
                Write-Log "  - $($device.PSChildName)"
            }
            Add-Finding "WARNING" "USB History" "$($devices.Count) devices connected"
        }
    }
} catch {}
Write-Log ""

# [12/17] Current USB Drives
Write-Host "[12/17] Checking connected USB drives..." -ForegroundColor Yellow
Write-Log "[12/17] CURRENT USB DRIVES"
try {
    $usb_drives = @(Get-Volume | Where-Object {$_.DriveType -eq "Removable"})
    if ($usb_drives.Count -gt 0) {
        Write-Host "⚠ Found $($usb_drives.Count) USB drive(s)" -ForegroundColor Yellow
        foreach ($usb in $usb_drives) {
            if ($usb.DriveLetter) {
                $usb_path = "$($usb.DriveLetter):\"
                $usb_jars = Get-ChildItem -Path $usb_path -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue
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

# [13/17] USB JAR MOVEMENT DETECTION - Recently Added Files
Write-Host "[13/17] Detecting JAR files moved to USB..." -ForegroundColor Yellow
Write-Log "[13/17] USB JAR MOVEMENT DETECTION"

$recent_usb_jars = Check-USBJARMovement

if ($recent_usb_jars.Count -gt 0) {
    Write-Host "🚨 Found $($recent_usb_jars.Count) recent JAR file(s) on USB!" -ForegroundColor Red
    Write-Log "🚨 SUSPICIOUS USB JAR MOVEMENT DETECTED"
    
    foreach ($jar_move in $recent_usb_jars) {
        Write-Host "  🚨 RECENT JAR ON USB: $($jar_move.Filename)" -ForegroundColor Red
        Write-Host "    Location: $($jar_move.USB)" -ForegroundColor Red
        Write-Host "    Added: $($jar_move.RecentHours) hours ago" -ForegroundColor Red
        Write-Host "    Size: $($jar_move.Size) bytes" -ForegroundColor Red
        Write-Log "  RECENT JAR: $($jar_move.Filename) - Added $($jar_move.RecentHours) hours ago"
        Write-Log "  Location: $($jar_move.USB)"
        
        # Check if it matches a cheat signature
        $filename_lower = $jar_move.Filename.ToLower()
        $is_cheat = $false
        
        foreach ($cheat in $RED_STRINGS) {
            if ($filename_lower -match [regex]::Escape($cheat.ToLower())) {
                Write-Host "    → CHEAT SIGNATURE MATCH: $cheat" -ForegroundColor Red
                Write-Log "    → Matches cheat: $cheat"
                $is_cheat = $true
            }
        }
        
        if ($is_cheat) {
            Add-Finding "CRITICAL" "JAR Moved to USB" "$($jar_move.Filename) recently moved to USB (attempted escape)"
        } else {
            Add-Finding "WARNING" "Suspicious USB Activity" "$($jar_move.Filename) recently added to USB ($($jar_move.RecentHours) hours ago)"
        }
    }
} else {
    Write-Host "✓ No recent JAR files on USB" -ForegroundColor Green
    Write-Log "✓ No suspicious USB JAR movement detected"
}
Write-Log ""

# [15/17] Registry Tampering
Write-Host "[14/17] Checking registry..." -ForegroundColor Yellow
Write-Log "[14/17] REGISTRY ANALYSIS"
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

# [15/17] Defender Exclusions
Write-Host "[15/17] Checking Defender exclusions..." -ForegroundColor Yellow
Write-Log "[15/17] WINDOWS DEFENDER"
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

# [16/17] Memory Analysis
Write-Host "[16/17] Analyzing Java process memory..." -ForegroundColor Yellow
Write-Log "[16/17] PROCESS MEMORY ANALYSIS"
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

# [23/26] Summary


# [17/26] MACRO DETECTION
Write-Host "[17/26] Scanning for macro files and macro software..." -ForegroundColor Yellow
Write-Log "[17/26] MACRO FILE & SOFTWARE DETECTION"

$found_macros = Find-SuspiciousMacros

if ($found_macros.Count -gt 0) {
    Write-Host "🚨 FOUND SUSPICIOUS MACROS!" -ForegroundColor Red
    Write-Log "🚨 MACRO FILES DETECTED:"
    
    foreach ($macro in $found_macros) {
        Write-Host "  🚨 MACRO: $($macro.Filename)" -ForegroundColor Red
        Write-Host "    Path: $($macro.Path)" -ForegroundColor Red
        Write-Host "    Type: $($macro.Extension)" -ForegroundColor Yellow
        Write-Host "    Keywords: $($macro.Keywords)" -ForegroundColor Yellow
        Write-Host "    Modified: $($macro.Modified)" -ForegroundColor Cyan
        Write-Log "  MACRO: $($macro.Filename)"
        Write-Log "    PATH: $($macro.Path)"
        Write-Log "    TYPE: $($macro.Extension)"
        Write-Log "    KEYWORDS: $($macro.Keywords)"
        Write-Log "    MODIFIED: $($macro.Modified)"
        
        Add-Finding "CRITICAL" "Macro File Detected" "$($macro.Filename) - Keywords: $($macro.Keywords)"
    }
} else {
    Write-Host "✓ No suspicious macro files found" -ForegroundColor Green
    Write-Log "✓ No macro files or macro software detected"
}
Write-Log ""

# [23/26] Generating final verdict...

# [18/26] DLL INJECTION SCANNING
Write-Host "[18/26] Scanning for suspicious DLL files..." -ForegroundColor Yellow
Write-Log "[18/26] DLL INJECTION DETECTION"

$found_dlls = Find-SuspiciousDLLs

if ($found_dlls.Count -gt 0) {
    Write-Host "🚨 FOUND SUSPICIOUS DLLs!" -ForegroundColor Red
    Write-Log "🚨 SUSPICIOUS DLLs DETECTED:"
    
    foreach ($dll in $found_dlls) {
        Write-Host "  🚨 DLL: $($dll.Filename)" -ForegroundColor Red
        Write-Host "    Path: $($dll.Path)" -ForegroundColor Red
        Write-Host "    Keyword Match: $($dll.Keyword)" -ForegroundColor Yellow
        Write-Host "    Size: $($dll.Size) bytes" -ForegroundColor Cyan
        Write-Host "    Modified: $($dll.Modified)" -ForegroundColor Cyan
        Write-Log "  DLL: $($dll.Filename)"
        Write-Log "    PATH: $($dll.Path)"
        Write-Log "    KEYWORD: $($dll.Keyword)"
        Write-Log "    SIZE: $($dll.Size)"
        Write-Log "    MODIFIED: $($dll.Modified)"
        
        Add-Finding "CRITICAL" "DLL Injection" "$($dll.Filename) - Keyword: $($dll.Keyword)"
    }
} else {
    Write-Host "✓ No suspicious DLLs found" -ForegroundColor Green
    Write-Log "✓ No cheat DLLs detected"
}
Write-Log ""

# [19/26] REGISTRY CHEAT CONFIG
Write-Host "[19/26] Scanning registry for cheat configs..." -ForegroundColor Yellow
Write-Log "[19/26] REGISTRY CHEAT CONFIG DETECTION"

$cheat_configs = Find-CheatRegistryConfig

if ($cheat_configs.Count -gt 0) {
    Write-Host "🚨 FOUND CHEAT REGISTRY CONFIGS!" -ForegroundColor Red
    Write-Log "🚨 CHEAT REGISTRY KEYS:"
    
    foreach ($config in $cheat_configs) {
        Write-Host "  🚨 Registry Key: $($config.Name)" -ForegroundColor Red
        Write-Host "    Path: $($config.Path)" -ForegroundColor Red
        Write-Log "  KEY: $($config.Name)"
        Write-Log "    PATH: $($config.Path)"
        
        Add-Finding "CRITICAL" "Registry Config" "$($config.Name) - Cheat configuration found"
    }
} else {
    Write-Host "✓ No cheat registry configs found" -ForegroundColor Green
    Write-Log "✓ No cheat registry configurations"
}
Write-Log ""

# [20/26] NETWORK CHEAT CONNECTIONS
Write-Host "[20/26] Analyzing network connections..." -ForegroundColor Yellow
Write-Log "[20/26] NETWORK CHEAT SERVER DETECTION"

$cheat_connections = Get-CheatNetworkConnections

if ($cheat_connections.Count -gt 0) {
    Write-Host "🚨 FOUND CHEAT SERVER CONNECTIONS!" -ForegroundColor Red
    Write-Log "🚨 SUSPICIOUS NETWORK CONNECTIONS:"
    
    foreach ($conn in $cheat_connections) {
        Write-Host "  🚨 Connection to: $($conn.Hostname)" -ForegroundColor Red
        Write-Host "    IP: $($conn.RemoteIP):$($conn.RemotePort)" -ForegroundColor Red
        Write-Host "    Process: $($conn.OwningProcess)" -ForegroundColor Yellow
        Write-Log "  HOSTNAME: $($conn.Hostname)"
        Write-Log "    IP:PORT: $($conn.RemoteIP):$($conn.RemotePort)"
        Write-Log "    PROCESS: $($conn.OwningProcess)"
        
        Add-Finding "CRITICAL" "Cheat Server Connection" "$($conn.Hostname) - Active connection to cheat server"
    }
} else {
    Write-Host "✓ No cheat server connections found" -ForegroundColor Green
    Write-Log "✓ No suspicious network connections"
}
Write-Log ""

# [21/26] GAME FILE INTEGRITY
Write-Host "[21/26] Checking Minecraft file integrity..." -ForegroundColor Yellow
Write-Log "[21/26] GAME FILE INTEGRITY CHECK"

$integrity_issues = Check-MinecraftFileIntegrity

if ($integrity_issues.Count -gt 0) {
    Write-Host "🚨 FOUND GAME FILE MODIFICATIONS!" -ForegroundColor Red
    Write-Log "🚨 GAME FILE INTEGRITY ISSUES:"
    
    foreach ($issue in $integrity_issues) {
        Write-Host "  🚨 Issue: $($issue.Issue)" -ForegroundColor Red
        Write-Host "    File: $($issue.Filename)" -ForegroundColor Red
        Write-Host "    Size: $($issue.Size) bytes" -ForegroundColor Yellow
        Write-Host "    Modified: $($issue.Modified)" -ForegroundColor Yellow
        Write-Log "  FILE: $($issue.Filename)"
        Write-Log "    ISSUE: $($issue.Issue)"
        Write-Log "    SIZE: $($issue.Size)"
        Write-Log "    MODIFIED: $($issue.Modified)"
        
        Add-Finding "CRITICAL" "File Integrity" "$($issue.Filename) - $($issue.Issue)"
    }
} else {
    Write-Host "✓ Game files integrity verified" -ForegroundColor Green
    Write-Log "✓ No game file modifications detected"
}
Write-Log ""

# [22/26] SCREEN RECORDING SOFTWARE
Write-Host "[22/26] Scanning for screen recording software..." -ForegroundColor Yellow
Write-Log "[22/26] SCREEN RECORDING SOFTWARE DETECTION"

$recording_software = Find-ScreenRecordingSoftware

if ($recording_software.Count -gt 0) {
    Write-Host "⚠ FOUND SCREEN RECORDING SOFTWARE!" -ForegroundColor Yellow
    Write-Log "⚠ SCREEN RECORDING SOFTWARE INSTALLED:"
    
    foreach ($software in $recording_software) {
        Write-Host "  ⚠ Software: $($software.Name)" -ForegroundColor Yellow
        Write-Host "    Installed: Yes" -ForegroundColor Yellow
        Write-Host "    Modified: $($software.Modified)" -ForegroundColor Cyan
        Write-Log "  SOFTWARE: $($software.Name)"
        Write-Log "    PATH: $($software.Path)"
        Write-Log "    EXECUTABLES: $($software.ExecutableCount)"
        Write-Log "    MODIFIED: $($software.Modified)"
        
        Add-Finding "WARNING" "Recording Software" "$($software.Name) installed - Could be used to hide evidence"
    }
} else {
    Write-Host "✓ No screen recording software found" -ForegroundColor Green
    Write-Log "✓ No screen recording software detected"
}
Write-Log ""

# [23/26] Generating final verdict...
Write-Host "[23/26] Generating final verdict..." -ForegroundColor Yellow
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
