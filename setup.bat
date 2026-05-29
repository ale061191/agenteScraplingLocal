@echo off
chcp 65001 >nul
title Lead Finder - Instalacion
echo ============================================
echo   Lead Finder Venezuela - Instalacion
echo ============================================
echo.
echo PASO 1: Verificando Python...
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo   Python no encontrado. Descargando...
    curl -L -o "%TEMP%\python-installer.exe" https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe
    echo   Instalando Python (esto toma 1-2 min)...
    "%TEMP%\python-installer.exe" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
)
echo   OK
echo.
echo PASO 2: Verificando Node.js...
where node >nul 2>nul
if %errorlevel% neq 0 (
    echo   Node.js no encontrado. Descargando...
    curl -L -o "%TEMP%\node-installer.msi" https://nodejs.org/dist/v20.18.0/node-v20.18.0-x64.msi
    echo   Instalando Node.js (esto toma 1-2 min)...
    msiexec /i "%TEMP%\node-installer.msi" /quiet
)
echo   OK
echo.
echo PASO 3: Instalando librerias Python...
pip install scrapling flask supabase -q
echo   OK
echo.
echo PASO 4: Preparando el Dashboard...
if not exist "dashboard\node_modules\next" (
    echo   Instalando dependencias del dashboard (esto toma 1-2 min)...
    pushd dashboard
    call npm install --loglevel=error
    popd
)
echo   OK
echo.
echo PASO 5: Creando carpeta de datos...
if not exist "leads_data" mkdir leads_data
echo   OK
echo.
echo ============================================
echo   INSTALACION COMPLETADA!
echo ============================================
echo.
echo   Ahora abre "INICIAR.bat" para empezar
echo.
pause
