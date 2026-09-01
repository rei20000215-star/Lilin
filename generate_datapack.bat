@echo off
setlocal
title Village Distance Datapack Generator

echo Minecraft 1.20.1 Village Distance Datapack Generator
echo.
set /p SE_MULTIPLIER=Enter Structure Essentials spacingSeparationModifier: 

if "%SE_MULTIPLIER%"=="" (
  echo No multiplier entered.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0generate_datapack.ps1" -StructureEssentialsMultiplier "%SE_MULTIPLIER%" -VillageTargetMultiplier 3.0 -OutputDirectory "%~dp0dist"

if errorlevel 1 (
  echo.
  echo Generation failed. Check the message above.
) else (
  echo.
  echo Finished. Open the dist folder for the datapack ZIP.
)

pause
endlocal
