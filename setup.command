#!/bin/bash
# Lead Finder Venezuela - Nova Tech AI
# Setup para macOS - haz doble clic para instalar

cd "$(dirname "$0")"

echo "============================================"
echo "  Lead Finder Venezuela - Instalacion"
echo "============================================"
echo ""

echo "PASO 1: Verificando Python..."
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
    echo "  Python no encontrado. Descargando..."
    curl -L -o /tmp/python-installer.pkg https://www.python.org/ftp/python/3.11.9/python-3.11.9-macos11.pkg
    sudo installer -pkg /tmp/python-installer.pkg -target /
    PYTHON="python3"
fi
echo "  OK: $($PYTHON --version)"
echo ""

echo "PASO 2: Verificando Node.js..."
if ! command -v node &>/dev/null; then
    echo "  Node.js no encontrado. Descargando..."
    curl -L -o /tmp/node-installer.pkg https://nodejs.org/dist/v20.18.0/node-v20.18.0.pkg
    sudo installer -pkg /tmp/node-installer.pkg -target /
fi
echo "  OK: $(node --version)"
echo ""

echo "PASO 3: Instalando librerias Python..."
pip3 install scrapling flask supabase -q 2>/dev/null || $PYTHON -m pip install scrapling flask supabase -q
echo "  OK"
echo ""

echo "PASO 4: Preparando el Dashboard..."
if [ ! -d "dashboard/node_modules/next" ]; then
    echo "  Instalando dependencias del dashboard (1-2 min)..."
    cd dashboard
    npm install --loglevel=error
    cd "$(dirname "$0")"
fi
echo "  OK"
echo ""

echo "PASO 5: Creando carpeta de datos..."
mkdir -p leads_data
echo "  OK"
echo ""

echo "============================================"
echo "  INSTALACION COMPLETADA!"
echo "============================================"
echo ""
echo "  Ahora abre INICIAR.command (doble clic)"
echo ""
read -p "Presiona Enter para salir..."
