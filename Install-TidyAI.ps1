# ==============================================================================
# TidyAI Installer - Context Menu Integration Setup
# Version 1.0.0
# ==============================================================================

# Requires Administrator privileges
#Requires -RunAsAdministrator

param(
    [switch]$Uninstall
)

# ==============================================================================
# CONFIGURATION
# ==============================================================================

$SCRIPT_NAME = "TidyAI.ps1"
$INSTALL_DIR = "$env:ProgramFiles\TidyAI"
$SCRIPT_PATH = Join-Path $INSTALL_DIR $SCRIPT_NAME

# Registry paths for context menu
$REGISTRY_KEY = "HKCR:\Directory\shell\TidyAI"
$REGISTRY_COMMAND_KEY = "HKCR:\Directory\shell\TidyAI\command"

# Registry paths for folder background context menu
$REGISTRY_BACKGROUND_KEY = "HKCR:\Directory\Background\shell\TidyAI"
$REGISTRY_BACKGROUND_COMMAND_KEY = "HKCR:\Directory\Background\shell\TidyAI\command"

# Registry paths for desktop context menu
$REGISTRY_DESKTOP_KEY = "HKCR:\DesktopBackground\Shell\TidyAI"
$REGISTRY_DESKTOP_COMMAND_KEY = "HKCR:\DesktopBackground\Shell\TidyAI\command"

# Registry paths for Windows uninstaller
$UNINSTALL_KEY = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\TidyAI"
$APP_VERSION = "1.0.0"
$APP_PUBLISHER = "TidyAI"
$APP_DISPLAY_NAME = "TidyAI - Intelligent Folder Organization"

# Console Colors
$Colors = @{
    Primary = "Cyan"
    Secondary = "Yellow" 
    Success = "Green"
    Warning = "DarkYellow"
    Error = "Red"
    Info = "White"
    Accent = "Magenta"
}

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

function Show-InstallerLogo {
    Clear-Host
    Write-Host ""
    Write-Host "    ################## #### ########  ####   ####     ##########    ####" -ForegroundColor $Colors.Primary
    Write-Host "    ################## #### ########  ####   ####     ##########    ####" -ForegroundColor $Colors.Primary
    Write-Host "        ####           #### ####  #### ####  ####     ####  ####    ####" -ForegroundColor $Colors.Primary
    Write-Host "        ####           #### ####  #### ####  ####     ####  ####    ####" -ForegroundColor $Colors.Accent
    Write-Host "        ####           #### ####  ####  ########      ##########    ####" -ForegroundColor $Colors.Accent
    Write-Host "        ####           #### ####  ####  #######       ##########    ####" -ForegroundColor $Colors.Accent
    Write-Host "        ####           #### ####  ####   ####         ####  ####    ####" -ForegroundColor $Colors.Secondary
    Write-Host "        ####           #### ########     ####         ####  ####    ####" -ForegroundColor $Colors.Secondary
    Write-Host "        ####           #### ########     ####         ####  #### ## ####" -ForegroundColor $Colors.Secondary
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

function Add-ContextMenuEntries {
    Write-ColorText "Adding context menu entries..." $Colors.Info
    
    try {
        # Commands for different contexts
        $folderCommand = "powershell.exe -WindowStyle Normal -ExecutionPolicy Bypass -File `"$SCRIPT_PATH`" -FolderPath `"%1`""
        $backgroundCommand = "powershell.exe -WindowStyle Normal -ExecutionPolicy Bypass -File `"$SCRIPT_PATH`" -FolderPath `"%V`""
        
        # Create folder context menu entry
        Write-ColorText "   Adding folder context menu entry..." $Colors.Info
        if (-not (Test-Path $REGISTRY_KEY)) {
            New-Item -Path $REGISTRY_KEY -Force | Out-Null
        }
        Set-ItemProperty -Path $REGISTRY_KEY -Name "(Default)" -Value "Tidy Up with TidyAI"
        Set-ItemProperty -Path $REGISTRY_KEY -Name "Icon" -Value "shell32.dll,4"
        
        if (-not (Test-Path $REGISTRY_COMMAND_KEY)) {
            New-Item -Path $REGISTRY_COMMAND_KEY -Force | Out-Null
        }
        Set-ItemProperty -Path $REGISTRY_COMMAND_KEY -Name "(Default)" -Value $folderCommand
        
        # Create folder background context menu entry
        Write-ColorText "   Adding folder background context menu entry..." $Colors.Info
        if (-not (Test-Path $REGISTRY_BACKGROUND_KEY)) {
            New-Item -Path $REGISTRY_BACKGROUND_KEY -Force | Out-Null
        }
        Set-ItemProperty -Path $REGISTRY_BACKGROUND_KEY -Name "(Default)" -Value "Tidy Up with TidyAI"
        Set-ItemProperty -Path $REGISTRY_BACKGROUND_KEY -Name "Icon" -Value "shell32.dll,4"
        
        if (-not (Test-Path $REGISTRY_BACKGROUND_COMMAND_KEY)) {
            New-Item -Path $REGISTRY_BACKGROUND_COMMAND_KEY -Force | Out-Null
        }
        Set-ItemProperty -Path $REGISTRY_BACKGROUND_COMMAND_KEY -Name "(Default)" -Value $backgroundCommand
        
        # Create desktop context menu entry
        Write-ColorText "   Adding desktop context menu entry..." $Colors.Info
        if (-not (Test-Path $REGISTRY_DESKTOP_KEY)) {
            New-Item -Path $REGISTRY_DESKTOP_KEY -Force | Out-Null
        }
        Set-ItemProperty -Path $REGISTRY_DESKTOP_KEY -Name "(Default)" -Value "Tidy Up with TidyAI"
        Set-ItemProperty -Path $REGISTRY_DESKTOP_KEY -Name "Icon" -Value "shell32.dll,4"
        
        if (-not (Test-Path $REGISTRY_DESKTOP_COMMAND_KEY)) {
            New-Item -Path $REGISTRY_DESKTOP_COMMAND_KEY -Force | Out-Null
        }
        Set-ItemProperty -Path $REGISTRY_DESKTOP_COMMAND_KEY -Name "(Default)" -Value $backgroundCommand
        
        Write-ColorText "   All context menu entries added successfully" $Colors.Success
        
        # Force refresh the shell to pick up changes immediately
        try {
            $shellApplication = New-Object -ComObject Shell.Application
            $shellApplication.RefreshMenu()
        } catch {
            # Refresh failed, but not critical
        }
        
    } catch {
        Write-ColorText "   Error adding context menu entries: $($_.Exception.Message)" $Colors.Error
        throw
    }
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-ProgressStep {
    param(
        [string]$Step,
        [string]$Status = "In Progress"
    )
    
    $emoji = switch ($Status) {
        "Success" { "[OK]" }
        "Error" { "[ERROR]" }
        "Warning" { "[WARN]" }
        default { "[...]" }
    }
    
    $color = switch ($Status) {
        "Success" { $Colors.Success }
        "Error" { $Colors.Error }
        "Warning" { $Colors.Warning }
        default { $Colors.Info }
    }
    
    Write-ColorText "$emoji $Step" $color
}

function Get-OpenAIAPIKey {
    Write-ColorText "OpenAI API Key Setup" $Colors.Accent
    Write-Host ""
    Write-ColorText "TidyAI requires an OpenAI API key to function." $Colors.Info
    Write-ColorText "You can get one from: https://platform.openai.com/api-keys" $Colors.Accent
    Write-Host ""
    
    do {
        $apiKey = Read-Host "Please enter your OpenAI API Key" -AsSecureString
        $plainKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey))
        
        if ([string]::IsNullOrWhiteSpace($plainKey)) {
            Write-ColorText "API key cannot be empty. Please try again." $Colors.Error
            continue
        }
        
        if (-not $plainKey.StartsWith("sk-")) {
            Write-ColorText "Warning: OpenAI API keys typically start with 'sk-'. Are you sure this is correct?" $Colors.Warning
            $confirm = Read-Host "Continue anyway? (y/n)"
            if ($confirm -ne "y" -and $confirm -ne "Y") {
                continue
            }
        }
        
        return $plainKey
        
    } while ($true)
}

function Set-APIKeyEnvironmentVariable {
    param([string]$ApiKey)
    
    try {
        Write-ColorText "Setting up API key environment variable..." $Colors.Info
        [Environment]::SetEnvironmentVariable("TidyAIOpenAIAPIKey", $ApiKey, "User")
        Write-ColorText "   API key configured successfully" $Colors.Success
        return $true
    } catch {
        Write-ColorText "   Error setting API key: $($_.Exception.Message)" $Colors.Error
        return $false
    }
}

# ==============================================================================
# INSTALLATION FUNCTIONS
# ==============================================================================

function Install-TidyAI {
    Show-InstallerLogo
    
    Write-ColorText "Welcome to TidyAI Installation!" $Colors.Info
    Write-Host ""
    
    # Step 1: Get and set API key
    $apiKey = Get-OpenAIAPIKey
    if (-not (Set-APIKeyEnvironmentVariable $apiKey)) {
        Write-ColorText "Failed to configure API key. Installation cannot continue." $Colors.Error
        Read-Host "Press Enter to exit"
        return $false
    }
    
    Write-Host ""
    Write-ColorText "Starting TidyAI Installation..." $Colors.Info
    Write-Host ""
    
    try {
        # Step 1: Create installation directory
        Show-ProgressStep "Creating installation directory"
        if (-not (Test-Path $INSTALL_DIR)) {
            New-Item -Path $INSTALL_DIR -ItemType Directory -Force | Out-Null
        }
        Show-ProgressStep "Installation directory created" "Success"
        
        # Step 2: Copy TidyAI script
        Show-ProgressStep "Copying TidyAI script"
        $currentScriptDir = if ($MyInvocation.MyCommand.Path) {
            Split-Path -Parent $MyInvocation.MyCommand.Path
        } else {
            Get-Location
        }
        $sourcePath = Join-Path $currentScriptDir $SCRIPT_NAME
        
        if (-not (Test-Path $sourcePath)) {
            Show-ProgressStep "TidyAI.ps1 not found in current directory" "Error"
            Write-ColorText "Please ensure TidyAI.ps1 is in the same folder as this installer." $Colors.Warning
            return $false
        }
        
        Copy-Item $sourcePath $SCRIPT_PATH -Force
        Show-ProgressStep "TidyAI script copied successfully" "Success"
        
        # Step 3: Create HKCR drive if it doesn't exist
        Show-ProgressStep "Setting up registry access"
        if (-not (Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue)) {
            New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
        }
        Show-ProgressStep "Registry access configured" "Success"
        
        # Step 4: Create context menu registry entries
        Add-ContextMenuEntries
        
        # Step 5: Create Windows uninstaller registry entries
        Show-ProgressStep "Adding Windows uninstaller entries"
        
        # Create uninstaller registry key
        if (-not (Test-Path $UNINSTALL_KEY)) {
            New-Item -Path $UNINSTALL_KEY -Force | Out-Null
        }
        
        # Calculate installation size (approximate)
        $installSize = if (Test-Path $SCRIPT_PATH) {
            [math]::Round((Get-Item $SCRIPT_PATH).Length / 1KB)
        } else {
            100  # Default size in KB
        }
        
        # Set uninstaller properties
        Set-ItemProperty -Path $UNINSTALL_KEY -Name "DisplayName" -Value $APP_DISPLAY_NAME
        Set-ItemProperty -Path $UNINSTALL_KEY -Name "DisplayVersion" -Value $APP_VERSION
        Set-ItemProperty -Path $UNINSTALL_KEY -Name "Publisher" -Value $APP_PUBLISHER
        Set-ItemProperty -Path $UNINSTALL_KEY -Name "InstallLocation" -Value $INSTALL_DIR
        Set-ItemProperty -Path $UNINSTALL_KEY -Name "UninstallString" -Value "powershell.exe -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Uninstall"
        Set-ItemProperty -Path $UNINSTALL_KEY -Name "QuietUninstallString" -Value "powershell.exe -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Uninstall"
        Set-ItemProperty -Path $UNINSTALL_KEY -Name "NoModify" -Value 1 -Type DWord
        Set-ItemProperty -Path $UNINSTALL_KEY -Name "NoRepair" -Value 1 -Type DWord
        Set-ItemProperty -Path $UNINSTALL_KEY -Name "EstimatedSize" -Value $installSize -Type DWord
        Set-ItemProperty -Path $UNINSTALL_KEY -Name "InstallDate" -Value (Get-Date -Format "yyyyMMdd")
        
        Show-ProgressStep "Windows uninstaller entries created" "Success"
        
        # Step 6: Set execution policy for the script
        Show-ProgressStep "Configuring PowerShell execution policy"
        try {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            Show-ProgressStep "Execution policy configured" "Success"
        }
        catch {
            Show-ProgressStep "Execution policy configuration (manual setup may be required)" "Warning"
        }
        
        Write-Host ""
        Write-ColorText "TidyAI Installation Complete!" $Colors.Success
        Write-Host ""
        Write-ColorText "Installation Summary:" $Colors.Info
        Write-ColorText "   - Installed to: $INSTALL_DIR" $Colors.Secondary
        Write-ColorText "   - Context menu added: Right-click any folder -> Tidy Up with TidyAI" $Colors.Secondary
        Write-ColorText "   - API key configured and ready to use!" $Colors.Secondary
        Write-Host ""
        
        return $true
    }
    catch {
        Show-ProgressStep "Installation failed: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Uninstall-TidyAI {
    Write-ColorText "Starting TidyAI Uninstallation..." $Colors.Warning
    Write-Host ""
    
    try {
        # Step 1: Remove context menu registry entries
        Show-ProgressStep "Removing context menu entries"
        
        if (Get-PSDrive -Name HKCR -ErrorAction SilentlyContinue) {
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
        }
        
        # Step 2: Remove Windows uninstaller registry entries
        Show-ProgressStep "Removing Windows uninstaller entries"
        if (Test-Path $UNINSTALL_KEY) {
            Remove-Item -Path $UNINSTALL_KEY -Recurse -Force
            Show-ProgressStep "Windows uninstaller entries removed" "Success"
        } else {
            Show-ProgressStep "Windows uninstaller entries not found" "Warning"
        }
        
        # Step 3: Remove installation directory
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
        Write-Host ""
        
        return $true
    }
    catch {
        Show-ProgressStep "Uninstallation failed: $($_.Exception.Message)" "Error"
        return $false
    }
}

function Show-Usage {
    Write-ColorText "TidyAI Installer Usage:" $Colors.Info
    Write-Host ""
    Write-ColorText "Install TidyAI:" $Colors.Secondary
    Write-ColorText "   .\Install-TidyAI.ps1" $Colors.Accent
    Write-Host ""
    Write-ColorText "Uninstall TidyAI:" $Colors.Secondary
    Write-ColorText "   .\Install-TidyAI.ps1 -Uninstall" $Colors.Accent
    Write-Host ""
    Write-ColorText "Requirements:" $Colors.Warning
    Write-ColorText "   - Run as Administrator" $Colors.Info
    Write-ColorText "   - TidyAI.ps1 must be in the same folder" $Colors.Info
    Write-ColorText "   - OpenAI API key (set after installation)" $Colors.Info
    Write-Host ""
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

function Main {
    # Show installer logo
    Show-InstallerLogo
    
    # Check for administrator rights
    if (-not (Test-AdminRights)) {
        Write-ColorText "Administrator rights required!" $Colors.Error
        Write-ColorText "   Please run this installer as Administrator." $Colors.Warning
        Write-ColorText "   Right-click PowerShell and select Run as Administrator" $Colors.Info
        Write-Host ""
        Show-Usage
        Read-Host "Press Enter to exit"
        return
    }
    
    Write-ColorText "Running with Administrator privileges" $Colors.Success
    Write-Host ""
    
    # Determine operation
    if ($Uninstall) {
        $success = Uninstall-TidyAI
    } else {
        $success = Install-TidyAI
    }
    
    # Wait for user input
    if ($success) {
        Write-ColorText "Press Enter to exit..." $Colors.Info
    } else {
        Write-ColorText "Press Enter to exit (check errors above)..." $Colors.Error
    }
    Read-Host
}

# ==============================================================================
# SCRIPT ENTRY POINT
# ==============================================================================

# Set console properties
try {
    $Host.UI.RawUI.WindowTitle = "TidyAI Installer"
    $Host.UI.RawUI.BackgroundColor = "Black"
    $Host.UI.RawUI.ForegroundColor = "White"
}
catch {
    # Ignore console customization errors
}

# Run the installer
Main
