# ==============================================================================
# TIDYAI - INTELLIGENT FOLDER ORGANIZATION TOOL
# Version 2.0.0 - Modular Architecture
# ==============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$FolderPath
)

# ==============================================================================
# MODULE IMPORTS
# ==============================================================================

# Get the script directory to build module paths
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Import Core modules
. (Join-Path $ScriptRoot "Modules\Core\Config.ps1")
. (Join-Path $ScriptRoot "Modules\Core\Utils.ps1")
. (Join-Path $ScriptRoot "Modules\Core\UI.ps1")
. (Join-Path $ScriptRoot "Modules\Core\UndoSystem.ps1")

# Import Scanner modules
. (Join-Path $ScriptRoot "Modules\Scanner\FolderScanner.ps1")
. (Join-Path $ScriptRoot "Modules\Scanner\FileProcessor.ps1")

# Import AI modules
. (Join-Path $ScriptRoot "Modules\AI\OpenAIClient.ps1")
. (Join-Path $ScriptRoot "Modules\AI\ResponseParser.ps1")
. (Join-Path $ScriptRoot "Modules\AI\PromptBuilder.ps1")

# Import Organizer modules
. (Join-Path $ScriptRoot "Modules\Organizer\OrganizationPlanner.ps1")
. (Join-Path $ScriptRoot "Modules\Organizer\FileOrganizer.ps1")

# ==============================================================================
# MAIN EXECUTION FUNCTION
# ==============================================================================

function Main {
    param([string]$TargetFolder)
    
    # Show beautiful logo
    Show-Logo
    
    # Sanitize the folder path (remove extra quotes and normalize)
    $TargetFolder = $TargetFolder.Trim('"').Trim()
    
    # If path ends with a quote, it might be malformed - try to fix it
    if ($TargetFolder.EndsWith('"')) {
        $TargetFolder = $TargetFolder.TrimEnd('"')
    }
    
    # Convert relative paths to absolute paths
    if (-not [System.IO.Path]::IsPathRooted($TargetFolder)) {
        $TargetFolder = Resolve-Path $TargetFolder -ErrorAction SilentlyContinue
        if (-not $TargetFolder) {
            $TargetFolder = Get-Location
        }
    }
    
    # Validate folder path
    if (-not (Test-Path $TargetFolder -PathType Container)) {
        Write-ColorText "Error: Folder path does not exist or is not accessible." $Colors.Error
        Write-ColorText "   Path: $TargetFolder" $Colors.Warning
        Read-Host "Press Enter to exit"
        return
    }
    
    # Store target path for use in Apply-Organization function
    $script:CurrentTargetPath = $TargetFolder
    
    Write-ColorText "Target Folder: " $Colors.Info -NoNewline
    Write-ColorText $TargetFolder $Colors.Accent
    Write-Host ""
    
    # Check for existing undo file and prompt user
    if (Test-UndoFileExists -TargetPath $TargetFolder) {
        $undoPerformed = Show-UndoPrompt -TargetPath $TargetFolder
        if ($undoPerformed) {
            Write-Host ""
            Write-ColorText "Undo operation completed. Exiting..." $Colors.Success
            Read-Host "Press Enter to exit"
            return
        }
        Write-Host ""
    }
    
    # Step 1: Scan the folder
    $items = Scan-Folder -Path $TargetFolder
    
    if ($items.Count -eq 0) {
        Write-ColorText "The folder appears to be empty or inaccessible." $Colors.Warning
        Read-Host "Press Enter to exit"
        return
    }
    
    # Step 2: Process folder organization
    Start-FileOrganization -Items $items
    
    # Wait for user input before closing
    Write-ColorText "Press Enter to exit..." $Colors.Info
    Read-Host
}

# ==============================================================================
# SCRIPT ENTRY POINT
# ==============================================================================

# Ensure we're running in a proper console
if ($Host.Name -eq "ConsoleHost") {
    # Set console properties for better display
    try {
        $Host.UI.RawUI.WindowTitle = "TidyAI - Intelligent Folder Organization"
        $Host.UI.RawUI.BackgroundColor = "Black"
        $Host.UI.RawUI.ForegroundColor = "White"
    }
    catch {
        # Ignore console customization errors
    }
}

# Run the main application
Main -TargetFolder $FolderPath
