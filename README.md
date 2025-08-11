```
    ############ #### ########   ####  ####     ##########    ####
    ############ #### ########   ####  ####     ##########    ####
        ####     #### ####  #### ####  ####     ####  ####    ####
        ####     #### ####  #### ####  ####     ####  ####    ####
        ####     #### ####  ####  ########      ##########    ####
        ####     #### ####  ####   ######       ##########    ####
        ####     #### ####  ####    ####        ####  ####    ####
        ####     #### ########      ####        ####  ####    ####
        ####     #### ########      ####        ####  #### ## ####
```

<div align="center">
<img src="https://raw.githubusercontent.com/geetbatth/tidyai/main/media/screenshot.jpg" alt="TidyAI Screenshot" width="600">
</div>

## There is a version in Bash for Unix-based systems. Check it out [here](/README_SHELL.md).

# AI-powered file organization for Windows

## Features
- 🤖 **AI-Powered** - Uses ChatGPT to intelligently organize files
- 📁 **Right-Click Integration** - Works directly from Windows Explorer  
- 🛡️ **Safe** - Never renames/deletes files, only moves them into folders
- 🔄 **Undo System** - Easily revert organization with one click
- 📦 **Batch Processing** - Handles large folders by processing files in batches
- 💰 **Cost-Effective** - Uses GPT-4 Mini model, very cheap to run
- ⚡ **Pure PowerShell** - No external dependencies, runs on any Windows machine

## 🎬 TidyAI in Action

<div align="center">
<img src="https://raw.githubusercontent.com/geetbatth/tidyai/main/media/demo.gif" alt="TidyAI Demo" width="600">
</div>



## Install
1. Right-click `setup.bat` → "Run as administrator"
2. Get OpenAI API key from [platform.openai.com](https://platform.openai.com/api-keys)
3. Set key during installation or `setx TidyAIOpenAIAPIKey "your-key-here"`

## Use
Right-click any folder → "🧹 Tidy Up with TidyAI"

## 🔄 Undo System
TidyAI includes a powerful undo system that makes organization completely safe and reversible:

### **How It Works**
- **Automatic Backup**: Before organizing, TidyAI saves your current folder structure to a hidden `.tidyai` file
- **Undo**: After organizing, TidyAI offers to undo if you dont like the result
- **Smart Detection**: When you run TidyAI on a previously organized folder, it detects the backup and offers to undo


## Uninstall
`appwiz.cpl` → Remove "TidyAI" or run `Uninstall-TidyAI.ps1`

## Contribute
Pull requests welcome!

---
**Created by Geet**
