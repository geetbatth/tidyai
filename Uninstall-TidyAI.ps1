# ==============================================================================
# TidyAI Uninstaller
# Removes TidyAI from the system completely
# ==============================================================================

# Ensure we're running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Console Colors
$Colors = @{
    Primary   = "Cyan"
    Secondary = "Blue"
    Accent    = "Yellow"
    Success   = "Green"
    Warning   = "Yellow"
    Error     = "Red"
    Info      = "White"
}

# Installation paths
$INSTALL_DIR = "$env:ProgramFiles\TidyAI"

# Registry paths for context menu
$REGISTRY_KEY = "HKCR:\Directory\shell\TidyAI"
$REGISTRY_BACKGROUND_KEY = "HKCR:\Directory\Background\shell\TidyAI"
$REGISTRY_DESKTOP_KEY = "HKCR:\DesktopBackground\Shell\TidyAI"

# Registry paths for Windows uninstaller
$UNINSTALL_KEY = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\TidyAI"

function Show-UninstallerLogo {
    Clear-Host
    Write-Host ""
    Write-Host "    ############ #### ########   ####  ####     ##########    ####" -ForegroundColor $Colors.Primary
    Write-Host "    ############ #### ########   ####  ####     ##########    ####" -ForegroundColor $Colors.Primary
    Write-Host "        ####     #### ####  #### ####  ####     ####  ####    ####" -ForegroundColor $Colors.Primary
    Write-Host "        ####     #### ####  #### ####  ####     ####  ####    ####" -ForegroundColor $Colors.Accent
    Write-Host "        ####     #### ####  ####  ########      ##########    ####" -ForegroundColor $Colors.Accent
    Write-Host "        ####     #### ####  ####   ######       ##########    ####" -ForegroundColor $Colors.Accent
    Write-Host "        ####     #### ####  ####    ####        ####  ####    ####" -ForegroundColor $Colors.Secondary
    Write-Host "        ####     #### ########      ####        ####  ####    ####" -ForegroundColor $Colors.Secondary
    Write-Host "        ####     #### ########      ####        ####  #### ## ####" -ForegroundColor $Colors.Secondary
    Write-Host ""
    Write-Host "    ================================================================" -ForegroundColor $Colors.Primary
    Write-Host "    ||                                                            ||" -ForegroundColor $Colors.Primary
    Write-Host "    ||                   UNINSTALLER v1.0.0                     ||" -ForegroundColor $Colors.Warning
    Write-Host "    ||                                                            ||" -ForegroundColor $Colors.Primary
    Write-Host "    ||                 REMOVING TIDYAI                          ||" -ForegroundColor $Colors.Error
    Write-Host "    ||                                                            ||" -ForegroundColor $Colors.Primary
    Write-Host "    ================================================================" -ForegroundColor $Colors.Primary
    Write-Host ""
}

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = $Colors.Info,
        [switch]$NoNewline
    )
    
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Show-ProgressStep {
    param(
        [string]$Message,
        [string]$Status = "Info"
    )
    
    $statusColor = switch ($Status) {
        "Success" { $Colors.Success }
        "Warning" { $Colors.Warning }
        "Error" { $Colors.Error }
        default { $Colors.Info }
    }
    
    $statusSymbol = switch ($Status) {
        "Success" { "[OK]" }
        "Warning" { "[WARN]" }
        "Error" { "[ERROR]" }
        default { "[INFO]" }
    }
    
    Write-ColorText "$statusSymbol $Message" $statusColor
}

function Uninstall-TidyAI {
    Show-UninstallerLogo
    
    Write-ColorText "Starting TidyAI Uninstallation..." $Colors.Warning
    Write-Host ""
    
    # Confirm uninstallation
    Write-ColorText "Are you sure you want to completely remove TidyAI from your system?" $Colors.Warning
    Write-ColorText "This will remove all files, context menu entries, and registry entries." $Colors.Info
    Write-Host ""
    $confirm = Read-Host "Type 'YES' to confirm uninstallation"
    
    if ($confirm -ne "YES") {
        Write-ColorText "Uninstallation cancelled." $Colors.Info
        Read-Host "Press Enter to exit"
        return
    }
    
    Write-Host ""
    Write-ColorText "Proceeding with uninstallation..." $Colors.Warning
    Write-Host ""
    
    try {
        # Step 1: Create HKCR drive if it doesn't exist
        Show-ProgressStep "Setting up registry access"
        if (-not (Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
        }
        Show-ProgressStep "Registry access configured" "Success"
        
        # Step 2: Remove context menu registry entries
        Show-ProgressStep "Removing context menu entries"
        
        # Remove folder context menu
        if (Test-Path $REGISTRY_KEY) {
            Remove-Item -Path $REGISTRY_KEY -Recurse -Force
            Show-ProgressStep "Folder context menu entries removed" "Success"
        } else {
            Show-ProgressStep "Folder context menu entries not found" "Warning"
        }
        
        # Remove folder background context menu
        if (Test-Path $REGISTRY_BACKGROUND_KEY) {
            Remove-Item -Path $REGISTRY_BACKGROUND_KEY -Recurse -Force
            Show-ProgressStep "Folder background context menu entries removed" "Success"
        } else {
            Show-ProgressStep "Folder background context menu entries not found" "Warning"
        }
        
        # Remove desktop context menu
        if (Test-Path $REGISTRY_DESKTOP_KEY) {
            Remove-Item -Path $REGISTRY_DESKTOP_KEY -Recurse -Force
            Show-ProgressStep "Desktop context menu entries removed" "Success"
        } else {
            Show-ProgressStep "Desktop context menu entries not found" "Warning"
        }
        
        # Step 3: Remove Windows uninstaller registry entries
        Show-ProgressStep "Removing Windows uninstaller entries"
        if (Test-Path $UNINSTALL_KEY) {
            Remove-Item -Path $UNINSTALL_KEY -Recurse -Force
            Show-ProgressStep "Windows uninstaller entries removed" "Success"
        } else {
            Show-ProgressStep "Windows uninstaller entries not found" "Warning"
        }
        
        # Step 4: Remove API key environment variable
        Show-ProgressStep "Removing API key environment variable"
        try {
            [Environment]::SetEnvironmentVariable("TidyAIOpenAIAPIKey", $null, "User")
            Show-ProgressStep "API key environment variable removed" "Success"
        } catch {
            Show-ProgressStep "API key removal failed (non-critical): $($_.Exception.Message)" "Warning"
        }
        
        # Step 5: Force refresh Windows Explorer context menus
        Show-ProgressStep "Refreshing Windows Explorer context menus"
        try {
            # Method 1: Notify shell of changes
            Add-Type -TypeDefinition @"
                using System;
                using System.Runtime.InteropServices;
                public class Shell32 {
                    [DllImport("shell32.dll", CharSet = CharSet.Auto, SetLastError = true)]
                    public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
                }
"@
            [Shell32]::SHChangeNotify(0x8000000, 0x1000, [IntPtr]::Zero, [IntPtr]::Zero)
            
            # Method 2: Restart Windows Explorer
            Show-ProgressStep "Restarting Windows Explorer to clear context menu cache"
            $explorerProcesses = Get-Process -Name "explorer" -ErrorAction SilentlyContinue
            if ($explorerProcesses) {
                $explorerProcesses | Stop-Process -Force
                Start-Sleep -Seconds 2
                Start-Process "explorer.exe"
                Show-ProgressStep "Windows Explorer restarted" "Success"
            }
            
            Show-ProgressStep "Context menu cache cleared" "Success"
        } catch {
            Show-ProgressStep "Context menu refresh failed (non-critical): $($_.Exception.Message)" "Warning"
        }
        
        # Step 5: Remove installation directory
        Show-ProgressStep "Removing installation files"
        if (Test-Path $INSTALL_DIR) {
            Remove-Item -Path $INSTALL_DIR -Recurse -Force
            Show-ProgressStep "Installation files removed" "Success"
        } else {
            Show-ProgressStep "Installation directory not found" "Warning"
        }
        
        Write-Host ""
        Write-ColorText "TidyAI Uninstallation Complete!" $Colors.Success
        Write-ColorText "   All files and registry entries have been removed." $Colors.Info
        Write-ColorText "   Context menus have been refreshed." $Colors.Info
        Write-ColorText "   Thank you for using TidyAI!" $Colors.Accent
        Write-Host ""
        
    } catch {
        Show-ProgressStep "Uninstallation failed: $($_.Exception.Message)" "Error"
        Write-Host ""
        Write-ColorText "Please try running the uninstaller as Administrator." $Colors.Warning
        Write-Host ""
    }
    
    Read-Host "Press Enter to exit"
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

Uninstall-TidyAI
