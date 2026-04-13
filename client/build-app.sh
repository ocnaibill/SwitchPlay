#!/bin/bash
# ==========================================
# SwitchPlay — Full Build Script
# Compiles Go sidecar + packages Electron app
#
# Usage:
#   ./build-app.sh [platform]
#   Platforms: mac, win, linux, all
# ==========================================

set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIDECAR_DIR="${ROOT_DIR}/sidecar"
BIN_DIR="${ROOT_DIR}/bin"

echo "🎮 SwitchPlay — Build completo"
echo "================================"
echo ""

# ---- Step 1: Compile Go sidecar ----
echo "📦 Passo 1: Compilando Go sidecar..."

PLATFORM=${1:-mac}

case ${PLATFORM} in
    mac)
        echo "  → macOS arm64 + x64..."
        (cd "${SIDECAR_DIR}" && GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o "${BIN_DIR}/ts-sidecar-darwin-arm64" .)
        (cd "${SIDECAR_DIR}" && GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o "${BIN_DIR}/ts-sidecar-darwin-amd64" .)
        ;;
    win)
        echo "  → Windows amd64..."
        (cd "${SIDECAR_DIR}" && GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o "${BIN_DIR}/ts-sidecar-win32-amd64.exe" .)
        ;;
    linux)
        echo "  → Linux amd64..."
        (cd "${SIDECAR_DIR}" && GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o "${BIN_DIR}/ts-sidecar-linux-amd64" .)
        ;;
    all)
        echo "  → Todas as plataformas..."
        (cd "${SIDECAR_DIR}" && GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o "${BIN_DIR}/ts-sidecar-darwin-arm64" .)
        (cd "${SIDECAR_DIR}" && GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o "${BIN_DIR}/ts-sidecar-darwin-amd64" .)
        (cd "${SIDECAR_DIR}" && GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o "${BIN_DIR}/ts-sidecar-win32-amd64.exe" .)
        (cd "${SIDECAR_DIR}" && GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o "${BIN_DIR}/ts-sidecar-linux-amd64" .)
        ;;
    *)
        echo "❌ Plataforma desconhecida: ${PLATFORM}"
        echo "   Use: mac, win, linux, all"
        exit 1
        ;;
esac

echo "  ✅ Sidecar compilado!"
echo ""

echo "  📋 Binários em bin/:"
ls -lh "${BIN_DIR}"/ts-sidecar-* 2>/dev/null || echo "  (nenhum binário encontrado)"
echo ""

# ---- Step 2: Check for lan-play binary ----
echo "🔍 Passo 2: Verificando binário lan-play..."
LAN_PLAY_COUNT=$(ls "${BIN_DIR}"/lan-play* 2>/dev/null | wc -l | tr -d ' ')
if [ "${LAN_PLAY_COUNT}" -gt 0 ]; then
    echo "  ✅ lan-play encontrado:"
    ls -lh "${BIN_DIR}"/lan-play* 2>/dev/null
else
    echo "  ⚠️  lan-play NÃO encontrado em bin/"
    echo "  Baixe de: https://github.com/spacemeowx2/switch-lan-play/releases"
    echo "  Coloque em: ${BIN_DIR}/"
    echo ""
fi
echo ""

# ---- Step 3: Package with electron-builder ----
echo "📦 Passo 3: Empacotando com electron-builder..."

case ${PLATFORM} in
    mac)
        npm run build:mac
        ;;
    win)
        npm run build:win
        ;;
    linux)
        npm run build:linux
        ;;
    all)
        npm run build:all
        ;;
esac

echo ""
echo "✅ Build completo!"
echo "📁 Pacotes gerados em: ${ROOT_DIR}/dist/"
ls -lh "${ROOT_DIR}/dist/" 2>/dev/null
