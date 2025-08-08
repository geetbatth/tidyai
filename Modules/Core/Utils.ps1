# ==============================================================================
# TIDYAI - UTILITY FUNCTIONS
# ==============================================================================

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White",
        [switch]$NoNewline
    )
    
    # Handle empty or null color
    if ([string]::IsNullOrWhiteSpace($Color)) {
        $Color = "White"
    }
    
    # Validate color exists
    $validColors = @("Black", "DarkBlue", "DarkGreen", "DarkCyan", "DarkRed", "DarkMagenta", "DarkYellow", "Gray", "DarkGray", "Blue", "Green", "Cyan", "Red", "Magenta", "Yellow", "White")
    if ($Color -notin $validColors) {
        $Color = "White"
    }
    
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Get-FileEmoji {
    param([string]$Extension)
    
    if ([string]::IsNullOrWhiteSpace($Extension)) {
        return $FileEmojis["default"]
    }
    
    $lowerExt = $Extension.ToLower()
    if ($FileEmojis.ContainsKey($lowerExt)) {
        return $FileEmojis[$lowerExt]
    }
    return $FileEmojis["default"]
}

function Group-FilesByType {
    param([array]$Files)
    
    # Simple grouping by extension for batch processing
    return $Files | Group-Object extension
}

function Show-ProgressBar {
    param([string]$Activity, [int]$PercentComplete)
    
    Write-Progress -Activity $Activity -PercentComplete $PercentComplete
}
