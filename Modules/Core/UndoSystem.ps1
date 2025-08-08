# ==============================================================================
# TIDYAI - UNDO SYSTEM
# Handles backup and restoration of folder organization
# ==============================================================================

function Test-UndoFileExists {
    param([string]$TargetPath)
    
    $undoFilePath = Join-Path $TargetPath ".tidyai"
    return Test-Path $undoFilePath
}

function Get-UndoFilePath {
    param([string]$TargetPath)
    
    return Join-Path $TargetPath ".tidyai"
}

function Save-OrganizationState {
    param(
        [string]$TargetPath,
        [array]$OriginalStructure,
        [array]$NewStructure
    )
    
    try {
        $undoFilePath = Get-UndoFilePath -TargetPath $TargetPath
        
        # Create undo data structure
        $undoData = @{
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            targetPath = $TargetPath
            originalStructure = $OriginalStructure
            newStructure = $NewStructure
            version = "2.0.0"
        }
        
        # Save as JSON with hidden attribute
        $jsonData = $undoData | ConvertTo-Json -Depth 10
        $jsonData | Out-File -FilePath $undoFilePath -Encoding UTF8
        
        # Make file hidden
        $file = Get-Item $undoFilePath
        $file.Attributes = $file.Attributes -bor [System.IO.FileAttributes]::Hidden
        
        Write-ColorText "Undo information saved successfully" $Colors.Success
        return $true
    }
    catch {
        Write-ColorText "Failed to save undo information: $($_.Exception.Message)" $Colors.Error
        return $false
    }
}

function Get-UndoData {
    param([string]$TargetPath)
    
    try {
        $undoFilePath = Get-UndoFilePath -TargetPath $TargetPath
        
        if (-not (Test-Path $undoFilePath)) {
            return $null
        }
        
        $jsonContent = Get-Content $undoFilePath -Raw -Encoding UTF8
        $undoData = $jsonContent | ConvertFrom-Json
        
        return $undoData
    }
    catch {
        Write-ColorText "Failed to read undo data: $($_.Exception.Message)" $Colors.Error
        return $null
    }
}

function Invoke-UndoOrganization {
    param([string]$TargetPath)
    
    try {
        Write-ColorText "Starting undo operation..." $Colors.Info
        
        $undoData = Get-UndoData -TargetPath $TargetPath
        if (-not $undoData) {
            Write-ColorText "No undo data found" $Colors.Error
            return $false
        }
        
        Write-ColorText "Restoring original folder structure..." $Colors.Info
        Write-ColorText "Organization from: $($undoData.timestamp)" $Colors.Accent
        
        # Use the original structure data to restore files properly
        $restoredCount = 0
        $skippedCount = 0
        
        # Get all organized folders (created by TidyAI)
        $organizedFolders = Get-ChildItem $TargetPath -Directory -Force | Where-Object { $_.Name -ne ".tidyai" }
        
        foreach ($folder in $organizedFolders) {
            Write-ColorText "  Processing folder: $($folder.Name)" $Colors.Accent
            $folderContents = Get-ChildItem $folder.FullName -Force
            
            foreach ($content in $folderContents) {
                $destinationPath = Join-Path $TargetPath $content.Name
                
                try {
                    if (Test-Path $destinationPath) {
                        # File already exists in root - this indicates a conflict or duplicate
                        Write-ColorText "    Conflict: $($content.Name) already exists in root - overwriting" $Colors.Warning
                        Remove-Item $destinationPath -Force
                    }
                    
                    # Move the file back to root
                    Move-Item $content.FullName $destinationPath -Force
                    Write-ColorText "    Restored: $($content.Name)" $Colors.Info
                    $restoredCount++
                }
                catch {
                    Write-ColorText "    Failed to restore: $($content.Name) - $($_.Exception.Message)" $Colors.Error
                    $skippedCount++
                }
            }
            
            # Remove the organized folder if it's empty
            $remainingContents = Get-ChildItem $folder.FullName -Force
            if ($remainingContents.Count -eq 0) {
                Remove-Item $folder.FullName -Force
                Write-ColorText "    Removed empty folder: $($folder.Name)" $Colors.Success
            } else {
                Write-ColorText "    Warning: Folder $($folder.Name) still contains $($remainingContents.Count) items" $Colors.Warning
            }
        }
        
        Write-ColorText "Restoration summary: $restoredCount files restored, $skippedCount failed" $Colors.Info
        
        # Remove undo file
        $undoFilePath = Get-UndoFilePath -TargetPath $TargetPath
        Remove-Item $undoFilePath -Force
        
        Write-ColorText "Undo completed successfully!" $Colors.Success
        Write-ColorText "Original folder structure has been restored." $Colors.Info
        
        return $true
    }
    catch {
        Write-ColorText "Error during undo operation: $($_.Exception.Message)" $Colors.Error
        return $false
    }
}

function Show-UndoPrompt {
    param([string]$TargetPath)
    
    $undoData = Get-UndoData -TargetPath $TargetPath
    if (-not $undoData) {
        return $false
    }
    
    Write-ColorText "========================================" $Colors.Primary
    Write-ColorText "TIDYAI WAS HERE BEFORE!" $Colors.Warning
    Write-ColorText "========================================" $Colors.Primary
    Write-ColorText "This folder was organized on: $($undoData.timestamp)" $Colors.Info
    Write-ColorText "Path: $($undoData.targetPath)" $Colors.Accent
    Write-Host ""
    Write-ColorText "What would you like to do?" $Colors.Info
    Write-ColorText "  [Y] Undo - Restore the original messy structure" $Colors.Warning
    Write-ColorText "  [N] Continue - Organize again with fresh AI suggestions" $Colors.Success
    Write-Host ""
    
    $response = Read-Host "Your choice (Y/N)"
    
    if ($response -match '^[Yy]') {
        return Invoke-UndoOrganization -TargetPath $TargetPath
    } else {
        Write-ColorText "Keeping current organization. Continuing with new organization..." $Colors.Info
        # Remove old undo file since user wants to keep current state
        $undoFilePath = Get-UndoFilePath -TargetPath $TargetPath
        Remove-Item $undoFilePath -Force -ErrorAction SilentlyContinue
        return $false
    }
}

function Show-PostOrganizationPrompt {
    param([string]$TargetPath)
    
    Write-Host ""
    Write-ColorText "========================================" $Colors.Primary
    Write-ColorText "*** ORGANIZATION COMPLETE! ***" $Colors.Success
    Write-ColorText "========================================" $Colors.Primary
    Write-ColorText "Your files have been organized successfully!" $Colors.Info
    Write-Host ""
    Write-ColorText "How does it look?" $Colors.Info
    Write-ColorText "  [K] Keep it - I love the new organization!" $Colors.Success
    Write-ColorText "  [U] Undo - Put everything back the way it was" $Colors.Warning
    Write-Host ""
    
    $response = Read-Host "Your decision (K/U)"
    
    if ($response -match '^[Uu]') {
        Write-Host ""
        if (Invoke-UndoOrganization -TargetPath $TargetPath) {
            Write-ColorText "Organization has been undone successfully!" $Colors.Success
        } else {
            Write-ColorText "Failed to undo organization" $Colors.Error
        }
    } else {
        Write-ColorText "Keeping the new organization. Undo data will remain available." $Colors.Success
        Write-ColorText "You can run TidyAI again to undo this organization later." $Colors.Info
    }
}
