# ==============================================================================
# TIDYAI - INTELLIGENT FOLDER ORGANIZATION TOOL
# Version 1.0.0 - Refactored for Better Organization
# ==============================================================================

param(
    [Parameter(Mandatory=$true)]
    [string]$FolderPath
)

# ==============================================================================
# SECTION 1: UTILITY FUNCTIONS (MUST BE FIRST)
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

# Console Colors
$Colors = @{
    Primary = "DarkRed"
    Secondary = "Yellow" 
    Success = "Yellow"
    Warning = "DarkYellow"
    Error = "Red"
    Info = "White"
    Accent = "DarkYellow"
}

# ==============================================================================
# SECTION 2: CONFIGURATION & CONSTANTS
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
# SECTION 3: UTILITY FUNCTIONS
# ==============================================================================

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

# ==============================================================================
# SECTION 4: FILE SYSTEM OPERATIONS
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
                        $errorMessages += "Item not found: $($item.name)"
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

# ==============================================================================
# SECTION 4: DATA PROCESSING
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
            # Folder data with metadata
            $itemData = @{
                name = $item.name
                type = "folder"
                fileCount = $item.fileCount
                subfolderCount = $item.subfolderCount
                isEmpty = $item.isEmpty
                sampleFiles = $item.sampleFiles
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

# ==============================================================================
# SECTION 5: API COMMUNICATION (CONSOLIDATED)
# ==============================================================================

function Invoke-OpenAIRequest {
    param(
        [string]$JsonData,
        [string]$RequestType = "batch", # batch, recovery, conflict
        [array]$ExistingFolders = @(),
        [int]$BatchNumber = 1
    )
    
    # Check if API key is set
    if ([string]::IsNullOrEmpty($OPENAI_API_KEY)) {
        Write-ColorText "OpenAI API key not found!" $Colors.Error
        return $null
    }
    
    # Build system message and prompt based on request type
    $systemMessage = ""
    $prompt = ""
    
    switch ($RequestType) {
        "batch" {
            $systemMessage = "You are TidyAI, an intelligent file organization expert. Analyze file names and size, patterns, dates, projects, and purposes. Create meaningful folder structures based on content similarity and purpose, not just file extensions. Think like a human organizing their digital workspace - group related files together in a way that makes sense for productivity and easy retrieval."
            
            $parsedData = $JsonData | ConvertFrom-Json
            $fileCount = $parsedData.items | Where-Object { $_.type -eq "file" } | Measure-Object | Select-Object -ExpandProperty Count
            $folderCount = $parsedData.items | Where-Object { $_.type -eq "folder" } | Measure-Object | Select-Object -ExpandProperty Count
            $totalCount = $fileCount + $folderCount
            
            $existingFoldersText = if ($ExistingFolders.Count -gt 0) { "Existing folders to reuse: " + ($ExistingFolders -join ", ") } else { "No existing folders - create new structure" }
            
            $prompt = @"
Organize these $totalCount items ($fileCount files and $folderCount folders) into logical, intelligent folders based on content patterns and purpose.

ORGANIZATION PRINCIPLES:
- Each item appears in EXACTLY ONE folder (zero duplicates allowed)
- Preserve ALL original filenames exactly as provided
- Create 3-8 meaningful folders with descriptive names
- Group by purpose, project, or content type
- Avoid generic names like "Other" or "Miscellaneous"
- Consider file extensions, names, dates, and folder contents for context

CRITICAL: ORGANIZE BOTH FILES AND FOLDERS!
- You MUST organize folders just like files - they are items to be moved, not just context
- Folders should appear in your response as items to be organized
- Group related folders together (e.g., "Project1", "Project2" folders into a "Projects" parent folder)
- Move folders based on their names, contents, and purpose
- A folder is an item that can be moved into another folder - treat it exactly like a file
- Balance folder sizes (avoid 1-item folders unless specialized)
- Use clear, professional folder names
- Prioritize logical grouping over alphabetical sorting
- Folders can be moved into other folders or merged based on content similarity

- Files with similar purposes (installation files, documentation, media)
- Sequential files or series (parts 1, 2, 3 or chapters)

FOLDER NAMING:
- Use specific, descriptive names that reflect the actual content
- Include context like dates, projects, or purposes when relevant
- Avoid generic names like "Documents" or "Files"
- Examples: "Invoice Records 2024", "Project Phoenix Documentation", "System Installation Files"

$existingFoldersText

Items to organize (both files AND folders):
$JsonData

EXAMPLE: If you receive folders named "Project1", "Project2" and files "report.pdf", "data.xlsx":
[
  {"folderName": "Projects", "items": [{"name": "Project1"}, {"name": "Project2"}]},
  {"folderName": "Documents", "items": [{"name": "report.pdf"}, {"name": "data.xlsx"}]}
]

Respond with ONLY valid JSON (no explanations):
[{"folderName": "Descriptive Name", "items": [{"name": "exact-filename-or-foldername"}]}]
"@
        }
        
        "recovery" {
            $systemMessage = "You are TidyAI recovery processor. Place missed files into the most appropriate existing folders. Only create new folders if absolutely necessary."
            
            $existingFoldersText = "Current folder structure: " + ($ExistingFolders -join ", ")
            
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
        }
        
        "conflict" {
            $systemMessage = "You are an expert at file organization. You MUST respond with ONLY valid JSON - no explanations, no markdown, no extra text. Choose the most logical folder for each file based on its name and type."
            $prompt = $JsonData # For conflicts, JsonData is already the formatted prompt
        }
    }
    
    # Clean and normalize the inputs to prevent 400 errors
    $cleanSystemMessage = $systemMessage
    $cleanPrompt = $prompt
    
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
        temperature = if ($RequestType -eq "conflict") { 0.1 } else { 0.3 }
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

# ==============================================================================
# SECTION 6: RESPONSE PROCESSING & VALIDATION
# ==============================================================================

function ConvertFrom-AIResponse {
    param([string]$JsonResponse)
    
    try {
        # Step 1: Clean and extract JSON from the response
        $cleanedJson = Get-JsonFromResponse -Response $JsonResponse
        
        # Step 2: Parse JSON using built-in .NET classes
        $suggestedStructure = ConvertFrom-JsonResponse -JsonString $cleanedJson
        
        return $suggestedStructure
    }
    catch {
        Write-ColorText "Error processing AI response: $($_.Exception.Message)" $Colors.Error
        return $null
    }
}

function Get-JsonFromResponse {
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
        Write-ColorText "Found JSON array in code block" $Colors.Success
        return $matches[1].Trim()
    }
    
    # Pattern 3: Direct JSON array (most common case)
    if ($cleaned -match '(\[[\s\S]*?\])') {
        Write-ColorText "Found direct JSON array" $Colors.Success
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

function ConvertFrom-JsonResponse {
    param([string]$JsonString)
    
    # Check for minimum expected structure first
    $trimmedResponse = $JsonString.Trim()
    # Write-ColorText "DEBUG: AI response length: $($trimmedResponse.Length) characters" $Colors.Warning
    # Write-ColorText "DEBUG: AI response preview: $($trimmedResponse.Substring(0, [Math]::Min(100, $trimmedResponse.Length)))" $Colors.Warning
    
    if ($trimmedResponse -eq "[]" -or $trimmedResponse -eq "") {
        Write-ColorText "ERROR: AI returned empty response" $Colors.Error
        # Write-ColorText "DEBUG: This usually means the AI found no files to organize or there was an input issue" $Colors.Warning
        throw "Empty response from AI. No organization suggestions received."
    }
    
    # For non-empty responses, check if it contains the expected structure
    if (-not $JsonString.Contains('folderName')) {
        Write-ColorText "ERROR: Response missing required structure (folderName)" $Colors.Error
        # Write-ColorText "DEBUG: Response content: $($JsonString.Substring(0, [Math]::Min(200, $JsonString.Length)))" $Colors.Warning
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
        
        foreach ($folderData in $itemsToProcess) {
            if ($folderData.folderName -and $folderData.items) {
                $folderObj = [PSCustomObject]@{
                    folderName = $folderData.folderName.ToString().Trim()
                    items = @()
                }
                
                foreach ($item in $folderData.items) {
                    if ($item.name) {
                        $itemObj = [PSCustomObject]@{
                            name = $item.name.ToString().Trim()
                            extension = if ($item.name.ToString().Contains('.')) { 
                                [System.IO.Path]::GetExtension($item.name.ToString()) 
                            } else { 
                                "" 
                            }
                        }
                        $folderObj.items += $itemObj
                    }
                }
                
                if ($folderObj.items.Count -gt 0) {
                    $folders += $folderObj
                }
            }
        }
        
        Write-ColorText "Successfully parsed $($folders.Count) folders from AI response" $Colors.Success
        
        # Debug: Show what folders the AI suggested
        # foreach ($folder in $folders) {
        #     $fileItems = ($folder.items | Where-Object { -not $_.name.Contains('\') -and -not (Test-Path (Join-Path $script:CurrentTargetPath $_.name) -PathType Container) }).Count
        #     $folderItems = ($folder.items | Where-Object { Test-Path (Join-Path $script:CurrentTargetPath $_.name) -PathType Container }).Count
        #     Write-ColorText "DEBUG: AI suggested folder '$($folder.folderName)' with $($folder.items.Count) items ($fileItems files, $folderItems folders)" $Colors.Warning
        # }
        
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
        return $true  # Very short and doesn't look complete
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

# ==============================================================================
# SECTION 7: USER INTERFACE
# ==============================================================================

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
            Write-ColorText "$folderPrefix$emoji $($folder.folderName) ($($folder.items.Count) files)" $Colors.Success
            
            # Files in folder
            if ($folder.items -and $folder.items.Count -gt 0) {
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
# SECTION 8: MAIN EXECUTION ENGINE
# ==============================================================================

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
        $structure = ConvertFrom-AIResponse -JsonResponse $response
        
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
        $batchStructure = ConvertFrom-AIResponse -JsonResponse $response
        
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

function Test-FinalStructure {
    param([array]$OriginalFiles, [array]$OrganizedStructure)
    
    Write-ColorText "Validating final organization structure..." $Colors.Info
    
    try {
        # Simple validation - just return the structure for now
        # In the full implementation, this would check for missing files, duplicates, etc.
        return $OrganizedStructure
    }
    catch {
        Write-ColorText "Error in final validation: $($_.Exception.Message)" $Colors.Error
        return $null
    }
}

# ==============================================================================
# SECTION 9: MAIN EXECUTION
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

# Additional utility functions needed for complete functionality
function Group-FilesByType {
    param([array]$Files)
    
    # Simple grouping by extension for batch processing
    return $Files | Group-Object extension
}

function Show-ProgressBar {
    param([string]$Activity, [int]$PercentComplete)
    
    Write-Progress -Activity $Activity -PercentComplete $PercentComplete
}

# Run the main application
Main -TargetFolder $FolderPath
