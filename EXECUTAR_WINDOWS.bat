@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul
title Node.js LTS Installer

cd /d "%~dp0"

if /i not "%~1"=="/force" (
  where node >nul 2>&1
  if !errorlevel!==0 (
    for /f "delims=" %%v in ('node -v') do echo Node.js %%v ja esta instalado.
    goto :deps
  )
)

net session >nul 2>&1
if %errorlevel% neq 0 (
  echo Esse script deve ser executado como administrador.
  echo Clique com o botão direito e selecione "Executar como administrador".
  pause
  exit /b 1
)

where winget >nul 2>&1
if %errorlevel%==0 (
  echo Installing Node.js LTS with winget...
  winget install --id OpenJS.NodeJS.LTS -e --accept-package-agreements --accept-source-agreements
  if !errorlevel!==0 goto :refresh
  echo winget failed, trying direct download...
)

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
  del "%MSI%" >nul 2>&1
  pause
  exit /b 1
)
del "%MSI%" >nul 2>&1

:refresh

set "PATH=%ProgramFiles%\nodejs;%APPDATA%\npm;%PATH%"

:deps
where npm >nul 2>&1
if %errorlevel% neq 0 (
  echo npm nao encontrado. Feche esta janela e execute o script novamente.
  pause
  exit /b 1
)

if not exist "package.json" (
  echo package.json nao encontrado em "%~dp0".
  pause
  exit /b 1
)

echo.
echo Instalando dependencias...
call npm install --omit=dev
if %errorlevel% neq 0 (
  echo Falha ao instalar as dependencias.
  pause
  exit /b 1
)

:done
echo.
echo.
echo Node.js e as dependencias foram instaladas com sucesso.
echo Iniciando: node app.js
if not exist "app.js" (
  echo app.js nao encontrado em "%~dp0".
  pause
  exit /b 1
)
echo.
node app.js
pause
endlocal