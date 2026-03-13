: << 'CMDBLOCK'
@echo off
REM Windows batch portion
setlocal enabledelayedexpansion
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME=%~1"
where bash >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    bash "%SCRIPT_DIR%%SCRIPT_NAME%" %2 %3 %4 %5
    exit /b %ERRORLEVEL%
)
echo {"hookSpecificOutput":{"hookEventName":"Error","additionalContext":"bash not found"}}
exit /b 1
CMDBLOCK

# Unix: Shell portion
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
shift
exec bash "${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
