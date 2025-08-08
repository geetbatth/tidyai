# ==============================================================================
# TidyAI - Intelligent Folder Organization Tool
# Version 1.0.0
# ==============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$FolderPath
)

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# ChatGPT API Configuration - Read from Environment Variable
$OPENAI_API_KEY = $env:TidyAIOpenAIAPIKey
$OPENAI_API_URL = "https://api.openai.com/v1/chat/completions"

# Check if API key is configured
if ([string]::IsNullOrWhiteSpace($OPENAI_API_KEY)) {
    Write-ColorText "Error: OpenAI API key not configured!" $Colors.Error
    Write-Host ""
    Write-ColorText "Please set your API key using one of these methods:" $Colors.Info
    Write-ColorText "1. Windows GUI: This PC -> Properties -> Advanced -> Environment Variables" $Colors.Accent
    Write-ColorText "   Variable name: TidyAIOpenAIAPIKey" $Colors.Accent
    Write-ColorText "   Variable value: your-openai-api-key" $Colors.Accent
    Write-Host ""
    Write-ColorText "2. Command line: setx TidyAIOpenAIAPIKey \"your-openai-api-key\"" $Colors.Accent
    Write-Host ""
    Write-ColorText "3. PowerShell: [Environment]::SetEnvironmentVariable(\"TidyAIOpenAIAPIKey\", \"your-key\", \"User\")" $Colors.Accent
    Write-Host ""
    Write-ColorText "After setting the key, restart this application." $Colors.Warning
    Read-Host "Press Enter to exit"
    return
}

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

# File type icons for better visual representation (ASCII only)
$FileEmojis = @{
    ".txt"      = "[TXT]"
    ".doc"      = "[DOC]"
    ".docx"     = "[DOC]"
    ".pdf"      = "[PDF]"
    ".jpg"      = "[IMG]"
    ".jpeg"     = "[IMG]"
    ".png"      = "[IMG]"
    ".gif"      = "[IMG]"
    ".mp4"      = "[VID]"
    ".avi"      = "[VID]"
    ".mkv"      = "[VID]"
    ".mp3"      = "[AUD]"
    ".wav"      = "[AUD]"
    ".zip"      = "[ZIP]"
    ".rar"      = "[ZIP]"
    ".exe"      = "[EXE]"
    ".msi"      = "[EXE]"
    ".lnk"      = "[LNK]"
    ".cmd"      = "[CMD]"
    ".py"       = "[PY]"
    ".js"       = "[JS]"
    ".html"     = "[HTM]"
    ".css"      = "[CSS]"
    ".json"     = "[JSN]"
    ".xml"      = "[XML]"
    ".csv"      = "[CSV]"
    ".xlsx"     = "[XLS]"
    ".xls"      = "[XLS]"
    "folder"    = "[DIR]"
    "default"   = "[FILE]"
}

# ==============================================================================
# HELPER FUNCTIONS
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
    
    if ($NoNewline) {
        Write-Host $Text -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Show-ProgressBar {
    param(
        [string]$Activity,
        [int]$PercentComplete
    )
    
    $barLength = 40
    $filledLength = [math]::Floor(($PercentComplete / 100) * $barLength)
    $emptyLength = $barLength - $filledLength
    
    $bar = "#" * $filledLength + "." * $emptyLength
    
    Write-Host "`r$Activity [" -NoNewline -ForegroundColor $Colors.Info
    Write-Host $bar -NoNewline -ForegroundColor $Colors.Primary
    Write-Host "] $PercentComplete%" -NoNewline -ForegroundColor $Colors.Info
}

function Get-FileEmoji {
    param([string]$Extension)
    
    if ($FileEmojis.ContainsKey($Extension.ToLower())) {
        return $FileEmojis[$Extension.ToLower()]
    }
    return $FileEmojis["default"]
}

# ==============================================================================
# CORE FUNCTIONS
# ==============================================================================

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
            Show-ProgressBar "Analyzing items" $percentComplete
            
            $itemInfo = @{
                name = $item.Name
                type = if ($item.PSIsContainer) { "folder" } else { "file" }
                extension = if ($item.PSIsContainer) { "" } else { $item.Extension }
                size = if ($item.PSIsContainer) { 0 } else { $item.Length }
                lastModified = $item.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
                fullPath = $item.FullName
            }
            
            $items += $itemInfo
            Start-Sleep -Milliseconds 50  # Small delay for visual effect
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

function Build-FolderJson {
    param([array]$Items, [string]$FolderPath)
    
    # Create minimal data structure - only send what AI needs for organization
    $minimalItems = @()
    foreach ($item in $Items) {
        # Skip folders - only organize files
        if ($item.type -eq "file") {
            $lastModified = [DateTime]$item.lastModified
            $minimalItems += @{
                name = $item.name
                ext = $item.extension
                size = if ($item.size -gt 100MB) { "large" } elseif ($item.size -gt 10MB) { "medium" } else { "small" }
                age = if ($lastModified -gt (Get-Date).AddDays(-30)) { "recent" } else { "old" }
            }
        }
    }
    
    # Minimal folder context - just what AI needs
    $folderInfo = @{
        files = $minimalItems
        count = $minimalItems.Count
        context = if ($FolderPath -match "Desktop") { "Desktop" } elseif ($FolderPath -match "Downloads?") { "Downloads" } elseif ($FolderPath -match "Documents?") { "Documents" } else { "General" }
    }
    
    return $folderInfo | ConvertTo-Json -Depth 5
}

function Send-BatchToOpenAI {
    param([string]$JsonData, [int]$BatchNumber, [array]$ExistingFolders)
    
    # Check if API key is set
    if ([string]::IsNullOrEmpty($OPENAI_API_KEY)) {
        Write-ColorText "OpenAI API key not found!" $Colors.Error
        return $null
    }
    
    # Parse the JSON to get file count
    $data = $JsonData | ConvertFrom-Json
    $fileCount = $data.count
    
    # Build context-aware prompt for batch processing
    $existingFoldersText = if ($ExistingFolders.Count -gt 0) {
        "Existing folders you can reuse: " + ($ExistingFolders -join ", ")
    } else {
        "This is the first batch - create initial folder structure."
    }
    
    $prompt = @"
Organize these $fileCount files into logical, intelligent folders based on content patterns and purpose.

ORGANIZATION PRINCIPLES:
- Each file appears in EXACTLY ONE folder (zero duplicates allowed)
- Preserve ALL original filenames exactly as provided
- ANALYZE FILE NAMES for patterns, dates, projects, purposes, and content clues
- Group files by PURPOSE and CONTENT SIMILARITY, not just file type
- Look for naming patterns like dates, version numbers, project names, company names
- REUSE existing folders when appropriate for consistency
- Create specific, meaningful folders that tell a story about the files

INTELLIGENT GROUPING EXAMPLES:
- Files with similar prefixes/suffixes (e.g., "invoice_2024", "report_Q1")
- Files with dates or version numbers (group by time period or version)
- Files with company/project names (group by entity)
- Files with similar purposes (installation files, documentation, media)
- Sequential files or series (parts 1, 2, 3 or chapters)

FOLDER NAMING:
- Use specific, descriptive names that reflect the actual content
- Include context like dates, projects, or purposes when relevant
- Avoid generic names like "Documents" or "Files"
- Examples: "Invoice Records 2024", "Project Phoenix Documentation", "System Installation Files"

$existingFoldersText

Files to organize:
$JsonData

Respond with ONLY valid JSON (no explanations):
[{"folderName": "Descriptive Name", "items": [{"name": "exact-filename.ext"}]}]
"@
    
    return Send-OpenAIRequest -Prompt $prompt -SystemMessage "You are TidyAI, an intelligent file organization expert. Analyze file names and size, patterns, dates, projects, and purposes. Create meaningful folder structures based on content similarity and purpose, not just file extensions. Think like a human organizing their digital workspace - group related files together in a way that makes sense for productivity and easy retrieval."
}

function Send-RecoveryToOpenAI {
    param([string]$JsonData, [array]$ExistingStructure)
    
    # Check if API key is set
    if ([string]::IsNullOrEmpty($OPENAI_API_KEY)) {
        Write-ColorText "OpenAI API key not found!" $Colors.Error
        return $null
    }
    
    # Build existing folder list
    $existingFolders = $ExistingStructure | ForEach-Object { $_.folderName }
    $existingFoldersText = "Current folder structure: " + ($existingFolders -join ", ")
    
    $prompt = @"
These files were missed during batch processing and need to be organized.
$existingFoldersText

ORGANIZATION PRINCIPLES:
- Each file appears in EXACTLY ONE folder
- Preserve ALL original filenames exactly
- REUSE existing folders when appropriate
- Only create new folders if absolutely necessary
- Group by file type and purpose

Missed files to organize:
$JsonData

Respond with ONLY valid JSON (no explanations):
[{"folderName": "Folder Name", "items": [{"name": "exact-filename.ext"}]}]
"@
    
    return Send-OpenAIRequest -Prompt $prompt -SystemMessage "You are TidyAI recovery processor. Place missed files into the most appropriate existing folders. Only create new folders if absolutely necessary."
}

function Send-ToOpenAI {
    param([string]$JsonData)
    
    # Check if API key is set
    if ([string]::IsNullOrEmpty($OPENAI_API_KEY)) {
        Write-ColorText "OpenAI API key not found!" $Colors.Error
        Write-ColorText "Please ensure the TidyAIOpenAIAPIKey environment variable is set." $Colors.Warning
        Write-ColorText "You can set it by running the installer again or manually setting it in Windows." $Colors.Info
        return $null
    }
    
    # Parse the JSON to check item count
    $data = $JsonData | ConvertFrom-Json
    $fileCount = $data.count
    
    # Enhanced prompt for single-batch processing
    $prompt = @"
Analyze and organize these $fileCount files into intelligent, purpose-driven folders.

ORGANIZATION PRINCIPLES:
- Each file appears in EXACTLY ONE folder (zero duplicates allowed)
- Preserve ALL original filenames exactly as provided
- ANALYZE FILE NAMES for patterns, dates, projects, purposes, and content clues
- Group files by PURPOSE and CONTENT SIMILARITY, not just file type
- Look for naming patterns like dates, version numbers, project names, company names
- Create specific, meaningful folders that tell a story about the files

INTELLIGENT GROUPING EXAMPLES:
- Files with similar prefixes/suffixes (e.g., "invoice_2024", "report_Q1")
- Files with dates or version numbers (group by time period or version)
- Files with company/project names (group by entity)
- Files with similar purposes (installation files, documentation, media)
- Sequential files or series (parts 1, 2, 3 or chapters)

FOLDER NAMING:
- Use specific, descriptive names that reflect the actual content
- Include context like dates, projects, or purposes when relevant
- Avoid generic names like "Documents" or "Files"
- Examples: "Invoice Records 2024", "Project Phoenix Documentation", "System Installation Files"

Files to organize:
$JsonData

Respond with ONLY valid JSON (no explanations):
[{"folderName": "Descriptive Name", "items": [{"name": "exact-filename.ext"}]}]
"@
    
    return Send-OpenAIRequest -Prompt $prompt -SystemMessage "You are TidyAI, an intelligent file organization expert. Analyze file names for patterns, dates, projects, and purposes. Create meaningful folder structures based on content similarity and purpose, not just file extensions. Think like a human organizing their digital workspace - group related files together in a way that makes sense for productivity and easy retrieval."
}

function Send-OpenAIRequest {
    param([string]$Prompt, [string]$SystemMessage)
    
    # Clean and normalize the inputs to prevent 400 errors
    $cleanSystemMessage = $SystemMessage
    $cleanPrompt = $Prompt
    
    # Remove or replace non-ASCII characters
    $cleanSystemMessage = $cleanSystemMessage -replace '[^\x00-\x7F]', '?'
    $cleanPrompt = $cleanPrompt -replace '[^\x00-\x7F]', '?'
    
    # Normalize line endings to Unix style (LF only)
    $cleanSystemMessage = $cleanSystemMessage -replace '\r\n', '\n' -replace '\r', '\n'
    $cleanPrompt = $cleanPrompt -replace '\r\n', '\n' -replace '\r', '\n'
    
    $requestBody = @{
        model = "gpt-4o-mini"
        messages = @(
            @{
                role = "system"
                content = $cleanSystemMessage
            },
            @{
                role = "user" 
                content = $cleanPrompt
            }
        )
        max_tokens = 16384
        temperature = 0.3
    } | ConvertTo-Json -Depth 10



    $headers = @{
        "Authorization" = "Bearer $OPENAI_API_KEY"
        "Content-Type" = "application/json"
    }

    # Validate request size before sending
    $requestSize = [System.Text.Encoding]::UTF8.GetByteCount($requestBody)
    
    if ($requestSize -gt 100000) {  # 100KB limit
        Write-ColorText "WARNING: Large request size may cause truncation" $Colors.Warning
        Write-ColorText "Consider reducing the number of files or simplifying the request" $Colors.Info
    }
    
    try {
        $response = Invoke-RestMethod -Uri $OPENAI_API_URL -Method Post -Body $requestBody -Headers $headers
        
        $content = $response.choices[0].message.content
        
        # Validate response completeness before returning
        if ([string]::IsNullOrWhiteSpace($content)) {
            throw "Empty response received from ChatGPT"
        }
        
        # Check if response was cut off due to token limits
        $finishReason = $response.choices[0].finish_reason
        if ($finishReason -eq "length") {
            Write-ColorText "ERROR: Response was truncated due to token limit!" $Colors.Error
            Write-ColorText "The response was cut off. Please try with fewer files or contact support." $Colors.Warning
            throw "Response truncated due to token limit. Cannot process incomplete data."
        }
        
        return $content
    }
    catch {
        Write-Host ""
        Write-ColorText "Error communicating with OpenAI API: $($_.Exception.Message)" $Colors.Error
        
        # Show detailed error information for debugging
        try {
            if ($_.Exception.Response) {
                $errorStream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($errorStream)
                $errorDetails = $reader.ReadToEnd()
                if ($errorDetails) {
                    Write-ColorText "API Error Details: $errorDetails" $Colors.Warning
                } else {
                    Write-ColorText "No additional error details available" $Colors.Warning
                }
            }
        }
        catch {
            Write-ColorText "Could not read error details: $($_.Exception.Message)" $Colors.Warning
        }
        

        
        Write-ColorText "Common causes:" $Colors.Info
        Write-ColorText "1. Invalid API key or quota exceeded" $Colors.Warning
        Write-ColorText "2. Request too large (reduce folder size)" $Colors.Warning
        Write-ColorText "3. Unicode characters in request" $Colors.Warning
        Write-ColorText "4. Network connectivity issues" $Colors.Warning
        
        return $null
    }
}

function Apply-Organization {
    param([array]$SuggestedStructure, [string]$TargetPath)
    
    Write-ColorText "Applying organization changes..." $Colors.Info
    Write-Host ""
    
    $totalMoves = 0
    $successfulMoves = 0
    $errorMessages = @()
    
    try {
        foreach ($folder in $SuggestedStructure) {
            $folderPath = Join-Path $TargetPath $folder.folderName
            
            # Create folder if it doesn't exist
            if (-not (Test-Path $folderPath)) {
                Write-ColorText "Creating folder: $($folder.folderName)" $Colors.Info
                New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
            }
            
            # Move files to the folder
            foreach ($item in $folder.items) {
                $totalMoves++
                $sourcePath = Join-Path $TargetPath $item.name
                $destinationPath = Join-Path $folderPath $item.name
                
                try {
                    if (Test-Path $sourcePath) {
                        Write-ColorText "Moving: $($item.name) -> $($folder.folderName)/" $Colors.Secondary
                        Move-Item -Path $sourcePath -Destination $destinationPath -Force
                        $successfulMoves++
                    } else {
                        $errorMessages += "File not found: $($item.name)"
                    }
                }
                catch {
                    $errorMessages += "Failed to move $($item.name): $($_.Exception.Message)"
                }
            }
        }
        
        Write-Host ""
        Write-ColorText "Organization Complete!" $Colors.Success
        Write-ColorText "Successfully moved: $successfulMoves/$totalMoves files" $Colors.Info
        
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

function Process-FolderOrganization {
    param([array]$Items)
    
    Write-ColorText "Analyzing folder contents..." $Colors.Info
    Write-Host ""
    
    # Filter out folders - only organize files
    $files = $Items | Where-Object { $_.type -eq "file" }
    $fileCount = $files.Count
    
    Write-ColorText "Found $fileCount files to organize" $Colors.Info
    
    if ($fileCount -eq 0) {
        Write-ColorText "No files found to organize!" $Colors.Warning
        return
    }
    
    # Determine processing strategy
    if ($fileCount -le 75) {
        Write-ColorText "Small folder detected - using single-batch processing" $Colors.Success
        Process-SingleBatch -Files $files
    } else {
        Write-ColorText "Large folder detected - using multi-batch processing" $Colors.Success
        Process-MultiBatch -Files $files
    }
}

function Process-SingleBatch {
    param([array]$Files)
    
    Write-ColorText "Processing all $($Files.Count) files in single batch..." $Colors.Info
    Write-Host ""
    
    try {
        # Build JSON for single batch
        $jsonData = Build-BatchJson -Files $Files -ExistingStructure @()
        
        # Send to OpenAI
        $response = Send-ToOpenAI -JsonData $jsonData
        
        if ($null -eq $response) {
            Write-ColorText "Failed to get response from ChatGPT" $Colors.Error
            return
        }
        
        # Process response
        $structure = Process-AIResponse -JsonResponse $response
        
        if ($structure) {
            # Validate final structure
            $validatedStructure = Validate-FinalStructure -OriginalFiles $Files -OrganizedStructure $structure
            
            if ($validatedStructure) {
                Display-OrganizationTree -Structure $validatedStructure
                Confirm-AndApplyOrganization -Structure $validatedStructure
            }
        }
    }
    catch {
        Write-ColorText "Error in single-batch processing: $($_.Exception.Message)" "Red"
    }
}

function Process-MultiBatch {
    param([array]$Files)
    
    Write-ColorText "Starting multi-batch processing for $($Files.Count) files..." $Colors.Info
    Write-Host ""
    
    try {
        # Group files by type and sort by name (for display purposes)
        $groupedFiles = Group-FilesByType -Files $Files
        
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
            $batchResult = Process-Batch -Files $currentBatch -ExistingStructure $masterStructure -BatchNumber $batchNumber
            
            # If failed, retry once after 8 seconds
            if ($null -eq $batchResult) {
                Write-ColorText "Batch $batchNumber failed, retrying in 8 seconds..." $Colors.Warning
                Start-Sleep -Seconds 8
                $batchResult = Process-Batch -Files $currentBatch -ExistingStructure $masterStructure -BatchNumber $batchNumber
                
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
        
        # Final processing loop - handle any remaining unprocessed files
        Write-ColorText "Checking for any remaining unprocessed files..." $Colors.Info
        
        # Get all files that were successfully processed
        $processedFileNames = [System.Collections.ArrayList]@()
        foreach ($folder in $masterStructure) {
            foreach ($item in $folder.items) {
                [void]$processedFileNames.Add($item.name.ToLower())
            }
        }
        
        # Find unprocessed files
        $unprocessedFiles = [System.Collections.ArrayList]@()
        foreach ($file in $Files) {
            if (-not $processedFileNames.Contains($file.name.ToLower())) {
                [void]$unprocessedFiles.Add($file)
            }
        }
        
        if ($unprocessedFiles.Count -gt 0) {
            Write-ColorText "Found $($unprocessedFiles.Count) unprocessed files - processing in final batches..." $Colors.Warning
            
            # Process unprocessed files in batches of 75
            $finalFileIndex = 0
            $finalBatchNumber = 1
            $finalTotalBatches = [Math]::Ceiling($unprocessedFiles.Count / 75)
            
            while ($finalFileIndex -lt $unprocessedFiles.Count) {
                $finalBatchSize = [Math]::Min(75, ($unprocessedFiles.Count - $finalFileIndex))
                $finalBatch = $unprocessedFiles[$finalFileIndex..($finalFileIndex + $finalBatchSize - 1)]
                
                Write-ColorText "Processing final batch $finalBatchNumber/$finalTotalBatches ($($finalBatch.Count) files)..." $Colors.Info
                
                # Process with retry logic (use high batch numbers to avoid conflicts)
                $adjustedBatchNumber = 1000 + $finalBatchNumber
                $finalBatchResult = Process-Batch -Files $finalBatch -ExistingStructure $masterStructure -BatchNumber $adjustedBatchNumber
                
                if ($null -eq $finalBatchResult) {
                    Write-ColorText "Final batch $finalBatchNumber failed, retrying in 5 seconds..." $Colors.Warning
                    Start-Sleep -Seconds 5
                    $finalBatchResult = Process-Batch -Files $finalBatch -ExistingStructure $masterStructure -BatchNumber $adjustedBatchNumber
                }
                
                if ($finalBatchResult) {
                    $masterStructure = Merge-BatchResults -MasterStructure $masterStructure -BatchResult $finalBatchResult
                    Write-ColorText "Final batch $finalBatchNumber completed successfully" $Colors.Success
                } else {
                    Write-ColorText "Final batch $finalBatchNumber failed - some files may remain unorganized" $Colors.Error
                }
                
                $finalFileIndex += $finalBatchSize
                $finalBatchNumber++
                Write-Host ""
            }
        } else {
            Write-ColorText "All files were successfully processed in main batches" $Colors.Success
        }
        
        # Final validation and recovery
        Write-ColorText "Performing final validation..." $Colors.Info
        $finalStructure = Validate-FinalStructure -OriginalFiles $Files -OrganizedStructure $masterStructure
        
        if ($finalStructure) {
            Write-ColorText "Multi-batch processing completed successfully!" $Colors.Success
            Write-Host ""
            Display-OrganizationTree -Structure $finalStructure
            Confirm-AndApplyOrganization -Structure $finalStructure
        } else {
            # Show partial results even if validation failed
            Write-ColorText "Final validation failed, but showing partial results..." $Colors.Warning
            
            # Count successfully processed files
            $processedCount = 0
            foreach ($folder in $masterStructure) {
                $processedCount += $folder.items.Count
            }
            
            Write-ColorText "Successfully processed $processedCount out of $($Files.Count) files" $Colors.Info
            
            if ($masterStructure -and $masterStructure.Count -gt 0) {
                Write-Host ""
                Write-ColorText "Partial Organization Results:" $Colors.Info
                Display-OrganizationTree -Structure $masterStructure
                
                Write-Host ""
                Write-ColorText "Would you like to apply this partial organization? (Y/N)" $Colors.Question
                $response = Read-Host
                if ($response -eq 'Y' -or $response -eq 'y') {
                    Confirm-AndApplyOrganization -Structure $masterStructure
                } else {
                    Write-ColorText "Partial organization not applied" $Colors.Info
                }
            } else {
                Write-ColorText "No files were successfully processed" $Colors.Error
            }
        }
    }
    catch {
        Write-ColorText "Error in multi-batch processing: $($_.Exception.Message)" "Red"
    }
}

function Group-FilesByType {
    param([array]$Files)
    
    Write-ColorText "Grouping files by type and sorting by name..." $Colors.Info
    
    # Group files by extension, handling files without extensions
    $grouped = $Files | Group-Object { 
        if ([string]::IsNullOrEmpty($_.extension)) { 
            "(no extension)" 
        } else { 
            $_.extension 
        }
    } | Sort-Object Name
    
    $fileGroups = @()
    foreach ($group in $grouped) {
        $sortedFiles = $group.Group | Sort-Object name
        $fileGroups += [PSCustomObject]@{
            Extension = $group.Name
            Count = $group.Count
            Files = $sortedFiles
        }
    }
    
    Write-ColorText "Grouped into $($fileGroups.Count) file types:" $Colors.Success
    foreach ($group in $fileGroups) {
        Write-ColorText "  - $($group.Extension): $($group.Count) files" $Colors.Info
    }
    
    return $fileGroups
}

function Build-BatchJson {
    param([array]$Files, [array]$ExistingStructure)
    
    # Create minimal data structure for batch
    $minimalItems = @()
    foreach ($file in $Files) {
        if ([string]::IsNullOrEmpty($file.name)) {
            continue
        }
        
        $lastModified = [DateTime]$file.lastModified
        $fileData = @{
            name = $file.name
            ext = $file.extension
            size = if ($file.size -gt 100MB) { "large" } elseif ($file.size -gt 10MB) { "medium" } else { "small" }
            age = if ($lastModified -gt (Get-Date).AddDays(-30)) { "recent" } else { "old" }
        }
        
        $minimalItems += $fileData
    }
    
    # Include existing folder structure for context
    $existingFolders = @()
    foreach ($folder in $ExistingStructure) {
        if (![string]::IsNullOrEmpty($folder.folderName)) {
            $existingFolders += $folder.folderName
        }
    }
    
    $batchInfo = @{
        files = $minimalItems
        count = $minimalItems.Count
        existingFolders = $existingFolders
    }
    
    return $batchInfo | ConvertTo-Json -Depth 5
}

function Process-Batch {
    param([array]$Files, [array]$ExistingStructure, [int]$BatchNumber)
    
    try {
        # Build JSON for this batch
        $jsonData = Build-BatchJson -Files $Files -ExistingStructure $ExistingStructure
        
        # Send to OpenAI
        $response = Send-BatchToOpenAI -JsonData $jsonData -BatchNumber $BatchNumber -ExistingFolders ($ExistingStructure | ForEach-Object { $_.folderName })
        
        if ($null -eq $response) {
            Write-ColorText "Batch ${BatchNumber}: Failed to get AI response" $Colors.Error
            return $null
        }
        
        # Process AI response
        $batchStructure = Process-AIResponse -JsonResponse $response
        
        if ($batchStructure) {
            # Remove duplicates within this batch
            $cleanedBatch = Remove-DuplicateFileAssignments -Structure $batchStructure
            Write-ColorText "Batch ${BatchNumber}: Processed $($Files.Count) files into $($cleanedBatch.Count) folders" $Colors.Success
            return $cleanedBatch
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
            $existingFolder.items = $existingItems
        } else {
            # Add new folder to master structure
            [void]$MasterStructure.Add($batchFolder)
        }
    }
    
    return $MasterStructure
}

function Process-AIResponse {
    param([string]$JsonResponse)
    
    try {
        # Step 1: Clean and extract JSON from the response
        $cleanedJson = Extract-JsonFromResponse -Response $JsonResponse
        
        # Step 2: Parse JSON using built-in .NET classes
        $suggestedStructure = Parse-JsonResponse -JsonString $cleanedJson
        
        return $suggestedStructure
    }
    catch {
        Write-ColorText "Error processing AI response: $($_.Exception.Message)" $Colors.Error
        return $null
    }
}

function Validate-FinalStructure {
    param([array]$OriginalFiles, [array]$OrganizedStructure)
    
    Write-ColorText "Validating final organization structure..." $Colors.Info
    
    try {
        # Collect all files from organized structure
        $organizedFiles = [System.Collections.ArrayList]@()
        foreach ($folder in $OrganizedStructure) {
            foreach ($item in $folder.items) {
                [void]$organizedFiles.Add($item.name.ToLower())
            }
        }
        
        # Check for missing files
        $missingFiles = [System.Collections.ArrayList]@()
        foreach ($originalFile in $OriginalFiles) {
            if (-not $organizedFiles.Contains($originalFile.name.ToLower())) {
                [void]$missingFiles.Add($originalFile)
            }
        }
        
        # Handle missing files if any
        if ($missingFiles.Count -gt 0) {
            Write-ColorText "Found $($missingFiles.Count) missing files - recovering..." $Colors.Warning
            $recoveredStructure = Recover-MissingFiles -MissingFiles $missingFiles.ToArray() -ExistingStructure $OrganizedStructure
            
            if ($recoveredStructure) {
                Write-ColorText "Successfully recovered all missing files" $Colors.Success
                return $recoveredStructure
            } else {
                Write-ColorText "Failed to recover missing files" $Colors.Error
                return $null
            }
        }
        
        # Check for duplicates
        $duplicateCheck = Remove-DuplicateFileAssignments -Structure $OrganizedStructure
        
        Write-ColorText "Final validation passed - all files accounted for" $Colors.Success
        return $duplicateCheck
    }
    catch {
        Write-ColorText "Error in final validation: $($_.Exception.Message)" $Colors.Error
        return $null
    }
}

function Recover-MissingFiles {
    param([array]$MissingFiles, [array]$ExistingStructure)
    
    Write-ColorText "Asking AI to organize $($MissingFiles.Count) missed files..." $Colors.Info
    
    try {
        # Build recovery JSON
        $recoveryData = Build-BatchJson -Files $MissingFiles -ExistingStructure $ExistingStructure
        
        # Send to AI for recovery
        $response = Send-RecoveryToOpenAI -JsonData $recoveryData -ExistingStructure $ExistingStructure
        
        if ($response) {
            $recoveryStructure = Process-AIResponse -JsonResponse $response
            
            if ($recoveryStructure) {
                # Merge recovery results with existing structure
                $masterStructure = [System.Collections.ArrayList]@($ExistingStructure)
                $finalStructure = Merge-BatchResults -MasterStructure $masterStructure -BatchResult $recoveryStructure
                
                Write-ColorText "Recovery completed successfully" $Colors.Success
                return $finalStructure
            }
        }
        
        Write-ColorText "AI recovery failed" $Colors.Error
        return $null
    }
    catch {
        Write-ColorText "Error in recovery process: $($_.Exception.Message)" $Colors.Error
        return $null
    }
}

# Helper function to remove duplicate file assignments from organization structure
function Remove-DuplicateFileAssignments {
    param([array]$Structure)
    
    Write-ColorText "Validating organization structure for duplicates..." $Colors.Info
    
    # Build a simple hashtable to track all folders for each file
    $fileToFolders = @{}
    
    foreach ($folder in $Structure) {
        foreach ($item in $folder.items) {
            $fileName = $item.name.ToLower()
            
            if (-not $fileToFolders.ContainsKey($fileName)) {
                $fileToFolders[$fileName] = @{
                    originalName = $item.name
                    folderList = [System.Collections.ArrayList]@()
                }
            }
            
            # Use ArrayList.Add() to avoid concatenation issues
            [void]$fileToFolders[$fileName].folderList.Add($folder.folderName)
        }
    }
    
    # Find conflicts (files in multiple folders)
    $conflicts = [System.Collections.ArrayList]@()
    foreach ($fileName in $fileToFolders.Keys) {
        $fileInfo = $fileToFolders[$fileName]
        if ($fileInfo.folderList.Count -gt 1) {
            $conflictObj = [PSCustomObject]@{
                fileName = $fileInfo.originalName
                folders = $fileInfo.folderList.ToArray()
            }
            [void]$conflicts.Add($conflictObj)
        }
    }
    
    # If conflicts found, ask AI to resolve them
    $aiDecisions = @{}
    if ($conflicts.Count -gt 0) {
        Write-ColorText "Found $($conflicts.Count) duplicate file assignments - asking AI to resolve..." $Colors.Warning
        $aiDecisions = Resolve-ConflictsWithAI -Conflicts $conflicts
    }
    
    # Second pass: build cleaned structure using AI decisions
    $finalFileAssignments = @{}
    $duplicatesResolved = 0
    $cleanedStructure = [System.Collections.ArrayList]@()
    
    foreach ($folder in $Structure) {
        $cleanedItems = [System.Collections.ArrayList]@()
        
        foreach ($item in $folder.items) {
            $fileName = $item.name.ToLower()
            
            if ($finalFileAssignments.ContainsKey($fileName)) {
                # Already assigned, skip
                continue
            }
            
            # Check if this file had conflicts
            $conflict = $conflicts | Where-Object { $_.fileName -eq $item.name }
            if ($conflict) {
                # Use AI decision
                $chosenFolder = $aiDecisions[$item.name]
                if ($folder.folderName -eq $chosenFolder) {
                    $finalFileAssignments[$fileName] = $folder.folderName
                    [void]$cleanedItems.Add($item)
                    Write-ColorText "  AI chose '$chosenFolder' for '$($item.name)'" $Colors.Success
                    $duplicatesResolved++
                }
            } else {
                # No conflict, add normally
                $finalFileAssignments[$fileName] = $folder.folderName
                [void]$cleanedItems.Add($item)
            }
        }
        
        # Only include folders that have items after deduplication
        if ($cleanedItems.Count -gt 0) {
            $folderObj = [PSCustomObject]@{
                folderName = $folder.folderName
                items = $cleanedItems.ToArray()
            }
            [void]$cleanedStructure.Add($folderObj)
        } else {
            Write-ColorText "  Removing empty folder: '$($folder.folderName)' (all files were duplicates)" $Colors.Warning
        }
    }
    
    if ($duplicatesResolved -gt 0) {
        Write-ColorText "AI resolved $duplicatesResolved duplicate file assignments" $Colors.Success
    } else {
        Write-ColorText "No duplicate file assignments found" $Colors.Success
    }
    
    return $cleanedStructure
}

# Helper function to resolve duplicate file conflicts using AI
function Resolve-ConflictsWithAI {
    param([array]$Conflicts)
    
    # Build conflict resolution prompt
    $conflictList = [System.Collections.ArrayList]@()
    foreach ($conflict in $Conflicts) {
        $folders = $conflict.folders -join " OR "
        [void]$conflictList.Add("File: '$($conflict.fileName)' appears in: $folders")
    }
    
    $conflictPrompt = @"
Resolve these duplicate file assignments by choosing the BEST folder for each file.

Rules:
- Choose the most specific, appropriate folder for each file type
- Consider file extensions and naming patterns
- Prefer descriptive folder names over generic ones

Conflicts to resolve:
$($conflictList -join "`n")

IMPORTANT: You MUST respond with ONLY a valid JSON object. Do not include any explanations, markdown formatting, or other text.

Required format (example):
{"filename1.ext": "ChosenFolder", "filename2.ext": "ChosenFolder"}

Your response:
"@
    
    $requestBody = @{
        model = "gpt-4o-mini"
        messages = @(
            @{
                role = "system"
                content = "You are an expert at file organization. You MUST respond with ONLY valid JSON - no explanations, no markdown, no extra text. Choose the most logical folder for each file based on its name and type."
            },
            @{
                role = "user"
                content = $conflictPrompt
            }
        )
        max_tokens = 16384
        temperature = 0.1
    } | ConvertTo-Json -Depth 10
    
    $headers = @{
        "Authorization" = "Bearer $OPENAI_API_KEY"
        "Content-Type" = "application/json"
    }
    
    try {
        Write-ColorText "Asking AI to resolve conflicts..." $Colors.Info
        $response = Invoke-RestMethod -Uri $OPENAI_API_URL -Method Post -Body $requestBody -Headers $headers
        $content = $response.choices[0].message.content
        
        # Parse AI response as JSON with error handling
        Write-ColorText "AI Response: $content" $Colors.Info
        
        try {
            # Clean the response (remove markdown if present)
            $cleanContent = $content
            if ($content -match '```json\s*([\s\S]*?)\s*```') {
                $cleanContent = $matches[1].Trim()
            }
            
            $aiDecisions = $cleanContent | ConvertFrom-Json
            
            # Convert to hashtable for easier lookup
            $decisionsHash = @{}
            $aiDecisions.PSObject.Properties | ForEach-Object {
                $decisionsHash[$_.Name] = $_.Value
            }
        }
        catch {
            Write-ColorText "Failed to parse AI response as JSON: $($_.Exception.Message)" $Colors.Error
            Write-ColorText "Raw AI response: '$content'" $Colors.Warning
            throw "AI returned invalid JSON for conflict resolution"
        }
        
        # Validate that all conflicted files have decisions
        $missingDecisions = @()
        foreach ($conflict in $Conflicts) {
            if (-not $decisionsHash.ContainsKey($conflict.fileName)) {
                $missingDecisions += $conflict.fileName
            }
        }
        
        if ($missingDecisions.Count -gt 0) {
            Write-ColorText "WARNING: AI didn't provide decisions for: $($missingDecisions -join ', ')" $Colors.Warning
            Write-ColorText "Using fallback logic for missing decisions" $Colors.Warning
            
            # Add fallback decisions for missing files
            foreach ($conflict in $Conflicts) {
                if (-not $decisionsHash.ContainsKey($conflict.fileName)) {
                    $decisionsHash[$conflict.fileName] = $conflict.folders[0]
                }
            }
        }
        
        Write-ColorText "AI successfully resolved all conflicts" $Colors.Success
        return $decisionsHash
    }
    catch {
        Write-ColorText "AI conflict resolution failed: $($_.Exception.Message)" $Colors.Error
        Write-ColorText "Falling back to first-come-first-served resolution" $Colors.Warning
        
        # Fallback: use first assignment for each file
        $fallbackDecisions = @{}
        foreach ($conflict in $Conflicts) {
            $fallbackDecisions[$conflict.fileName] = $conflict.folders[0]
        }
        return $fallbackDecisions
    }
}



# Helper function to extract JSON from various response formats
function Extract-JsonFromResponse {
    param([string]$Response)
    
    $cleaned = $Response.Trim()
    
    # Remove any leading/trailing whitespace and normalize line endings
    $cleaned = $cleaned -replace '\r\n', '\n' -replace '\r', '\n'
    
    # Pattern 1: JSON in markdown code block with json language
    if ($cleaned -match '```json\s*\n([\s\S]*?)\n\s*```') {
        Write-ColorText "Found JSON in markdown code block" $Colors.Success
        return $matches[1].Trim()
    }
    
    # Pattern 2: JSON in generic markdown code block
    if ($cleaned -match '```\s*\n(\[[\s\S]*?\])\s*\n```') {
        Write-ColorText "Found JSON array in generic code block" $Colors.Success
        return $matches[1].Trim()
    }
    
    # Pattern 3: Direct JSON array (most common for our prompt)
    if ($cleaned.StartsWith('[') -and $cleaned.EndsWith(']')) {
        Write-ColorText "Found JSON array in response" $Colors.Success
        return $cleaned.Trim()
    }
    
    # Pattern 4: Remove any remaining markdown formatting
    if ($cleaned.StartsWith('```')) {
        $cleaned = $cleaned -replace '^```[a-zA-Z]*\s*', '' -replace '```\s*$', ''
        $cleaned = $cleaned.Trim()
        
        # Try to find JSON array after cleanup
        if ($cleaned -match '(\[[\s\S]*?\])') {
            Write-ColorText "Found JSON array after markdown cleanup" $Colors.Success
            return $matches[1].Trim()
        }
    }
    
    # If no patterns match, return the cleaned response as-is
    Write-ColorText "No specific JSON pattern found, using cleaned response" $Colors.Warning
    return $cleaned
}

# Helper function to detect if JSON appears to be truncated
function Test-JsonTruncation {
    param([string]$JsonString)
    
    $trimmed = $JsonString.Trim()
    
    # If response is very short (less than 100 chars), be more lenient
    if ($trimmed.Length -lt 100) {
        # Only check basic structure for very short responses
        if ($trimmed.StartsWith('[') -and $trimmed.EndsWith(']')) {
            return $false  # Likely complete short array
        }
        if ($trimmed.StartsWith('{') -and $trimmed.EndsWith('}')) {
            return $false  # Likely complete short object
        }
        # If it's very short and doesn't match basic patterns, might be truncated
        if ($trimmed.Length -lt 20) {
            return $true
        }
    }
    
    # Check if it starts with [ but doesn't end with ]
    if ($trimmed.StartsWith('[') -and -not $trimmed.EndsWith(']')) {
        return $true
    }
    
    # Check if it starts with { but doesn't end with }
    if ($trimmed.StartsWith('{') -and -not $trimmed.EndsWith('}')) {
        return $true
    }
    
    # Check for incomplete JSON structures (unmatched brackets)
    $openBrackets = ($trimmed.ToCharArray() | Where-Object { $_ -eq '[' }).Count
    $closeBrackets = ($trimmed.ToCharArray() | Where-Object { $_ -eq ']' }).Count
    $openBraces = ($trimmed.ToCharArray() | Where-Object { $_ -eq '{' }).Count
    $closeBraces = ($trimmed.ToCharArray() | Where-Object { $_ -eq '}' }).Count
    
    # Only flag as truncated if there's a significant imbalance
    if ($openBrackets -ne $closeBrackets -or $openBraces -ne $closeBraces) {
        # For responses longer than 1000 chars, be more strict
        if ($trimmed.Length -gt 1000) {
            return $true
        }
        # For shorter responses, check if the imbalance is significant
        $bracketImbalance = [Math]::Abs($openBrackets - $closeBrackets)
        $braceImbalance = [Math]::Abs($openBraces - $closeBraces)
        if ($bracketImbalance -gt 1 -or $braceImbalance -gt 1) {
            return $true
        }
    }
    
    # Additional check: Look for obvious truncation patterns
    if ($trimmed.EndsWith('...') -or $trimmed.EndsWith('"...') -or $trimmed.EndsWith(',')) {
        return $true
    }
    
    return $false
}

# Helper function to attempt repair of truncated JSON
function Repair-TruncatedJson {
    param([string]$JsonString)
    
    $repaired = $JsonString.Trim()
    
    # If it starts with [ but doesn't end with ], try to close it
    if ($repaired.StartsWith('[') -and -not $repaired.EndsWith(']')) {
        # Find the last complete object and close the array
        $lastCompleteObject = $repaired.LastIndexOf('}')
        if ($lastCompleteObject -gt 0) {
            $repaired = $repaired.Substring(0, $lastCompleteObject + 1) + ']'
            Write-ColorText "Attempted to repair truncated JSON array" $Colors.Info
        }
    }
    
    # If it starts with { but doesn't end with }, try to close it
    elseif ($repaired.StartsWith('{') -and -not $repaired.EndsWith('}')) {
        # Try to close the object
        $repaired = $repaired + '}'
        Write-ColorText "Attempted to repair truncated JSON object" $Colors.Info
    }
    
    return $repaired
}



# Clean, simple JSON parsing using PowerShell native ConvertFrom-Json
function Parse-JsonResponse {
    param([string]$JsonString)
    
    # Check for minimum expected structure first
    if (-not ($JsonString.Contains('folderName') -and $JsonString.Contains('items'))) {
        Write-ColorText "ERROR: Response missing required structure (folderName/items)" $Colors.Error
        throw "Invalid response format. Expected folder structure not found."
    }
    
    try {
        Write-ColorText "Parsing JSON with PowerShell ConvertFrom-Json..." $Colors.Info
        
        # Clean the JSON string
        $cleanedJson = $JsonString.Trim()
        # Remove any BOM or invisible characters
        $cleanedJson = $cleanedJson -replace '^\uFEFF', ''
        # Normalize line endings
        $cleanedJson = $cleanedJson -replace '\r\n', '\n' -replace '\r', '\n'
        
        # Use PowerShell's built-in ConvertFrom-Json for simpler object access
        $jsonData = $cleanedJson | ConvertFrom-Json
        
        # Convert to PowerShell objects and validate structure
        $folders = @()
        
        # Handle both array and single object responses
        $itemsToProcess = @()
        if ($jsonData -is [array]) {
            $itemsToProcess = $jsonData
        } else {
            $itemsToProcess = @($jsonData)
        }
        
        foreach ($item in $itemsToProcess) {
            if ($item.folderName -and $item.items) {
                $folderObj = [PSCustomObject]@{
                    folderName = $item.folderName
                    items = @()
                }
                
                foreach ($fileItem in $item.items) {
                    if ($fileItem.name) {
                        $fileName = $fileItem.name
                        $extension = if ($fileName.Contains('.')) { 
                            [System.IO.Path]::GetExtension($fileName) 
                        } else { 
                            "" 
                        }
                        
                        $folderObj.items += [PSCustomObject]@{
                            name = $fileName
                            extension = $extension
                        }
                    }
                }
                
                if ($folderObj.items.Count -gt 0) {
                    $folders += $folderObj
                }
            }
        }
        
        if ($folders.Count -eq 0) {
            throw "No valid folders found in JSON response"
        }
        
        Write-ColorText "Successfully parsed JSON with $($folders.Count) folders" $Colors.Success
        return $folders
        
    }
    catch [System.Exception] {
        Write-ColorText "JSON parsing failed: $($_.Exception.Message)" $Colors.Error
        
        # Check if response might be truncated
        $isTruncated = Test-JsonTruncation -JsonString $JsonString
        if ($isTruncated) {
            Write-ColorText "ERROR: Response appears to be truncated!" $Colors.Error
            Write-ColorText "TidyAI requires complete responses. Please try again." $Colors.Warning
            throw "Response was truncated. Cannot process incomplete data."
        } else {
            throw "JSON parsing failed: $($_.Exception.Message)"
        }
    }
}

# Manual parsing function removed - now using Newtonsoft.Json for all JSON parsing

# Helper function to get partial folder information from severely truncated JSON
function Get-PartialFolderInfo {
    param([string]$JsonString)
    
    $folders = @()
    
    try {
        # Look for any folder name patterns, even if incomplete
        $folderNamePattern = '"folderName"\s*:\s*"([^"]+)"'
        $folderMatches = [regex]::Matches($JsonString, $folderNamePattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        # Look for any file name patterns
        $fileNamePattern = '"name"\s*:\s*"([^"]+)"'
        $fileMatches = [regex]::Matches($JsonString, $fileNamePattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        if ($folderMatches.Count -gt 0 -and $fileMatches.Count -gt 0) {
            Write-ColorText "Found $($folderMatches.Count) folder names and $($fileMatches.Count) file names" $Colors.Info
            
            # Create a single folder with all found files (best effort)
            $folderName = $folderMatches[0].Groups[1].Value.Trim()
            $items = @()
            
            foreach ($fileMatch in $fileMatches) {
                $fileName = $fileMatch.Groups[1].Value.Trim()
                $extension = if ($fileName.Contains('.')) { 
                    [System.IO.Path]::GetExtension($fileName) 
                } else { 
                    "" 
                }
                
                $items += [PSCustomObject]@{
                    name = $fileName
                    extension = $extension
                }
            }
            
            if ($items.Count -gt 0) {
                $folders += [PSCustomObject]@{
                    folderName = $folderName
                    items = $items
                }
                
                Write-ColorText "Created partial folder '$folderName' with $($items.Count) files" $Colors.Success
            }
        }
    }
    catch {
        Write-ColorText "Error in partial extraction: $($_.Exception.Message)" $Colors.Error
    }
    
    return $folders
}

# Helper function to display the organization tree
function Display-OrganizationTree {
    param([array]$Structure)
    
    Write-ColorText "Suggested Folder Organization:" $Colors.Primary
    Write-Host ""
    Write-ColorText "[DIR] Organized Folder Structure" $Colors.Accent
    Write-ColorText "|" $Colors.Info
    
    if ($Structure -and $Structure.Count -gt 0) {
        $folderCount = $Structure.Count
        
        for ($i = 0; $i -lt $folderCount; $i++) {
            $folder = $Structure[$i]
            $isLast = ($i -eq ($folderCount - 1))
            
            $prefix = if ($isLast) { "+-- " } else { "+-- " }
            $continuation = if ($isLast) { "    " } else { "|   " }
            
            Write-ColorText "$prefix$(Get-FileEmoji 'folder') $($folder.folderName)" $Colors.Secondary
            
            if ($folder.items -and $folder.items.Count -gt 0) {
                $itemCount = $folder.items.Count
                
                for ($j = 0; $j -lt $itemCount; $j++) {
                    $item = $folder.items[$j]
                    $isLastItem = ($j -eq ($itemCount - 1))
                    
                    $itemPrefix = if ($isLastItem) { "$continuation+-- " } else { "$continuation+-- " }
                    $emoji = Get-FileEmoji $item.extension
                    
                    Write-ColorText "$itemPrefix$emoji $($item.name)" $Colors.Info
                }
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

# Helper function to confirm and apply organization
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
        Apply-Organization -SuggestedStructure $Structure -TargetPath $script:CurrentTargetPath
    } else {
        Write-ColorText "Organization cancelled. No files were moved." $Colors.Warning
    }
    
    Write-Host ""
}

# ==============================================================================
# MAIN EXECUTION
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
    
    # Step 1: Scan the folder
    $items = Scan-Folder -Path $TargetFolder
    
    if ($items.Count -eq 0) {
        Write-ColorText "The folder appears to be empty or inaccessible." $Colors.Warning
        Read-Host "Press Enter to exit"
        return
    }
    
    # Step 2: Process folder organization using multi-batch system
    Process-FolderOrganization -Items $items
    
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
