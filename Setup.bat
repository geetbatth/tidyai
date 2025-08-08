@echo off
:: ============================================================================
:: TidyAI Auto-Admin Installer
:: Automatically runs Install-TidyAI.ps1 as Administrator
:: ============================================================================

title TidyAI Installer

:: Check if already running as admin
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running as Administrator - proceeding with installation...
    goto :RunInstaller
)

:: If not admin, restart as admin
echo.
echo     ############ #### ########   ####  ####     ##########    ####
echo     ############ #### ########   ####  ####     ##########    ####
echo         ####     #### ####  #### ####  ####     ####  ####    ####
echo         ####     #### ####  #### ####  ####     ####  ####    ####
echo         ####     #### ####  ####  ########      ##########    ####
echo         ####     #### ####  ####   ######       ##########    ####
echo         ####     #### ####  ####    ####        ####  ####    ####
echo         ####     #### ########      ####        ####  ####    ####
echo         ####     #### ########      ####        ####  #### ## ####
echo.
echo Requesting Administrator privileges...
echo.
echo This will open a new window with Administrator privileges.
echo Please click "Yes" when prompted by Windows UAC.
echo.
pause

:: Restart this batch file as Administrator
powershell -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
exit /b

:RunInstaller

:: Change to the directory where this batch file is located
cd /d "%~dp0"

:: Check if Install-TidyAI.ps1 exists
if not exist "Install-TidyAI.ps1" (
    echo ERROR: Install-TidyAI.ps1 not found in current directory!
    echo Please ensure both files are in the same folder.
    echo.
    pause
    exit /b 1
)

:: Run the PowerShell installer
echo Running TidyAI installer...
echo.
powershell -ExecutionPolicy Bypass -File "Install-TidyAI.ps1"

:: Check if installation was successful
if %errorLevel% == 0 (
    echo.
    echo ============================================
    echo    TidyAI Installation Complete!
    echo ============================================
    echo.
    echo You can now right-click any folder and select
    echo "Tidy Up with TidyAI" to organize your files.
    echo.
    echo Your OpenAI API key has been configured and
    echo TidyAI is ready to use!
    echo.
) else (
    echo.
    echo ============================================
    echo    Installation encountered an error
    echo ============================================
    echo.
    echo Please check the error messages above.
    echo.
)

echo Press any key to exit...
pause >nul
