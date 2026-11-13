@echo off
setlocal EnableDelayedExpansion
title Node.js LTS Installer

:: Skip if Node.js is already installed (pass /force to reinstall)
where node >nul 2>&1
if %errorlevel%==0 (
  for /f "delims=" %%v in ('node -v') do echo Node.js %%v ja esta instalado.
  if /i not "%~1"=="/force" exit /b 0
)

:: Installation requires administrator rights
net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Esse script deve ser executado como administrador.
  echo Clique com o botão direito e selecione "Executar como administrador".
  pause
  exit /b 1
)

:: Method 1: winget
where winget >nul 2>&1
if %errorlevel%==0 (
  echo Installing Node.js LTS with winget...
  winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements
  if !errorlevel!==0 goto :done
  echo winget failed, trying direct download...
)

:: Method 2: download the latest LTS MSI from nodejs.org
set "MSI=%TEMP%\node-lts-x64.msi"
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$idx = Invoke-RestMethod 'https://nodejs.org/dist/index.json';" ^
  "$lts = $idx | Where-Object { $_.lts } | Select-Object -First 1;" ^
  "$url = 'https://nodejs.org/dist/' + $lts.version + '/node-' + $lts.version + '-x64.msi';" ^
  "Write-Host ('Downloading ' + $url);" ^
  "Invoke-WebRequest $url -OutFile '%MSI%'"

if not exist "%MSI%" (
  echo Download falhou.
  pause
  exit /b 1
)

msiexec /i "%MSI%" /qn /norestart
if %errorlevel% neq 0 (
  echo MSI installation failed.
  pause
  exit /b 1
)
del "%MSI%" >nul 2>&1

:done
echo.
echo Node.js foi instalado com sucesso.
echo Execute o arquivo ABRIR de acordo com o seu sistema operacional
pause
endlocal
