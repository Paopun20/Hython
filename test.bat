@REM This batch file compiles the Haxe code and runs the resulting executable.
@echo off

echo Compiling...
haxe test.hxml
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo Running...
.\bin\test\cpp\TestMain.exe