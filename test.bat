@REM This batch file compiles the Haxe code and runs the resulting executable.
@echo off

echo Compiling...
@REM
set args=%*

haxe test.hxml %args%
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo Running...

.\bin\test\cpp\TestMain.exe

echo Exit Error Code %ERRORLEVEL%
exit /b %ERRORLEVEL%