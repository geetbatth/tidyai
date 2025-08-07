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
        [string]$Color = $Colors.Info,
        [switch]$NoNewline
    )
    
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
    
    # Create rich data structure with full context for better AI analysis
    $enrichedItems = @()
    foreach ($item in $Items) {
        $lastModified = [DateTime]$item.lastModified
        $enrichedItems += @{
            name = $item.name
            type = $item.type
            extension = $item.extension
            size = $item.size
            lastModified = $item.lastModified
            fullPath = $item.fullPath
            # Add helpful analysis fields
            sizeCategory = if ($item.size -gt 100MB) { "large" } elseif ($item.size -gt 10MB) { "medium" } else { "small" }
            ageCategory = if ($lastModified -gt (Get-Date).AddDays(-7)) { "recent" } elseif ($lastModified -gt (Get-Date).AddDays(-30)) { "current" } elseif ($lastModified -gt (Get-Date).AddDays(-365)) { "old" } else { "archived" }
            year = $lastModified.Year
            month = $lastModified.Month
        }
    }
    
    $folderInfo = @{
        folderPath = $FolderPath
        folderName = Split-Path $FolderPath -Leaf
        totalItems = $Items.Count
        scanDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        items = $enrichedItems
        # Add folder-level analysis
        folderType = if ($FolderPath -match "Desktop") { "Desktop" } elseif ($FolderPath -match "Downloads?") { "Downloads" } elseif ($FolderPath -match "Documents?") { "Documents" } else { "General" }
    }
    
    return $folderInfo | ConvertTo-Json -Depth 10
}

function Send-ToOpenAI {
    param([string]$JsonData)
    
    Write-ColorText "Sending data to ChatGPT for analysis..." $Colors.Info
    Write-Host ""
    
    # Check if API key is set
    if ([string]::IsNullOrEmpty($OPENAI_API_KEY)) {
        Write-ColorText "OpenAI API key not found!" $Colors.Error
        Write-ColorText "Please ensure the TidyAIOpenAIAPIKey environment variable is set." $Colors.Warning
        Write-ColorText "You can set it by running the installer again or manually setting it in Windows." $Colors.Info
        return $null
    }
    
    # Parse the JSON to check item count and analyze patterns
    $data = $JsonData | ConvertFrom-Json
    $itemCount = $data.items.Count
    
    # Analyze folder context and patterns
    $folderType = if ($data.folderPath -match "Desktop") { "Desktop" } 
                  elseif ($data.folderPath -match "Downloads?") { "Downloads" }
                  elseif ($data.folderPath -match "Documents?") { "Documents" }
                  elseif ($data.folderPath -match "Pictures?") { "Pictures" }
                  else { "General" }
    
    # Detect file patterns
    $extensions = $data.items | Where-Object { $_.type -eq "file" } | Group-Object extension | Sort-Object Count -Descending | Select-Object -First 5
    $topExtensions = ($extensions | ForEach-Object { $_.Name }) -join ", "
    
    # Detect date patterns (files from same time periods)
    $recentFiles = ($data.items | Where-Object { $_.type -eq "file" -and [DateTime]$_.lastModified -gt (Get-Date).AddDays(-30) }).Count
    $oldFiles = $itemCount - $recentFiles
    
    # Enhanced prompt for intelligent file organization
    $prompt = @"
First, analyze the entire collection of $itemCount files to understand the overall content patterns, file types, and user context. Then create an optimal folder structure based on your analysis.

ANALYSIS PHASE:
- Survey all file extensions to identify the primary file types present
- Examine naming patterns to understand user workflows and projects
- Assess the volume and distribution of different file categories
- Identify any obvious groupings or themes in the file collection
- Consider the user's likely use cases based on the file mix

ORGANIZATION PRINCIPLES:
- Each file appears in EXACTLY ONE folder (zero duplicates allowed)
- Preserve ALL original filenames exactly as provided
- Create intuitive folder names that immediately convey purpose
- Create 3-8 folders based on natural content groupings
- Prioritize user workflow and accessibility

PRIORITIZATION HIERARCHY (in order of importance):
1. FILE EXTENSION (highest priority) - Group by file type first (.pdf, .jpg, .exe, etc.)
2. FILE NAME - Consider naming patterns, keywords, and implied purpose
3. DATE - Use creation/modification dates as secondary grouping factor

FOLDER NAMING BEST PRACTICES:
- Use specific, descriptive names that indicate purpose or function
- Prefer action-oriented names over generic file type categories
- Consider the user's likely workflow and how they'll search for files
- Group by primary use case, then by file type if needed
- Avoid overly technical jargon unless the files are clearly technical
- Use clear, intuitive names that don't require explanation

ORGANIZATION STRATEGIES:
- Analyze file names and extensions to infer purpose and context
- Look for patterns in naming conventions (dates, projects, functions)
- Group files that would logically be used together
- Consider frequency of access - commonly used files in accessible folders
- Balance specificity with practicality (avoid too many micro-categories)
- Respect existing naming patterns that suggest user intent

Files to organize:
$JsonData

Respond with ONLY valid JSON (no explanations):
[{"folderName": "Descriptive Name", "items": [{"name": "exact-filename.ext"}]}]
"@

    $requestBody = @{
        model = "gpt-4o-mini"
        messages = @(
            @{
                role = "system"
                content = "You are TidyAI, an expert file organization system. Create logical, user-friendly folder structures that enhance productivity. Always preserve exact filenames and avoid duplicate assignments. Focus on practical workflow over rigid categorization."
            },
            @{
                role = "user" 
                content = $prompt
            }
        )
        max_tokens = 4000
        temperature = 0.3
    } | ConvertTo-Json -Depth 10

    $headers = @{
        "Authorization" = "Bearer $OPENAI_API_KEY"
        "Content-Type" = "application/json"
    }

    # Validate request size before sending
    $requestSize = [System.Text.Encoding]::UTF8.GetByteCount($requestBody)
    Write-ColorText "Request size: $requestSize bytes" $Colors.Info
    
    if ($requestSize -gt 100000) {  # 100KB limit
        Write-ColorText "WARNING: Large request size may cause truncation" $Colors.Warning
        Write-ColorText "Consider reducing the number of files or simplifying the request" $Colors.Info
    }
    
    try {
        Show-ProgressBar "Waiting for ChatGPT response" 50
        $response = Invoke-RestMethod -Uri $OPENAI_API_URL -Method Post -Body $requestBody -Headers $headers
        Show-ProgressBar "Processing ChatGPT response" 100
        Write-Host ""
        Write-ColorText "Received response from ChatGPT!" $Colors.Success
        Write-Host ""
        
        $content = $response.choices[0].message.content
        
        # Validate response completeness before returning
        if ([string]::IsNullOrWhiteSpace($content)) {
            throw "Empty response received from ChatGPT"
        }
        
        # Check if response was cut off due to token limits
        if ($response.choices[0].finish_reason -eq "length") {
            Write-ColorText "ERROR: Response was truncated due to token limit!" $Colors.Error
            Write-ColorText "The response was cut off. Please try with fewer files or contact support." $Colors.Warning
            throw "Response truncated due to token limit. Cannot process incomplete data."
        }
        
        Write-ColorText "Response validation: Complete ($($content.Length) characters)" $Colors.Success
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
        
        # Show request size for debugging
        $requestSize = [System.Text.Encoding]::UTF8.GetByteCount($requestBody)
        Write-ColorText "Request size: $requestSize bytes" $Colors.Info
        
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

function Show-OrganizationTree {
    param([string]$JsonResponse)
    
    Write-ColorText "Processing ChatGPT response..." $Colors.Info
    Write-Host ""
    
    try {
        # Step 1: Clean and extract JSON from the response
        $cleanedJson = Extract-JsonFromResponse -Response $JsonResponse
        
        # Step 2: Parse JSON using built-in .NET classes
        $suggestedStructure = Parse-JsonResponse -JsonString $cleanedJson
        
        # Step 3: Validate and clean the organization structure
        $cleanedStructure = Remove-DuplicateFileAssignments -Structure $suggestedStructure
        
        # Step 4: Display the organization tree
        Display-OrganizationTree -Structure $cleanedStructure
        
        # Step 5: Ask for user confirmation and apply changes if approved
        Confirm-AndApplyOrganization -Structure $cleanedStructure
        
    }
    catch {
        Write-ColorText "Error processing ChatGPT response: $($_.Exception.Message)" $Colors.Error
        Write-Host ""
        Write-ColorText "Debug Information:" $Colors.Warning
        Write-ColorText "Response length: $($JsonResponse.Length) characters" $Colors.Info
        
        if ($JsonResponse.Length -gt 100) {
            Write-ColorText "Response preview (first 200 chars): '$($JsonResponse.Substring(0, [Math]::Min(200, $JsonResponse.Length)))...'" $Colors.Info
            Write-ColorText "Response ending (last 100 chars): '...$($JsonResponse.Substring([Math]::Max(0, $JsonResponse.Length - 100)))'" $Colors.Info
        } else {
            Write-ColorText "Full response: '$JsonResponse'" $Colors.Info
        }
        
        Write-Host ""
        Write-ColorText "Common causes:" $Colors.Warning
        Write-ColorText "1. Response was truncated due to token limits" $Colors.Warning
        Write-ColorText "2. Invalid JSON format from ChatGPT" $Colors.Warning
        Write-ColorText "3. Network connectivity issues" $Colors.Warning
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
    
    return $cleanedStructure.ToArray()
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
        max_tokens = 1000
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
    if ($cleaned -match '(\[[\s\S]*?\])') {
        Write-ColorText "Found JSON array in response" $Colors.Success
        return $matches[1].Trim()
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
    
    if ($openBrackets -ne $closeBrackets -or $openBraces -ne $closeBraces) {
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

# Helper function to parse JSON using built-in .NET classes only
function Parse-JsonResponse {
    param([string]$JsonString)
    
    # Strict validation: Reject any truncated responses immediately
    $isTruncated = Test-JsonTruncation -JsonString $JsonString
    if ($isTruncated) {
        Write-ColorText "ERROR: Detected truncated JSON response!" $Colors.Error
        Write-ColorText "TidyAI requires complete responses. Please try again." $Colors.Warning
        throw "Response was truncated. Cannot process incomplete data."
    }
    
    # Additional validation: Check for minimum expected structure
    if (-not ($JsonString.Contains('folderName') -and $JsonString.Contains('items'))) {
        Write-ColorText "ERROR: Response missing required structure (folderName/items)" $Colors.Error
        throw "Invalid response format. Expected folder structure not found."
    }
    
    # Method 1: Try PowerShell's built-in ConvertFrom-Json (available in PS 3.0+)
    try {
        Write-ColorText "Attempting PowerShell ConvertFrom-Json..." $Colors.Info
        $parsed = $JsonString | ConvertFrom-Json -ErrorAction Stop
        
        # Validate structure
        if ($parsed -is [System.Array] -and $parsed.Count -gt 0) {
            Write-ColorText "Successfully parsed JSON array with $($parsed.Count) folders" $Colors.Success
            return $parsed
        } elseif ($parsed -and $parsed.PSObject.Properties.Name -contains 'folderName') {
            # Single object, wrap in array
            Write-ColorText "Parsed single folder object, wrapping in array" $Colors.Success
            return @($parsed)
        } else {
            throw "Invalid structure: expected array of folder objects"
        }
    }
    catch {
        Write-ColorText "PowerShell parser failed: $($_.Exception.Message)" $Colors.Warning
    }
    
    # Method 2: Try with increased depth (PS 6.0+ feature, fallback gracefully)
    try {
        Write-ColorText "Attempting ConvertFrom-Json with depth parameter..." $Colors.Info
        $parsed = $JsonString | ConvertFrom-Json -Depth 50 -ErrorAction Stop
        
        if ($parsed -is [System.Array] -and $parsed.Count -gt 0) {
            Write-ColorText "Successfully parsed with depth parameter" $Colors.Success
            return $parsed
        }
    }
    catch {
        Write-ColorText "Depth parameter not supported or failed: $($_.Exception.Message)" $Colors.Warning
    }
    
    # Method 3: Enhanced manual JSON parsing using .NET Regex (last resort)
    try {
        Write-ColorText "Attempting enhanced manual JSON parsing..." $Colors.Info
        $folders = Parse-JsonManually -JsonString $JsonString
        
        if ($folders -and $folders.Count -gt 0) {
            Write-ColorText "Successfully parsed manually with $($folders.Count) folders" $Colors.Success
            return $folders
        }
    }
    catch {
        Write-ColorText "Manual parsing failed: $($_.Exception.Message)" $Colors.Warning
    }
    
    throw "All JSON parsing methods failed. The response may be malformed or truncated."
}

# Enhanced manual JSON parsing for edge cases (using only built-in .NET classes)
function Parse-JsonManually {
    param([string]$JsonString)
    
    $folders = @()
    
    try {
        # More flexible pattern that handles nested structures and whitespace better
        $folderPattern = '\{[^{}]*?"folderName"\s*:\s*"([^"]+)"[^{}]*?"items"\s*:\s*\[([^\]]*?)\]'
        $matches = [regex]::Matches($JsonString, $folderPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Singleline)
        
        Write-ColorText "Found $($matches.Count) folder matches in manual parsing" $Colors.Info
        
        foreach ($match in $matches) {
            $folderName = $match.Groups[1].Value.Trim()
            $itemsString = $match.Groups[2].Value.Trim()
            
            Write-ColorText "Processing folder: $folderName" $Colors.Info
            
            # Parse items within this folder with more flexible pattern
            $items = @()
            # Handle both {"name": "filename"} and simplified {"name":"filename"} formats
            $itemPattern = '\{\s*"name"\s*:\s*"([^"]+)"[^}]*\}'
            $itemMatches = [regex]::Matches($itemsString, $itemPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            
            Write-ColorText "Found $($itemMatches.Count) items in folder $folderName" $Colors.Info
            
            foreach ($itemMatch in $itemMatches) {
                $fileName = $itemMatch.Groups[1].Value.Trim()
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
            
            # Only add folders that have items
            if ($items.Count -gt 0) {
                $folders = $folders + [PSCustomObject]@{
                    folderName = $folderName
                    items = $items
                }
            }
        }
        
        # If no complete folders found, log the issue but don't try partial extraction
        # We want all-or-none, not partial data
        if ($folders.Count -eq 0) {
            Write-ColorText "No complete folders found in manual parsing" $Colors.Error
            throw "Manual parsing failed to extract complete folder structure"
        }
    }
    catch {
        Write-ColorText "Error in manual JSON parsing: $($_.Exception.Message)" $Colors.Error
        throw
    }
    
    return $folders
}

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
    
    # Step 2: Build JSON structure
    Write-ColorText "Building folder structure..." $Colors.Info
    $jsonData = Build-FolderJson -Items $items -FolderPath $TargetFolder
    
    # Step 3: Send to ChatGPT
    $response = Send-ToOpenAI -JsonData $jsonData
    
    if ($null -eq $response) {
        Write-ColorText "Failed to get response from ChatGPT. Please check your API key and internet connection." $Colors.Error
        Read-Host "Press Enter to exit"
        return
    }
    
    # Step 4: Display the organization tree
    Show-OrganizationTree -JsonResponse $response
    
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
