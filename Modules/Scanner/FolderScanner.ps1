# ==============================================================================
# TIDYAI - FOLDER SCANNING FUNCTIONS
# ==============================================================================

function Get-FolderMetadata {
    param([string]$FolderPath)
    
    try {
        $folderInfo = Get-Item $FolderPath -ErrorAction Stop
        $childItems = Get-ChildItem $FolderPath -Force -ErrorAction SilentlyContinue
        
        $files = $childItems | Where-Object { -not $_.PSIsContainer }
        $subfolders = $childItems | Where-Object { $_.PSIsContainer }
        
        # Sample up to 5 random files for content understanding
        $sampleFiles = @()
        if ($files.Count -gt 0) {
            $sampleCount = [Math]::Min(5, $files.Count)
            $randomFiles = $files | Get-Random -Count $sampleCount
            foreach ($file in $randomFiles) {
                $sampleFiles += @{
                    name = $file.Name
                    extension = $file.Extension
                    size = $file.Length
                    lastModified = $file.LastWriteTime
                }
            }
        }
        
        return @{
            name = Split-Path $FolderPath -Leaf
            fullPath = $FolderPath
            lastModified = $folderInfo.LastWriteTime
            fileCount = $files.Count
            subfolderCount = $subfolders.Count
            sampleFiles = $sampleFiles
            isEmpty = $childItems.Count -eq 0
        }
    }
    catch {
        # Return minimal info if folder is inaccessible
        return @{
            name = Split-Path $FolderPath -Leaf
            fullPath = $FolderPath
            lastModified = Get-Date
            fileCount = 0
            subfolderCount = 0
            sampleFiles = @()
            isEmpty = $true
        }
    }
}

function Scan-Folder {
    param([string]$Path)
    
    Write-ColorText "Scanning folder: $Path" $Colors.Info
    Write-Host ""
    
    $items = @()
    $totalItems = 0
    
    try {
        # Get all items in the folder (non-recursive)
        $allItems = Get-ChildItem -Path $Path -Force -ErrorAction Stop
        $totalItems = $allItems.Count
        
        $processedItems = 0
        
        foreach ($item in $allItems) {
            $processedItems++
            $percentComplete = [math]::Round(($processedItems / $totalItems) * 100)
            
            # Horizontal progress bar every 50 items or at key percentages
            if ($processedItems % 50 -eq 0 -or $percentComplete -in @(25, 50, 75, 90, 100)) {
                $barWidth = 40
                $filledWidth = [math]::Round(($percentComplete / 100) * $barWidth)
                $emptyWidth = $barWidth - $filledWidth
                $progressBar = "#" * $filledWidth + "-" * $emptyWidth
                Write-Host "`r[$progressBar] $percentComplete% ($processedItems/$totalItems)" -NoNewline -ForegroundColor Yellow
            }
            
            if ($item.PSIsContainer) {
                # Folder information with metadata
                $folderMetadata = Get-FolderMetadata -FolderPath $item.FullName
                $itemInfo = @{
                    name = $item.Name
                    type = "folder"
                    lastModified = $item.LastWriteTime
                    fullPath = $item.FullName
                    fileCount = $folderMetadata.fileCount
                    subfolderCount = $folderMetadata.subfolderCount
                    sampleFiles = $folderMetadata.sampleFiles
                    isEmpty = $folderMetadata.isEmpty
                }
            } else {
                # File information
                $itemInfo = @{
                    name = $item.Name
                    type = "file"
                    extension = $item.Extension
                    size = $item.Length
                    lastModified = $item.LastWriteTime
                    fullPath = $item.FullName
                }
            }
            
            $items += $itemInfo
            Start-Sleep -Milliseconds 30  # Reduced delay since we're doing more work
        }
        
        Write-Host ""
        Write-ColorText "Scanned $totalItems items successfully!" $Colors.Success
        Write-Host ""
        
        return $items
    }
    catch {
        Write-ColorText "Error scanning folder: $($_.Exception.Message)" $Colors.Error
        return @()
    }
}
