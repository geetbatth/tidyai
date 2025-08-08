# ==============================================================================
# TIDYAI - OPENAI API COMMUNICATION
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

🚨 CRITICAL: SAMPLE FILES ARE CONTEXT ONLY! 🚨
- When you see "sampleFiles" in folder data, these are files INSIDE the folder for context
- DO NOT organize sample files as separate items - they are already inside their parent folder
- Only organize the folder itself, not the files listed in "sampleFiles"
- Sample files help you understand folder content but should NEVER appear in your response
- FORBIDDEN: Never include any filename from "sampleFiles" arrays in your organization response
- ONLY organize items with "type": "file" or "type": "folder" at the root level

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
            Write-ColorText "Could not retrieve detailed error information" $Colors.Warning
        }
        
        return $null
    }
}
