# ==============================================================================
# TIDYAI - USER INTERFACE FUNCTIONS
# ==============================================================================

function Show-Logo {
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
}

function Show-OrganizationTree {
    param([array]$Structure)
    
    if ($Structure -and $Structure.Count -gt 0) {
        Write-ColorText "Proposed Organization Structure:" $Colors.Primary
        Write-Host ""
        
        for ($i = 0; $i -lt $Structure.Count; $i++) {
            $folder = $Structure[$i]
            $isLast = ($i -eq ($Structure.Count - 1))
            
            # Folder line
            $folderPrefix = if ($isLast) { "+-- " } else { "+-- " }
            $emoji = Get-FileEmoji "folder"
            
            Write-ColorText "$folderPrefix$emoji $($folder.folderName) ($($folder.items.Count) files)" $Colors.Primary
            
            for ($j = 0; $j -lt $folder.items.Count; $j++) {
                $item = $folder.items[$j]
                $isLastItem = ($j -eq ($folder.items.Count - 1))
                $continuation = if ($isLast) { "    " } else { "|   " }
                
                $itemPrefix = if ($isLastItem) { "$continuation+-- " } else { "$continuation+-- " }
                
                # Check if item is a folder by testing if it exists as a directory
                $itemPath = Join-Path $script:CurrentTargetPath $item.name
                if (Test-Path $itemPath -PathType Container) {
                    $emoji = Get-FileEmoji "folder"
                } else {
                    $emoji = Get-FileEmoji $item.extension
                }
                
                Write-ColorText "$itemPrefix$emoji $($item.name)" $Colors.Info
            }
            
            if (-not $isLast) {
                Write-ColorText "|" $Colors.Info
            }
        }
    } else {
        Write-ColorText "+-- No reorganization suggested - folder is already well organized!" $Colors.Success
    }
    
    Write-Host ""
}
