# ==============================================================================
# TIDYAI - CONFIGURATION & CONSTANTS
# ==============================================================================

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
