# ==============================================================================
# TIDYAI - FILE ORGANIZATION OPERATIONS
# ==============================================================================

function Apply-Organization {
    param([array]$SuggestedStructure, [string]$TargetPath)
    
    Write-ColorText "Applying organization changes..." $Colors.Info
    Write-Host ""
    
    $totalMoves = 0
    $successfulMoves = 0
    $folderOperations = 0
    $successfulFolderOps = 0
    $errorMessages = @()
    
    try {
        foreach ($folder in $SuggestedStructure) {
            $folderPath = Join-Path $TargetPath $folder.folderName
            
            # Create folder if it doesn't exist
            if (-not (Test-Path $folderPath)) {
                New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
                Write-ColorText "Created folder: $($folder.folderName)" $Colors.Success
            }
            
            # Move items to the folder
            foreach ($item in $folder.items) {
                $sourcePath = Join-Path $TargetPath $item.name
                $destinationPath = Join-Path $folderPath $item.name
                
                try {
                    if (Test-Path $sourcePath) {
                        $sourceItem = Get-Item $sourcePath
                        # Write-ColorText "DEBUG: Processing item '$($item.name)' - IsContainer: $($sourceItem.PSIsContainer)" $Colors.Warning
                        
                        if ($sourceItem.PSIsContainer) {
                            # Moving a folder
                            $folderOperations++
                            # Write-ColorText "DEBUG: Moving folder from '$sourcePath' to '$destinationPath'" $Colors.Warning
                            Move-Item -Path $sourcePath -Destination $destinationPath -Force
                            Write-ColorText "  [DIR] Moved folder: $($item.name)" $Colors.Accent
                            $successfulFolderOps++
                        } else {
                            # Moving a file
                            $totalMoves++
                            Move-Item -Path $sourcePath -Destination $destinationPath -Force
                            $emoji = Get-FileEmoji -Extension ([System.IO.Path]::GetExtension($item.name))
                            Write-ColorText "  $emoji Moved: $($item.name)" $Colors.Info
                            $successfulMoves++
                        }
                    } else {
                        # Item not found - this is normal for sample files from folder metadata, skip silently
                        # We never delete any files so we can skip this
                    }
                }
                catch {
                    $errorMessages += "Failed to move $($item.name): $($_.Exception.Message)"
                }
            }
        }
        
        Write-Host ""
        Write-ColorText "Organization Complete!" $Colors.Success
        Write-ColorText "Successfully moved $successfulMoves files and $successfulFolderOps folders" $Colors.Info
        
        if ($errorMessages.Count -gt 0) {
            Write-Host ""
            Write-ColorText "Errors encountered:" $Colors.Warning
            foreach ($errorMsg in $errorMessages) {
                Write-ColorText "  - $errorMsg" $Colors.Error
           }
        }
    }
    catch {
        Write-ColorText "Error during organization: $($_.Exception.Message)" $Colors.Error
    }
}
