@echo off
setlocal enabledelayedexpansion

:: check argument
if "%~1"=="" (
    echo Usage: %~nx0 folder_path
    exit /b
)

set "target=%~1"
set total=0

for /r "%target%" %%f in (*.hx) do (
    for /f %%c in ('find /c /v "" ^< "%%f"') do (
        set /a total+=%%c
    )
)

echo Total lines in %target%: %total%