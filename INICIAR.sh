#!/bin/bash
# Lead Finder Venezuela - Nova Tech AI
# Uso: chmod +x INICIAR.sh && ./INICIAR.sh

set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "============================================"
echo "     LEAD FINDER VENEZUELA"
echo "     Nova Tech AI"
echo "============================================"
echo ""

# ---- DETECTAR PYTHON ----
PYTHON=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        if $cmd --version 2>&1 | grep -qi python; then
            PYTHON="$cmd"
            break
        fi
    fi
done
if [ -z "$PYTHON" ]; then
    for p in /usr/local/bin/python3 /opt/homebrew/bin/python3 /usr/bin/python3; do
        if [ -x "$p" ]; then
            PYTHON="$p"
            break
        fi
    done
fi
if [ -z "$PYTHON" ]; then
    echo "[ERROR] Python no encontrado. Instalalo desde https://python.org"
    exit 1
fi
echo "[OK] $($PYTHON --version)"

# ---- VERIFICAR NODE ----
if ! command -v node &>/dev/null; then
    echo "[ERROR] Node.js no encontrado. Instalalo desde https://nodejs.org"
    exit 1
fi
echo "[OK] Node.js $(node --version)"

# ---- INSTALAR DEPENDENCIAS DEL DASHBOARD ----
if [ ! -d "dashboard/node_modules" ]; then
    echo "[~] Instalando dependencias del dashboard..."
    cd "$ROOT/dashboard"
    npm install
    cd "$ROOT"
    echo "[OK] Dependencias instaladas"
fi

# ---- CREAR DIRECTORIO DE DATOS ----
mkdir -p leads_data

# ---- GENERAR LEADS.JSON SI HAY SQLITE ----
if [ ! -f "leads_data/leads.json" ]; then
    if [ -f "leads_data/leads.db" ]; then
        echo "[~] Exportando leads a JSON..."
        $PYTHON main.py export
    fi
fi

if [ -f "leads_data/leads.json" ]; then
    echo "[OK] leads.json encontrado"
else
    echo "[!] Sin datos aun. Usa la opcion 1 del menu para buscar leads."
fi

# ---- CONFIGURAR SMTP (si no existe) ----
if [ ! -f "leads_data/smtp_config.json" ]; then
    echo "[~] Configurando SMTP con Gmail..."
    node -e "require('fs').writeFileSync('leads_data/smtp_config.json',JSON.stringify({host:'smtp.gmail.com',port:587,user:'voltajevzla@gmail.com',password:'omei fwjx yeis cqgx',use_tls:true,from_name:'Voltaje Plus C.A.',configured:true},null,2))"
    if [ $? -eq 0 ]; then
        echo "[OK] SMTP configurado con voltajevzla@gmail.com"
    fi
fi
echo ""

# ---- LIMPIAR CACHE Y MATAR SERVIDOR ANTERIOR ----
rm -rf dashboard/.next 2>/dev/null || true
echo "[~] Cache de compilacion eliminada"
lsof -ti:3000 | xargs kill -9 2>/dev/null || true

# ---- INICIAR DASHBOARD EN SEGUNDO PLANO ----
echo "[~] Iniciando dashboard..."
cd "$ROOT/dashboard"
npm run dev &
DASHBOARD_PID=$!
cd "$ROOT"

# ---- ESPERAR A QUE EL SERVIDOR RESPONDA ----
echo "[~] Esperando al servidor..."
WAITED=0
while [ $WAITED -lt 60 ]; do
    sleep 2
    WAITED=$((WAITED + 2))
    if curl -s -o /dev/null --max-time 2 "http://localhost:3000/dashboard" 2>/dev/null; then
        echo "[OK] Dashboard listo!"
        break
    fi
done

if [ $WAITED -ge 60 ]; then
    echo "[ADVERTENCIA] El servidor no respondio en 60 segundos."
    echo "Revisa la terminal del dashboard para ver errores."
fi

# Abrir navegador
if command -v open &>/dev/null; then
    open http://localhost:3000/dashboard
elif command -v xdg-open &>/dev/null; then
    xdg-open http://localhost:3000/dashboard
fi

# ---- MENU DEL SCRAPER ----
while true; do
    clear 2>/dev/null || cls 2>/dev/null || true
    echo "============================================"
    echo "     LEAD FINDER VENEZUELA"
    echo "============================================"
    echo ""
    echo " Dashboard: http://localhost:3000/dashboard"
    echo ""
    echo " 1 - Buscar nuevos leads (scraper)"
    echo " 2 - Subir datos a la nube (Supabase sync)"
    echo " 3 - Ver estadisticas"
    echo " 0 - Cerrar todo"
    echo ""
    read -p "Elige: " opcion

    case $opcion in
        1)
            clear
            echo "============ BUSCAR LEADS ============"
            echo ""
            echo "Categoria:"
            echo " 1 - Restaurantes    11 - Bares"
            echo " 2 - Hoteles         12 - Cafeterias"
            echo " 3 - Centros Comerc. 13 - Centros Dep."
            echo " 4 - Gimnasios       14 - Cines"
            echo " 5 - Hospitales      15 - Universidades"
            echo " 6 - Clinicas        16 - Supermercados"
            echo " 7 - Discotecas      17 - Teatros"
            echo " 8 - Clubes Noct.    18 - Convenciones"
            echo " 9 - Parques         19 - Plazas"
            echo "10 - Aeropuertos     20 - Farmacias"
            echo "21 - TODAS"
            echo ""
            read -p "Numero: " cat
            case $cat in
                21) CAT="--todas" ;; 1) CAT="restaurantes" ;; 2) CAT="hoteles" ;; 3) CAT="centros comerciales" ;;
                4) CAT="gimnasios" ;; 5) CAT="hospitales" ;; 6) CAT="clinicas" ;; 7) CAT="discotecas" ;;
                8) CAT="clubes nocturnos" ;; 9) CAT="parques" ;; 10) CAT="aeropuertos" ;; 11) CAT="bares" ;;
                12) CAT="cafeterias" ;; 13) CAT="centros deportivos" ;; 14) CAT="cines" ;; 15) CAT="universidades" ;;
                16) CAT="supermercados" ;; 17) CAT="teatros" ;; 18) CAT="centros de convenciones" ;;
                19) CAT="plazas" ;; 20) CAT="farmacias" ;; *) echo "Invalido"; sleep 2; continue ;;
            esac
            echo ""
            echo "Modo: 1 - Rapido  2 - Profundo (telefonos/web)"
            read -p "Opcion: " modo
            EXTRA=""
            [ "$modo" = "2" ] && EXTRA="--deep"
            echo ""
            echo "Buscando... (no cierres esta terminal)"
            if [ "$CAT" = "--todas" ]; then
                $PYTHON main.py run $EXTRA
            else
                $PYTHON main.py run "$CAT" $EXTRA
            fi
            echo ""
            read -p "Subir a la nube ahora? (S/N): " sync
            if [ "$sync" = "S" ] || [ "$sync" = "s" ]; then
                $PYTHON main.py supabase-sync
                echo "Listo! Refresca el navegador."
            fi
            echo ""
            read -p "Presiona Enter para continuar..."
            ;;
        2)
            clear
            echo "Sincronizando con la nube..."
            $PYTHON main.py supabase-sync
            read -p "Presiona Enter para continuar..."
            ;;
        3)
            clear
            $PYTHON main.py stats
            read -p "Presiona Enter para continuar..."
            ;;
        0)
            echo "Cerrando el sistema..."
            kill $DASHBOARD_PID 2>/dev/null || true
            lsof -ti:3000 | xargs kill -9 2>/dev/null || true
            echo "Adios!"
            exit 0
            ;;
        *)
            echo "Opcion invalida"
            sleep 2
            ;;
    esac
done
