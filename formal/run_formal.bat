@echo off
:: 1. Clean the path to prevent library contamination from MSYS2 or Python 3.14 folders
set "PATH=C:\Windows\system32;C:\Windows"

:: Change the active directory to the folder containing the .sby file
cd /d "%~dp1"

:: 2. Initialize the official internal variables via the suite's environment profile
call "C:\oss-cad-suite\environment.bat"

:: 3. Launch SymbiYosys natively in force mode against the right-clicked target file
sby -f "%~1"
