:: Copyright 2026 circuitli (https://github.com)
::
:: Licensed under the CERN Open Hardware Licence Version 2 - Weakly Reciprocal  (the "License");
:: you may not use this file except in compliance with the License.
:: You may obtain a copy of the License at
::
::     https://cern-ohl.web.cern.ch/
::
:: Unless required by applicable law or agreed to in writing, software
:: distributed under the License is distributed on an "AS IS" BASIS,
:: WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
:: See the License for the specific language governing permissions and
:: limitations under the License.

@echo off
:: 1. Clean the path to prevent library contamination from MSYS2 or Python 3.14 folders
set "PATH=C:\Windows\system32;C:\Windows"

:: Change the active directory to the folder containing the .sby file
cd /d "%~dp1"

:: 2. Initialize the official internal variables via the suite's environment profile
call "C:\oss-cad-suite\environment.bat"

:: 3. Launch SymbiYosys natively in force mode against the right-clicked target file
sby -f "%~1"
