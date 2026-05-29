@echo off
chcp 65001 >nul
title Lead Finder Venezuela

:: Configuracion de Supabase (nube)
set SUPABASE_URL=https://vdknyyempgailnbnxeqz.supabase.co
set SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZka255eWVtcGdhaWxuYm54ZXF6Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczMDg2NDY5NSwiZXhwIjoyMDQ2NDQwNjk1fQ.P_kLfQ1eK5q9NDqNEz1dNsHNv2K5KB3RkBiIjZnZ_Tc

:MENU
cls
echo ============================================
echo      LEAD FINDER VENEZUELA
echo      Buscador de clientes para Power Banks
echo ============================================
echo.
echo  1 - Buscar en TODO Venezuela
echo  2 - Buscar por estado y categoria
echo  3 - Sincronizar con Supabase (subir a la nube)
echo  4 - Ver estadisticas
echo  5 - Exportar a CSV/JSON
echo  0 - Salir
echo.
set /p opcion="Elige una opcion (0-5): "

if "%opcion%"=="1" goto TODOVENEZUELA
if "%opcion%"=="2" goto PORESTADO
if "%opcion%"=="3" goto SYNC
if "%opcion%"=="4" goto STATS
if "%opcion%"=="5" goto EXPORT
if "%opcion%"=="0" goto SALIR
goto MENU

:TODOVENEZUELA
cls
echo ============ BUSCAR EN TODO VENEZUELA ============
echo.
echo Categorias:
echo.
echo  1  - Restaurantes        11 - Bares
echo  2  - Hoteles             12 - Cafeterias
echo  3  - Centros Comerciales 13 - Centros Deportivos
echo  4  - Gimnasios           14 - Cines
echo  5  - Hospitales          15 - Universidades
echo  6  - Clinicas            16 - Supermercados
echo  7  - Discotecas          17 - Teatros
echo  8  - Clubes Nocturnos    18 - Centros de Convenciones
echo  9  - Parques             19 - Plazas
echo  10 - Aeropuertos         20 - Farmacias
echo  21 - TODAS las categorias
echo.
set /p cat="Numero de categoria: "
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
echo Que modo de busqueda?
echo  1 - Rapido (solo nombres y direcciones)
echo  2 - Profundo (telefonos y paginas web)
echo.
set /p modo="Opcion (1-2): "
if "%modo%"=="2" (set EXTRA=--deep) else (set EXTRA=)
echo.
echo ============================================
echo  Buscando %CAT% en toda Venezuela...
echo  Esto puede tomar varios minutos.
echo  Cuando termine, se sincronizara solo.
echo ============================================
echo.
if "%CAT%"=="--todas" (
    python main.py run %EXTRA%
) else (
    python main.py run "%CAT%" %EXTRA%
)
echo.
echo Busqueda completada.
pause
goto SYNC

:PORESTADO
cls
echo ============ BUSCAR POR ESTADO ============
echo.
echo Estados disponibles:
echo.
echo  1  - Distrito Capital    13 - Merida
echo  2  - Miranda             14 - Trujillo
echo  3  - La Guaira           15 - Barinas
echo  4  - Carabobo            16 - Portuguesa
echo  5  - Zulia               17 - Yaracuy
echo  6  - Lara                18 - Cojedes
echo  7  - Aragua              19 - Guarico
echo  8  - Bolivar             20 - Apure
echo  9  - Anzoategui          21 - Delta Amacuro
echo  10 - Sucre               22 - Amazonas
echo  11 - Monagas
echo  12 - Falcon
echo  13 - Nueva Esparta
echo.
set /p est="Numero de estado: "
if "%est%"=="1" set STATE=Distrito Capital
if "%est%"=="2" set STATE=Miranda
if "%est%"=="3" set STATE=La Guaira
if "%est%"=="4" set STATE=Carabobo
if "%est%"=="5" set STATE=Zulia
if "%est%"=="6" set STATE=Lara
if "%est%"=="7" set STATE=Aragua
if "%est%"=="8" set STATE=Bolivar
if "%est%"=="9" set STATE=Anzoategui
if "%est%"=="10" set STATE=Sucre
if "%est%"=="11" set STATE=Monagas
if "%est%"=="12" set STATE=Falcon
if "%est%"=="13" set STATE=Nueva Esparta
if "%est%"=="13" set STATE=Nueva Esparta
if "%est%"=="14" set STATE=Trujillo
if "%est%"=="15" set STATE=Barinas
if "%est%"=="16" set STATE=Portuguesa
if "%est%"=="17" set STATE=Yaracuy
if "%est%"=="18" set STATE=Cojedes
if "%est%"=="19" set STATE=Guarico
if "%est%"=="20" set STATE=Apure
if "%est%"=="21" set STATE=Delta Amacuro
if "%est%"=="22" set STATE=Amazonas
echo.
echo Categoria:
echo  1 - Restaurantes    2 - Hoteles    3 - Centros Comerciales
echo  4 - Gimnasios       5 - Hospitales 6 - Clinicas
echo  7 - Discotecas      8 - Clubes     9 - Parques
echo  10 - Aeropuertos   11 - Bares     12 - Cafeterias
echo  13 - Dep.          14 - Cines     15 - Universidades
echo  16 - Supermercados 17 - Teatros   18 - Convenciones
echo  19 - Plazas        20 - Farmacias
echo.
set /p cat="Numero de categoria: "
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
echo Modo:
echo  1 - Rapido  2 - Profundo
set /p modo="Opcion: "
if "%modo%"=="2" (set EXTRA=--deep) else (set EXTRA=)
echo.
echo ============================================
echo  Buscando %CAT% en %STATE%...
echo  Esto puede tomar varios minutos.
echo ============================================
echo.
python main.py run "%CAT%" "%STATE%" %EXTRA%
echo.
echo Busqueda completada.
pause
goto SYNC

:SYNC
cls
echo ============ SINCRONIZAR CON SUPABASE ============
echo.
set /p si="Subir los datos a la nube (Supabase)? (S/N): "
if /i "%si%"=="S" (
    echo Sincronizando...
    python main.py supabase-sync
    echo.
    echo Listo! Datos subidos a la nube.
    echo Tus companeros pueden verlos en la pagina web.
) else (
    echo OK, sin sincronizar.
)
echo.
pause
goto MENU

:STATS
cls
echo ============ ESTADISTICAS ============
echo.
python main.py stats
echo.
pause
goto MENU

:EXPORT
cls
echo ============ EXPORTAR ============
echo.
python main.py export
echo.
echo Archivos generados en la carpeta leads_data/
echo  - leads.csv  (para Excel)
echo  - leads.json (para desarrolladores)
echo.
pause
goto MENU

:SALIR
cls
echo Gracias por usar Lead Finder Venezuela!
echo.
pause
exit
