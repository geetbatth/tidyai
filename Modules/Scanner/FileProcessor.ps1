# ==============================================================================
# TIDYAI - FILE PROCESSING FUNCTIONS
# ==============================================================================

function New-BatchJson {
    param([array]$Items, [array]$ExistingStructure = @(), [string]$Context = "General")
    
    # Create minimal data structure for batch
    $minimalItems = @()
    foreach ($item in $Items) {
        if ([string]::IsNullOrEmpty($item.name)) {
            continue
        }
        
        $lastModified = [DateTime]$item.lastModified
        
        if ($item.type -eq "folder") {
            # Folder data with metadata (sample files are for AI context only, not for organization)
            $sampleFileInfo = @()
            if ($item.sampleFiles -and $item.sampleFiles.Count -gt 0) {
                foreach ($sample in $item.sampleFiles) {
                    $sampleFileInfo += @{
                        name = $sample.name
                        extension = $sample.extension
                        size = $sample.size
                    }
                }
            }
            
            $itemData = @{
                name = $item.name
                type = "folder"
                fileCount = $item.fileCount
                subfolderCount = $item.subfolderCount
                isEmpty = $item.isEmpty
                sampleFiles = $sampleFileInfo
                age = if ($lastModified -gt (Get-Date).AddDays(-30)) { "recent" } else { "old" }
            }
        } else {
            # File data
            $itemData = @{
                name = $item.name
                type = "file"
                ext = $item.extension
                size = if ($item.size -gt 100MB) { "large" } elseif ($item.size -gt 10MB) { "medium" } else { "small" }
                age = if ($lastModified -gt (Get-Date).AddDays(-30)) { "recent" } else { "old" }
            }
        }
        
        $minimalItems += $itemData
    }
    
    # Include existing folder structure for context
    $existingFolders = @()
    foreach ($folder in $ExistingStructure) {
        if (![string]::IsNullOrEmpty($folder.folderName)) {
            $existingFolders += $folder.folderName
        }
    }
    
    $batchInfo = @{
        items = $minimalItems
        count = $minimalItems.Count
        existingFolders = $existingFolders
        context = $Context
    }
    
    # Debug: Show what we're sending to AI
    # $fileCount = ($minimalItems | Where-Object { $_.type -eq "file" }).Count
    # $folderCount = ($minimalItems | Where-Object { $_.type -eq "folder" }).Count
    # Write-ColorText "DEBUG: Sending $($minimalItems.Count) items to AI ($fileCount files, $folderCount folders)" $Colors.Warning
    # if ($minimalItems.Count -gt 0) {
    #     $sampleItem = $minimalItems[0]
    #     Write-ColorText "DEBUG: Sample item: $($sampleItem.name) (type: $($sampleItem.type))" $Colors.Warning
    #     if ($folderCount -gt 0) {
    #         $sampleFolder = $minimalItems | Where-Object { $_.type -eq "folder" } | Select-Object -First 1
    #         if ($sampleFolder) {
    #             Write-ColorText "DEBUG: Sample folder: $($sampleFolder.name) ($($sampleFolder.fileCount) files inside)" $Colors.Warning
    #         }
    #     }
    # }
    
    return $batchInfo | ConvertTo-Json -Depth 5
}
