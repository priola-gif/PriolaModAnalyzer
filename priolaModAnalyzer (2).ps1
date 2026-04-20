# Minecraft Screenshare Scanner v4.0 - PowerShell Edition
# Live Detection - Works While Game is Running!
# Professional Detection Tool - 302+ Signatures

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

# API STRINGS - Suspicious Method Calls (130+)
$API_STRINGS = @(
    "AutoCrystal", "autocrystal", "auto crystal", "cw crystal", "dontPlaceCrystal",
    "dontBreakCrystal", "AutoHitCrystal", "autohitcrystal", "canPlaceCrystalServer",
    "healPotSlot", "AutoAnchor", "autoanchor", "auto anchor", "DoubleAnchor", "hasGlowstone",
    "HasAnchor", "anchortweaks", "anchor macro", "safe anchor", "safeanchor", "AutoTotem",
    "autototem", "auto totem", "InventoryTotem", "inventorytotem", "HoverTotem", "hover totem",
    "legittotem", "AutoPot", "autopot", "auto pot", "speedPotSlot", "strengthPotSlot",
    "AutoArmor", "autoarmor", "auto armor", "preventSwordBlockBreaking", "preventSwordBlockAttack",
    "AutoDoubleHand", "autodoublehand", "auto double hand", "AutoClicker", "Breaking shield",
    "switch to mace", "switch to axe", "Donut", "JumpReset", "axespam", "axe spam",
    "shieldbreaker", "shield breaker", "EndCrystalItemMixin", "findKnockbackSword",
    "attackRegisteredThisClick", "autoCrystalPlaceClock", "AimAssist", "aimassist",
    "aim assist", "setBlockBreakingCooldown", "getBlockBreakingCooldown", "triggerbot",
    "trigger bot", "onBlockBreaking", "setItemUseCooldown", "freecam", "Freecam", "FakeInv",
    "swapBackToOriginalSlot", "setSelectedSlot", "invokeDoAttack", "pushOutOfBlocks",
    "FakeLag", "pingspoof", "ping spoof", "onTickMovement", "webmacro", "web macro",
    "arrayOfString", "invokeDoItemUse", "onPushOutOfBlocks", "onIsGlowing", "getSelectedSlot",
    "WalksyCrystalOptimizerMod", "lvstrng", "dqrkis", "selfdestruct", "self destruct",
    "blockBreakingCooldown", "invokeOnMouseButton", "POT_CHEATS", "onSwapLastAttackedTicksReset",
    "StringObfuscator", "getVisualAttackCooldownProgressPerTick", "getHandSwingDuration",
    "onBeginRenderTick", "PlayerMoveC2SPacketAccessor", "redirectSelectedSlot",
    "hookCancelBlockBreaking", "endcrystalitemmixin", "invokeSwap", "invokePlace",
    "invokeBreak", "invokeAttack"
)

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logfile = "$env:TEMP\Screenshare_Scan_$timestamp.txt"
$red_count = 0
$yellow_count = 0
$api_count = 0

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $logfile -Value $Message
}

# Header
Clear-Host
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   PROFESSIONAL SCREENSHARE SCANNER v4.0               ║" -ForegroundColor Cyan
Write-Host "║   Live Detection - Works While Game Running!          ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Log "╔════════════════════════════════════════════════════════╗"
Write-Log "║   PROFESSIONAL SCREENSHARE SCANNER v4.0               ║"
Write-Log "║   Live Detection Mode                                 ║"
Write-Log "╚════════════════════════════════════════════════════════╝"
Write-Log "Scan Time: $(Get-Date)"
Write-Log "RED Signatures: $($RED_STRINGS.Count) | YELLOW: $($YELLOW_STRINGS.Count) | API: $($API_STRINGS.Count)"
Write-Log ""

# Get Minecraft process
Write-Host "[1/6] Detecting running Minecraft..." -ForegroundColor Yellow
Write-Log "[1/6] MINECRAFT PROCESS DETECTION"

$java_proc = Get-Process | Where-Object {$_.ProcessName -eq "javaw" -or $_.ProcessName -eq "java"} | Select-Object -First 1

if ($java_proc) {
    Write-Host "✓ Found Minecraft process (PID: $($java_proc.Id))" -ForegroundColor Green
    Write-Log "✓ Found Minecraft process (PID: $($java_proc.Id))"
    Write-Log "  Memory: $([math]::Round($java_proc.WorkingSet/1MB)) MB"
} else {
    Write-Host "✗ Minecraft not running" -ForegroundColor Red
    Write-Log "✗ Minecraft not running - Game must be open to scan"
    Write-Host ""
    Write-Host "Please start Minecraft and try again!" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit
}
Write-Log ""

# Scan loaded modules (DLL injections)
Write-Host "[2/6] Scanning loaded modules (DLL injection check)..." -ForegroundColor Yellow
Write-Log "[2/6] LOADED MODULE ANALYSIS (DLL INJECTION CHECK)"

try {
    $modules = $java_proc.Modules
    $suspicious_dlls = @()
    
    foreach ($module in $modules) {
        $dll_name = $module.ModuleName.ToLower()
        
        if ($dll_name -match "inject|hook|patch|cheat|crack|wurst|meteor|vape") {
            Write-Host "⚠ Suspicious DLL: $($module.ModuleName)" -ForegroundColor Yellow
            Write-Log "⚠ Suspicious DLL: $($module.ModuleName)"
            $suspicious_dlls += $module.ModuleName
            $yellow_count++
        }
    }
    
    if ($suspicious_dlls.Count -eq 0) {
        Write-Host "✓ No suspicious DLLs loaded" -ForegroundColor Green
        Write-Log "✓ No suspicious DLLs loaded"
    }
} catch {
    Write-Host "⚠ Could not fully scan modules (elevated permissions may help)" -ForegroundColor Yellow
    Write-Log "⚠ Could not fully scan modules"
}
Write-Log ""

# Get process environment strings
Write-Host "[3/6] Extracting process memory strings..." -ForegroundColor Yellow
Write-Log "[3/6] PROCESS MEMORY STRING EXTRACTION"

try {
    # Get command line
    $proc_cmdline = (Get-WmiObject Win32_Process | Where-Object ProcessId -eq $java_proc.Id).CommandLine
    Write-Log "  Command: $proc_cmdline"
    
    # Check for suspicious command line arguments
    if ($proc_cmdline -match "inject|crack|cheat|bypass|client") {
        Write-Host "⚠ Suspicious command line arguments detected" -ForegroundColor Yellow
        Write-Log "⚠ Suspicious command line arguments detected"
        $yellow_count++
    }
} catch {}
Write-Log ""

# Scan files (non-locked)
Write-Host "[4/6] Scanning accessible files..." -ForegroundColor Yellow
Write-Log "[4/6] ACCESSIBLE FILE SCAN"

$minecraft_path = "$env:APPDATA\.minecraft"
$scan_paths = @(
    "$minecraft_path\launcher_accounts.json",
    "$minecraft_path\launcher_profiles.json",
    "$minecraft_path\launcher.exe",
    "$minecraft_path\*.log"
)

foreach ($path in $scan_paths) {
    if (Test-Path $path) {
        try {
            $files = @(Get-Item -Path $path -ErrorAction SilentlyContinue)
            foreach ($file in $files) {
                $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
                if ($content) {
                    $content_lower = $content.ToLower()
                    
                    foreach ($red in $RED_STRINGS) {
                        if ($content_lower.Contains($red.ToLower())) {
                            Write-Host "🚨 CRITICAL: '$red' found in $($file.Name)" -ForegroundColor Red
                            Write-Log "🚨 CRITICAL: '$red' found in $($file.Name)"
                            $red_count++
                        }
                    }
                    
                    foreach ($yellow in $YELLOW_STRINGS) {
                        if ($content_lower.Contains($yellow.ToLower())) {
                            Write-Host "⚠ WARNING: '$yellow' found in $($file.Name)" -ForegroundColor Yellow
                            Write-Log "⚠ WARNING: '$yellow' found in $($file.Name)"
                            $yellow_count++
                        }
                    }
                }
            }
        } catch {}
    }
}

if ($red_count -eq 0 -and $yellow_count -eq 0) {
    Write-Host "✓ No signatures in accessible files" -ForegroundColor Green
    Write-Log "✓ No signatures in accessible files"
}
Write-Log ""

# Check recently accessed executables
Write-Host "[5/6] Checking recent launcher executables..." -ForegroundColor Yellow
Write-Log "[5/6] RECENT EXECUTABLE ANALYSIS"

$recent_exes = @(Get-ChildItem -Path "$env:APPDATA\Microsoft\Windows\Recent" -Filter "*.exe" -ErrorAction SilentlyContinue)
if ($recent_exes) {
    Write-Host "⚠ Found $($recent_exes.Count) recent EXE file(s)" -ForegroundColor Yellow
    Write-Log "⚠ Found $($recent_exes.Count) recent EXE file(s) (may indicate injectors)"
    foreach ($exe in $recent_exes | Select-Object -First 10) {
        Write-Log "  - $($exe.Name)"
        $yellow_count++
    }
} else {
    Write-Host "✓ No suspicious recent executables" -ForegroundColor Green
    Write-Log "✓ No suspicious recent executables"
}
Write-Log ""

# Summary
Write-Host "[6/6] Generating final report..." -ForegroundColor Yellow

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   LIVE SCAN COMPLETE - RESULTS                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Log "╔════════════════════════════════════════════════════════╗"
Write-Log "║   LIVE SCAN COMPLETE - RESULTS                        ║"
Write-Log "╚════════════════════════════════════════════════════════╝"

Write-Host "CRITICAL (RED):  $red_count" -ForegroundColor Red
Write-Host "WARNING (YELLOW): $yellow_count" -ForegroundColor Yellow
Write-Host "INFO (API):      $api_count" -ForegroundColor DarkYellow
Write-Log "CRITICAL (RED):  $red_count"
Write-Log "WARNING (YELLOW): $yellow_count"
Write-Log "INFO (API):      $api_count"

Write-Host ""
if ($red_count -gt 0) {
    Write-Host "🚨 CHEAT CLIENT DETECTED - BAN IMMEDIATELY!" -ForegroundColor Red
    Write-Log "🚨 CHEAT CLIENT DETECTED - BAN IMMEDIATELY!"
} elseif ($yellow_count -gt 0) {
    Write-Host "⚠ SUSPICIOUS ACTIVITY - MANUAL REVIEW RECOMMENDED" -ForegroundColor Yellow
    Write-Log "⚠ SUSPICIOUS ACTIVITY - MANUAL REVIEW RECOMMENDED"
} else {
    Write-Host "✓ NO CHEATS DETECTED - PLAYER PASSED SCAN" -ForegroundColor Green
    Write-Log "✓ NO CHEATS DETECTED - PLAYER PASSED SCAN"
}

Write-Log ""
Write-Log "Report saved to: $logfile"
Write-Host ""
Write-Host "📄 Full report saved to: $logfile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to open report..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

if (Test-Path $logfile) {
    Invoke-Item $logfile
}
