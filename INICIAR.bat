@echo off
chcp 65001 >nul
title Lead Finder Venezuela
setlocal enabledelayedexpansion

set "ROOT=%~dp0"
cd /d "%ROOT%"

echo ============================================
echo      LEAD FINDER VENEZUELA
echo      Nova Tech AI
echo ============================================
echo.

:: ---- DETECTAR PYTHON ----
set "PYTHON_EXE=python"
python --version >nul 2>&1
if errorlevel 1 (
    if exist "%LOCALAPPDATA%\Python\bin\python.exe" (
        set "PYTHON_EXE=%LOCALAPPDATA%\Python\bin\python.exe"
    ) else if exist "%USERPROFILE%\AppData\Local\Programs\Python\Launcher\py.exe" (
        set "PYTHON_EXE=%USERPROFILE%\AppData\Local\Programs\Python\Launcher\py.exe"
    ) else if exist "C:\Python313\python.exe" (
        set "PYTHON_EXE=C:\Python313\python.exe"
    ) else if exist "C:\Python312\python.exe" (
        set "PYTHON_EXE=C:\Python312\python.exe"
    ) else if exist "C:\Python311\python.exe" (
        set "PYTHON_EXE=C:\Python311\python.exe"
    ) else (
        echo [ERROR] Python no encontrado.
        echo        Instalalo desde https://python.org marcando "Add Python to PATH"
        pause
        exit /b 1
    )
)
"%PYTHON_EXE%" --version 2>&1 | find "Python" >nul
if errorlevel 1 (
    echo [ERROR] El ejecutable "%PYTHON_EXE%" no funciona
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('"%PYTHON_EXE%" --version 2^>^&1') do echo [OK] %%v

:: ---- VERIFICAR NODE ----
node --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Node.js no encontrado. Instalalo desde https://nodejs.org
    pause
    exit /b 1
)
for /f %%v in ('node --version') do echo [OK] Node.js %%v

:: ---- INSTALAR DEPENDENCIAS DEL DASHBOARD ----
if not exist "dashboard\node_modules" (
    echo [~] Instalando dependencias del dashboard...
    cd /d "%ROOT%dashboard"
    call npm install
    if errorlevel 1 (
        echo [ERROR] Fallo npm install
        pause
        exit /b 1
    )
    cd /d "%ROOT%"
    echo [OK] Dependencias instaladas
)

:: ---- GENERAR LEADS.JSON SI HAY SQLITE ----
if not exist "leads_data\leads.json" (
    if exist "leads_data\leads.db" (
        echo [~] Exportando leads a JSON...
        "%PYTHON_EXE%" main.py export
    )
)

if exist "leads_data\leads.json" (
    echo [OK] leads.json encontrado
) else (
    echo [!] Sin datos aun. Usa la opcion 1 del menu para buscar leads.
)

:: ---- CONFIGURAR SMTP (si no existe) ----
if not exist "leads_data\smtp_config.json" (
    echo [~] Configurando SMTP con Gmail...
    node -e "require('fs').writeFileSync('leads_data/smtp_config.json',JSON.stringify({host:'smtp.gmail.com',port:587,user:'voltajevzla@gmail.com',password:'omei fwjx yeis cqgx',use_tls:true,from_name:'Voltaje Plus C.A.',configured:true},null,2))"
    if %errorlevel% equ 0 (
        echo [OK] SMTP configurado con voltajevzla@gmail.com
    )
)

echo.

:: ---- LIMPIAR CACHE Y MATAR SERVIDOR ANTERIOR ----
if exist "dashboard\.next" (
    rmdir /s /q "dashboard\.next" >nul 2>nul
    echo [~] Cache de compilacion eliminada
)
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :3000 ^| findstr LISTENING') do (
    taskkill /f /pid %%a >nul 2>nul
)

:: ---- INICIAR DASHBOARD EN SEGUNDO PLANO ----
echo [~] Iniciando dashboard...
start "Dashboard" cmd /c "cd /d "%ROOT%dashboard" && npm run dev"

:: ---- ESPERAR A QUE EL SERVIDOR RESPONDA ----
echo [~] Esperando al servidor (hasta 60s)...
set WAITED=0
:WAIT_LOOP
timeout /t 2 /nobreak >nul
set /a WAITED+=2
powershell -command "try{$r=Invoke-WebRequest -Uri 'http://localhost:3000/dashboard' -UseBasicParsing -TimeoutSec 2; exit $r.StatusCode}catch{exit 0}" 2>nul
if !errorlevel! equ 200 goto OPEN_BROWSER
if !WAITED! lss 60 goto WAIT_LOOP

echo [ADVERTENCIA] El servidor no respondio en 60 segundos.
echo Revisa la ventana 'Dashboard' para ver errores.
pause
goto MENU

:OPEN_BROWSER
echo [OK] Dashboard listo!
start http://localhost:3000/dashboard

:MENU
cls
echo ============================================
echo      LEAD FINDER VENEZUELA
echo ============================================
echo.
echo  Dashboard: http://localhost:3000/dashboard
echo.
echo  1 - Buscar nuevos leads (scraper)
echo  2 - Subir datos a la nube (Supabase sync)
echo  3 - Ver estadisticas
echo  0 - Cerrar todo
echo.
set /p opcion="Elige: "

if "%opcion%"=="1" goto BUSCAR
if "%opcion%"=="2" goto SYNC
if "%opcion%"=="3" goto STATS
if "%opcion%"=="0" goto SALIR
goto MENU

:BUSCAR
cls
echo ============ BUSCAR LEADS ============
echo.
echo Categoria:
echo  1 - Restaurantes    11 - Bares
echo  2 - Hoteles         12 - Cafeterias
echo  3 - Centros Comerc. 13 - Centros Dep.
echo  4 - Gimnasios       14 - Cines
echo  5 - Hospitales      15 - Universidades
echo  6 - Clinicas        16 - Supermercados
echo  7 - Discotecas      17 - Teatros
echo  8 - Clubes Noct.    18 - Convenciones
echo  9 - Parques         19 - Plazas
echo 10 - Aeropuertos     20 - Farmacias
echo  21 - TODAS
echo.
set /p cat="Numero: "
if "%cat%"=="21" set CAT=--todas
if "%cat%"=="1" set CAT=restaurantes
if "%cat%"=="2" set CAT=hoteles
if "%cat%"=="3" set CAT=centros comerciales
if "%cat%"=="4" set CAT=gimnasios
if "%cat%"=="5" set CAT=hospitales
if "%cat%"=="6" set CAT=clinicas
if "%cat%"=="7" set CAT=discotecas
if "%cat%"=="8" set CAT=clubes nocturnos
if "%cat%"=="9" set CAT=parques
if "%cat%"=="10" set CAT=aeropuertos
if "%cat%"=="11" set CAT=bares
if "%cat%"=="12" set CAT=cafeterias
if "%cat%"=="13" set CAT=centros deportivos
if "%cat%"=="14" set CAT=cines
if "%cat%"=="15" set CAT=universidades
if "%cat%"=="16" set CAT=supermercados
if "%cat%"=="17" set CAT=teatros
if "%cat%"=="18" set CAT=centros de convenciones
if "%cat%"=="19" set CAT=plazas
if "%cat%"=="20" set CAT=farmacias

echo.
echo Modo: 1 - Rapido  2 - Profundo (telefonos/web)
set /p modo="Opcion: "
if "%modo%"=="2" (set EXTRA=--deep) else (set EXTRA=)
echo.
echo Buscando... (no cierres esta ventana)
if "%CAT%"=="--todas" (
    "%PYTHON_EXE%" main.py run %EXTRA%
) else (
    "%PYTHON_EXE%" main.py run "%CAT%" %EXTRA%
)
echo.
echo Busqueda terminada.
echo.
set /p sync="Subir a la nube ahora? (S/N): "
if /i "%sync%"=="S" (
    "%PYTHON_EXE%" main.py supabase-sync
    echo Listo! Refresca el navegador.
)
pause
goto MENU

:SYNC
cls
echo Sincronizando con la nube...
"%PYTHON_EXE%" main.py supabase-sync
pause
goto MENU

:STATS
cls
"%PYTHON_EXE%" main.py stats
pause
goto MENU

:SALIR
cls
echo Cerrando el sistema...
taskkill /f /im node.exe >nul 2>nul
echo Adios!
timeout /t 2 >nul
exit
