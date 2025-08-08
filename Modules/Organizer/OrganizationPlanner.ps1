# ==============================================================================
# TIDYAI - ORGANIZATION PLANNING & COORDINATION
# ==============================================================================

function Confirm-AndApplyOrganization {
    param([array]$Structure)
    
    if (-not $Structure -or $Structure.Count -eq 0) {
        Write-ColorText "No changes to apply." $Colors.Info
        return
    }
    
    Write-ColorText "========================================" $Colors.Primary
    Write-ColorText "Would you like to apply these changes?" $Colors.Info
    Write-Host ""
    
    # Ask for user confirmation
    $confirmation = Read-Host "Apply organization? (Y/N)"
    
    if ($confirmation -match '^[Yy]') {
        # Save current state for undo before making changes
        Write-ColorText "Saving undo information..." $Colors.Info
        
        # Get current folder structure before organization
        $originalItems = Get-ChildItem $script:CurrentTargetPath -Force | Where-Object { $_.Name -ne ".tidyai" }
        $originalStructure = @()
        foreach ($item in $originalItems) {
            $originalStructure += @{
                name = $item.Name
                type = if ($item.PSIsContainer) { "folder" } else { "file" }
                fullPath = $item.FullName
            }
        }
        
        # Save undo state
        $undoSaved = Save-OrganizationState -TargetPath $script:CurrentTargetPath -OriginalStructure $originalStructure -NewStructure $Structure
        
        if ($undoSaved) {
            Write-ColorText "Undo information saved successfully" $Colors.Success
        } else {
            Write-ColorText "Warning: Could not save undo information" $Colors.Warning
            $continueAnyway = Read-Host "Continue without undo capability? (Y/N)"
            if ($continueAnyway -notmatch '^[Yy]') {
                Write-ColorText "Organization cancelled." $Colors.Warning
                return
            }
        }
        
        # Apply the organization
        Apply-Organization -SuggestedStructure $Structure -TargetPath $script:CurrentTargetPath
        
        # Show post-organization undo prompt
        Show-PostOrganizationPrompt -TargetPath $script:CurrentTargetPath
    } else {
        Write-ColorText "Organization cancelled. No files were moved." $Colors.Warning
    }
    
    Write-Host ""
}

function Start-FileOrganization {
    param([array]$Items)
    
    # Determine processing strategy based on file count
    if ($Items.Count -le 150) {
        # Single batch processing for smaller folders
        Invoke-SingleBatchProcessing -Files $Items
    } else {
        # Multi-batch processing for larger folders
        Invoke-MultiBatchProcessing -Files $Items
    }
}

function Invoke-SingleBatchProcessing {
    param([array]$Files)
    
    Write-ColorText "Processing all $($Files.Count) files in single batch..." $Colors.Info
    Write-Host ""
    
    try {
        # Build JSON for single batch
        $jsonData = New-BatchJson -Items $Files -ExistingStructure @()
        
        # Send to OpenAI
        $response = Invoke-OpenAIRequest -JsonData $jsonData -RequestType "batch"
        
        if ($null -eq $response) {
            Write-ColorText "Failed to get response from ChatGPT" $Colors.Error
            return
        }
        
        # Process response
        $structure = ConvertFrom-AIResponse -JsonResponse $response -OriginalItems $Files
        
        if ($structure) {
            # Validate final structure
            $validatedStructure = Test-FinalStructure -OriginalFiles $Files -OrganizedStructure $structure
            
            if ($validatedStructure) {
                Show-OrganizationTree -Structure $validatedStructure
                Confirm-AndApplyOrganization -Structure $validatedStructure
            }
        }
    }
    catch {
        Write-ColorText "Error in single-batch processing: $($_.Exception.Message)" "Red"
    }
}

function Invoke-MultiBatchProcessing {
    param([array]$Files)
    
    Write-ColorText "Starting multi-batch processing for $($Files.Count) files..." $Colors.Info
    Write-Host ""
    
    try {
        # Initialize master organization structure
        $masterStructure = [System.Collections.ArrayList]@()
        $processedFiles = [System.Collections.ArrayList]@()
        
        # Create mixed batches with adaptive sizing
        $allFiles = $Files | Sort-Object name
        $batchNumber = 1
        $currentBatchSize = 75  # Start with 75, reduce if we get 400 errors
        $consecutive400Errors = 0
        $totalBatches = [Math]::Ceiling($Files.Count / $currentBatchSize)
        $fileIndex = 0
        
        while ($fileIndex -lt $allFiles.Count) {
            # Take up to current batch size for this batch
            $batchSize = [Math]::Min($currentBatchSize, ($allFiles.Count - $fileIndex))
            $currentBatch = $allFiles[$fileIndex..($fileIndex + $batchSize - 1)]
            $fileIndex += $batchSize
            
            Write-ColorText "Processing batch $batchNumber/$totalBatches ($($currentBatch.Count) files, batch size: $currentBatchSize)..." $Colors.Info
            
            # Process this batch with simple retry logic
            $batchResult = Invoke-BatchProcessing -Files $currentBatch -ExistingStructure $masterStructure -BatchNumber $batchNumber
            
            # If failed, retry once after 8 seconds
            if ($null -eq $batchResult) {
                Write-ColorText "Batch $batchNumber failed, retrying in 8 seconds..." $Colors.Warning
                Start-Sleep -Seconds 8
                $batchResult = Invoke-BatchProcessing -Files $currentBatch -ExistingStructure $masterStructure -BatchNumber $batchNumber
                
                # If still failed, track consecutive 400 errors
                if ($null -eq $batchResult) {
                    $consecutive400Errors++
                    Write-ColorText "Consecutive 400 errors: $consecutive400Errors" $Colors.Warning
                    
                    # Reduce batch size if we get multiple 400 errors
                    if ($consecutive400Errors -ge 2 -and $currentBatchSize -gt 25) {
                        $currentBatchSize = [Math]::Max(25, [Math]::Floor($currentBatchSize * 0.7))
                        Write-ColorText "Reducing batch size to $currentBatchSize due to repeated 400 errors" $Colors.Warning
                        $totalBatches = [Math]::Ceiling(($allFiles.Count - $fileIndex + $batchSize) / $currentBatchSize) + $batchNumber - 1
                    }
                }
            }
            
            if ($batchResult) {
                # Reset consecutive error counter on success
                $consecutive400Errors = 0
                
                # Merge batch result with master structure
                $masterStructure = Merge-BatchResults -MasterStructure $masterStructure -BatchResult $batchResult
                
                # Track processed files
                foreach ($file in $currentBatch) {
                    [void]$processedFiles.Add($file)
                }
                
                Write-ColorText "Batch $batchNumber completed successfully" $Colors.Success
            } else {
                Write-ColorText "Batch $batchNumber failed - skipping" $Colors.Error
            }
            
            $batchNumber++
            Write-Host ""
        }
        
        # Final validation and recovery
        Write-ColorText "Performing final validation..." $Colors.Info
        $finalStructure = Test-FinalStructure -OriginalFiles $Files -OrganizedStructure $masterStructure
        
        if ($finalStructure) {
            Write-ColorText "Multi-batch processing completed successfully!" $Colors.Success
            Write-Host ""
            Show-OrganizationTree -Structure $finalStructure
            Confirm-AndApplyOrganization -Structure $finalStructure
        } else {
            Write-ColorText "Final validation failed" $Colors.Error
        }
    }
    catch {
        Write-ColorText "Error in multi-batch processing: $($_.Exception.Message)" "Red"
    }
}

function Invoke-BatchProcessing {
    param([array]$Files, [array]$ExistingStructure, [int]$BatchNumber)
    
    try {
        # Build JSON for this batch
        $jsonData = New-BatchJson -Items $Files -ExistingStructure $ExistingStructure
        
        # Send to OpenAI
        $existingFolders = $ExistingStructure | ForEach-Object { $_.folderName }
        $response = Invoke-OpenAIRequest -JsonData $jsonData -RequestType "batch" -ExistingFolders $existingFolders -BatchNumber $BatchNumber
        
        if ($null -eq $response) {
            Write-ColorText "Batch ${BatchNumber}: Failed to get AI response" $Colors.Error
            return $null
        }
        
        # Process AI response
        $batchStructure = ConvertFrom-AIResponse -JsonResponse $response -OriginalItems $Files
        
        if ($batchStructure) {
            Write-ColorText "Batch ${BatchNumber}: Processed $($Files.Count) files into $($batchStructure.Count) folders" $Colors.Success
            return $batchStructure
        }
        
        return $null
    }
    catch {
        Write-ColorText "Batch ${BatchNumber}: Error processing - $($_.Exception.Message)" $Colors.Error
        return $null
    }
}

function Merge-BatchResults {
    param([System.Collections.ArrayList]$MasterStructure, [array]$BatchResult)
    
    foreach ($batchFolder in $BatchResult) {
        # Check if folder already exists in master structure
        $existingFolder = $MasterStructure | Where-Object { $_.folderName -eq $batchFolder.folderName }
        
        if ($existingFolder) {
            # Merge files into existing folder
            $existingItems = [System.Collections.ArrayList]@($existingFolder.items)
            foreach ($item in $batchFolder.items) {
                [void]$existingItems.Add($item)
            }
            $existingFolder.items = $existingItems.ToArray()
        } else {
            # Add new folder to master structure
            [void]$MasterStructure.Add($batchFolder)
        }
    }
    
    return $MasterStructure
}

function Get-MissedFiles {
    param([array]$OriginalFiles, [array]$OrganizedStructure)
    
    # Get all items that were organized
    $organizedItems = @()
    foreach ($folder in $OrganizedStructure) {
        foreach ($item in $folder.items) {
            $organizedItems += $item.name
        }
    }
    
    # Find files that weren't organized
    $missedFiles = @()
    foreach ($file in $OriginalFiles) {
        if ($organizedItems -notcontains $file.name) {
            $missedFiles += $file
        }
    }
    
    return $missedFiles
}

function Test-FinalStructure {
    param([array]$OriginalFiles, [array]$OrganizedStructure)
    
    Write-ColorText "Validating final organization structure..." $Colors.Info
    
    try {
        # Check for missed files
        $missedFiles = Get-MissedFiles -OriginalFiles $OriginalFiles -OrganizedStructure $OrganizedStructure
        
        if ($missedFiles.Count -gt 0) {
            Write-ColorText "Found $($missedFiles.Count) files that need recovery processing..." $Colors.Warning
            
            # Process missed files with recovery logic
            $recoveryStructure = Process-MissedFiles -MissedFiles $missedFiles -ExistingStructure $OrganizedStructure
            
            if ($recoveryStructure) {
                # Merge recovery results with main structure
                $finalStructure = Merge-BatchResults -MasterStructure ([System.Collections.ArrayList]@($OrganizedStructure)) -BatchResult $recoveryStructure
                return @($finalStructure)
            }
        }
        
        return $OrganizedStructure
    }
    catch {
        Write-ColorText "Error in final validation: $($_.Exception.Message)" $Colors.Error
        return $null
    }
}

function Process-MissedFiles {
    param([array]$MissedFiles, [array]$ExistingStructure)
    
    try {
        Write-ColorText "Processing $($MissedFiles.Count) missed files..." $Colors.Info
        
        # Build JSON for missed files
        $jsonData = New-BatchJson -Items $MissedFiles -ExistingStructure $ExistingStructure
        
        # Get existing folder names for context
        $existingFolders = $ExistingStructure | ForEach-Object { $_.folderName }
        
        # Send to OpenAI with recovery request type
        $response = Invoke-OpenAIRequest -JsonData $jsonData -RequestType "recovery" -ExistingFolders $existingFolders
        
        if ($null -eq $response) {
            Write-ColorText "Failed to get recovery response from AI" $Colors.Error
            return $null
        }
        
        # Process AI response
        $recoveryStructure = ConvertFrom-AIResponse -JsonResponse $response -OriginalItems $MissedFiles
        
        if ($recoveryStructure) {
            Write-ColorText "Successfully processed $($MissedFiles.Count) missed files" $Colors.Success
            return $recoveryStructure
        }
        
        return $null
    }
    catch {
        Write-ColorText "Error processing missed files: $($_.Exception.Message)" $Colors.Error
        return $null
    }
}
