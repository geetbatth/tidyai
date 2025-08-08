# ==============================================================================
# TIDYAI - AI RESPONSE PROCESSING & VALIDATION
# ==============================================================================

function ConvertFrom-AIResponse {
    param([string]$JsonResponse, [array]$OriginalItems = @())
    
    try {
        # Step 1: Clean and extract JSON from the response
        $cleanedJson = Get-JsonFromResponse -Response $JsonResponse
        
        # Step 2: Parse JSON using built-in .NET classes
        $suggestedStructure = ConvertFrom-JsonResponse -JsonString $cleanedJson
        
        # Step 3: Filter out sample files that shouldn't be organized
        if ($OriginalItems.Count -gt 0) {
            $suggestedStructure = Remove-SampleFilesFromResponse -Structure $suggestedStructure -OriginalItems $OriginalItems
        }
        
        return $suggestedStructure
    }
    catch {
        Write-ColorText "Error processing AI response: $($_.Exception.Message)" $Colors.Error
        return $null
    }
}

function Remove-SampleFilesFromResponse {
    param([array]$Structure, [array]$OriginalItems)
    
    # Get list of actual items that exist in the target directory
    $actualItemNames = @()
    foreach ($item in $OriginalItems) {
        $actualItemNames += $item.name
    }
    
    # Filter the AI response to only include items that actually exist
    $filteredStructure = @()
    foreach ($folder in $Structure) {
        $filteredItems = @()
        foreach ($item in $folder.items) {
            if ($actualItemNames -contains $item.name) {
                $filteredItems += $item
            } else {
                Write-ColorText "Filtered out non-existent item: $($item.name)" $Colors.Warning
            }
        }
        
        # Only include folders that have valid items
        if ($filteredItems.Count -gt 0) {
            $folder.items = $filteredItems
            $filteredStructure += $folder
        }
    }
    
    return $filteredStructure
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
    
    # Check for incomplete JSON structures
    $openBraces = ($trimmed.ToCharArray() | Where-Object { $_ -eq '{' }).Count
    $closeBraces = ($trimmed.ToCharArray() | Where-Object { $_ -eq '}' }).Count
    $openBrackets = ($trimmed.ToCharArray() | Where-Object { $_ -eq '[' }).Count
    $closeBrackets = ($trimmed.ToCharArray() | Where-Object { $_ -eq ']' }).Count
    
    if ($openBraces -ne $closeBraces -or $openBrackets -ne $closeBrackets) {
        return $true
    }
    
    return $false
}
