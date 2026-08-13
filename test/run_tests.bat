@echo off
SETLOCAL

:: 5. SANITIZE PATH: Convert Windows backslashes (\) to Unix forward slashes (/)
set "RAW_MAKEFILE=%~1"
set "SAFE_MAKEFILE=%RAW_MAKEFILE:\=/%"

echo [*] Sanitized Makefile path for MinGW: %SAFE_MAKEFILE%

:: 1. Define your core MSYS2 layout paths 
set "MSYS_ROOT=C:\msys64"
set "UCRT_BIN=%MSYS_ROOT%\ucrt64\bin"
set "USR_BIN=%MSYS_ROOT%\usr\bin"

:: 2. Check if the UCRT binary folder exists on your drive
if not exist "%USR_BIN%\make.exe" (
    echo [!] Error: MSYS2 UCRT64 toolchain was not found at %UCRT_BIN%
    echo Please make sure MSYS2 is installed in C:\msys64
    pause
    exit /b 1
)

:: 3. Route the execution paths strictly inside the UCRT64 ecosystem
set "PATH=%UCRT_BIN%;%MSYS_ROOT%\usr\bin;%PATH%"

:: 4. Explicitly map the unique MinGW/UCRT Python shared library file name
:: In UCRT64, this file uses the libpython prefix instead of the raw Windows name.
set "LIBPYTHON_LOC=%UCRT_BIN%\libpython3.12.dll"

:: Fallback check if your UCRT64 environment upgraded its internal Python minor version
if not exist "%LIBPYTHON_LOC%" (
    for %%F in ("%UCRT_BIN%\libpython3.*.dll") do set "LIBPYTHON_LOC=%%F"
)

echo [*] Grounding execution inside MSYS2 UCRT64...
echo [*] Toolchain Path: %UCRT_BIN%
echo [*] Linked DLL:    %LIBPYTHON_LOC%

:: 5. Execute make forcing the UCRT64 bash subshell to avoid Access Denied blocks
:: Execute make using the safe, slash-corrected string variable
"%USR_BIN%\make.exe" -f "%SAFE_MAKEFILE%" SIM=icarus SHELL=bash.exe LIBPYTHON_LOC="%LIBPYTHON_LOC%"

if %errorlevel% neq 0 (
    echo [!] Simulation execution stalled within the compiler loop.
    pause
    exit /b %errorlevel%
)

echo [+] Simulation verification completed successfully!
pause
ENDLOCAL
