# Minecraft Screenshare Scanner v3.0 - PowerShell Edition
# Professional Detection Tool - 302+ Signatures
# No Python Required!

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
Write-Host "║   PROFESSIONAL SCREENSHARE SCANNER v3.0               ║" -ForegroundColor Cyan
Write-Host "║   PowerShell Edition - 302+ Signatures                ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Log "╔════════════════════════════════════════════════════════╗"
Write-Log "║   PROFESSIONAL SCREENSHARE SCANNER v3.0               ║"
Write-Log "╚════════════════════════════════════════════════════════╝"
Write-Log "Scan Time: $(Get-Date)"
Write-Log "RED Signatures: $($RED_STRINGS.Count) | YELLOW: $($YELLOW_STRINGS.Count) | API: $($API_STRINGS.Count)"
Write-Log ""

# Scan Minecraft folder
$minecraft_path = "$env:APPDATA\.minecraft"

Write-Host "[1/4] Scanning Java processes..." -ForegroundColor Yellow
Write-Log "[1/4] JAVA PROCESS ANALYSIS"
$java_procs = Get-Process | Where-Object {$_.ProcessName -match "javaw|java"}
if ($java_procs) {
    Write-Host "⚠ Active Java process detected!" -ForegroundColor Yellow
    foreach ($proc in $java_procs) {
        Write-Log "  PID: $($proc.Id) | Name: $($proc.ProcessName)"
        $yellow_count++
    }
} else {
    Write-Host "✓ No Java processes found" -ForegroundColor Green
    Write-Log "✓ No Java processes found"
}
Write-Log ""

Write-Host "[2/4] Scanning mods folder..." -ForegroundColor Yellow
Write-Log "[2/4] MODS FOLDER SCAN"
$mods_path = "$minecraft_path\mods"
if (Test-Path $mods_path) {
    $jar_files = @(Get-ChildItem -Path $mods_path -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue)
    if ($jar_files) {
        Write-Host "⚠ Found $($jar_files.Count) JAR file(s)" -ForegroundColor Yellow
        Write-Log "⚠ Found $($jar_files.Count) JAR file(s)"
        foreach ($jar in $jar_files | Select-Object -First 20) {
            Write-Log "  - $($jar.Name)"
            $yellow_count++
        }
    } else {
        Write-Host "✓ No JAR files found" -ForegroundColor Green
        Write-Log "✓ No JAR files found"
    }
} else {
    Write-Host "✓ Mods folder not found" -ForegroundColor Green
    Write-Log "✓ Mods folder not found"
}
Write-Log ""

Write-Host "[3/4] Advanced signature search (302 signatures)..." -ForegroundColor Yellow
Write-Log "[3/4] ADVANCED SIGNATURE SEARCH"

if (Test-Path $minecraft_path) {
    $files = @(Get-ChildItem -Path $minecraft_path -Recurse -ErrorAction SilentlyContinue | 
               Where-Object {$_.Extension -in @('.txt', '.json', '.cfg', '.conf', '.jar', '.log')})
    
    foreach ($file in $files) {
        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
            $filename_lower = $file.Name.ToLower()
            
            if ($content) {
                $content_lower = $content.ToLower()
                
                # Check RED strings
                foreach ($red in $RED_STRINGS) {
                    if ($content_lower.Contains($red.ToLower()) -or $filename_lower.Contains($red.ToLower())) {
                        Write-Host "🚨 CRITICAL: '$red' detected in $($file.Name)" -ForegroundColor Red
                        Write-Log "🚨 CRITICAL: '$red' detected in $($file.Name)"
                        $red_count++
                    }
                }
                
                # Check YELLOW strings
                foreach ($yellow in $YELLOW_STRINGS) {
                    if ($content_lower.Contains($yellow.ToLower()) -or $filename_lower.Contains($yellow.ToLower())) {
                        Write-Host "⚠ WARNING: '$yellow' detected in $($file.Name)" -ForegroundColor Yellow
                        Write-Log "⚠ WARNING: '$yellow' detected in $($file.Name)"
                        $yellow_count++
                    }
                }
                
                # Check API strings
                foreach ($api in $API_STRINGS) {
                    if ($content_lower.Contains($api.ToLower()) -or $filename_lower.Contains($api.ToLower())) {
                        Write-Host "ℹ INFO: '$api' detected in $($file.Name)" -ForegroundColor DarkYellow
                        Write-Log "ℹ INFO: '$api' detected in $($file.Name)"
                        $api_count++
                    }
                }
            }
        } catch {}
    }
}

if ($red_count -eq 0 -and $yellow_count -eq 0 -and $api_count -eq 0) {
    Write-Host "✓ No suspicious signatures detected" -ForegroundColor Green
    Write-Log "✓ No suspicious signatures detected"
}
Write-Log ""

Write-Host "[4/4] Generating report..." -ForegroundColor Yellow
Write-Log "[4/4] GENERATING REPORT"

# Summary
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   SCAN COMPLETE - SUMMARY                             ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Log "╔════════════════════════════════════════════════════════╗"
Write-Log "║   SCAN COMPLETE - SUMMARY                             ║"
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
} elseif ($api_count -gt 0) {
    Write-Host "ℹ SUSPICIOUS PATTERNS - INVESTIGATION ADVISED" -ForegroundColor DarkYellow
    Write-Log "ℹ SUSPICIOUS PATTERNS - INVESTIGATION ADVISED"
} else {
    Write-Host "✓ NO SUSPICIOUS ACTIVITY DETECTED - PASS" -ForegroundColor Green
    Write-Log "✓ NO SUSPICIOUS ACTIVITY DETECTED - PASS"
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
