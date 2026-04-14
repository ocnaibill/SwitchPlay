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

VERSION=$(git describe --tags --always 2>/dev/null || echo "dev")

LDFLAGS="-s -w"
LDFLAGS="${LDFLAGS} -X main.Version=${VERSION}"

mkdir -p "${BIN_DIR}"

# ---- Step 1: Compile Go sidecar ----
echo "📦 Step 1: Compiling Go sidecar..."

PLATFORM=${1:-mac}

case ${PLATFORM} in
    mac)
        echo "  → macOS arm64 + x64..."
        (cd "${SIDECAR_DIR}" && GOOS=darwin GOARCH=arm64 go build -ldflags="${LDFLAGS}" -o "${BIN_DIR}/ts-sidecar-darwin-arm64" .)
        (cd "${SIDECAR_DIR}" && GOOS=darwin GOARCH=amd64 go build -ldflags="${LDFLAGS}" -o "${BIN_DIR}/ts-sidecar-darwin-amd64" .)
        ;;
    win)
        echo "  → Windows amd64..."
        (cd "${SIDECAR_DIR}" && GOOS=windows GOARCH=amd64 go build -ldflags="${LDFLAGS}" -o "${BIN_DIR}/ts-sidecar-win32-amd64.exe" .)
        ;;
    linux)
        echo "  → Linux amd64..."
        (cd "${SIDECAR_DIR}" && GOOS=linux GOARCH=amd64 go build -ldflags="${LDFLAGS}" -o "${BIN_DIR}/ts-sidecar-linux-amd64" .)
        ;;
    all)
        echo "  → All platforms..."
        (cd "${SIDECAR_DIR}" && GOOS=darwin GOARCH=arm64 go build -ldflags="${LDFLAGS}" -o "${BIN_DIR}/ts-sidecar-darwin-arm64" .)
        (cd "${SIDECAR_DIR}" && GOOS=darwin GOARCH=amd64 go build -ldflags="${LDFLAGS}" -o "${BIN_DIR}/ts-sidecar-darwin-amd64" .)
        (cd "${SIDECAR_DIR}" && GOOS=windows GOARCH=amd64 go build -ldflags="${LDFLAGS}" -o "${BIN_DIR}/ts-sidecar-win32-amd64.exe" .)
        (cd "${SIDECAR_DIR}" && GOOS=linux GOARCH=amd64 go build -ldflags="${LDFLAGS}" -o "${BIN_DIR}/ts-sidecar-linux-amd64" .)
        ;;
    *)
        echo "❌ Unknown platform: ${PLATFORM}"
        echo "   Use: mac, win, linux, all"
        exit 1
        ;;
esac

echo "  ✅ Sidecar compiled!"
echo ""

echo "  📋 Binaries in bin/:"
ls -lh "${BIN_DIR}"/ts-sidecar-* 2>/dev/null || echo "  (no binaries found)"
echo ""

# ---- Step 2: Check for lan-play binary ----
echo "🔍 Step 2: Checking lan-play binary..."
LAN_PLAY_COUNT=$(ls "${BIN_DIR}"/lan-play* 2>/dev/null | wc -l | tr -d ' ')
if [ "${LAN_PLAY_COUNT}" -gt 0 ]; then
    echo "  ✅ lan-play found:"
    ls -lh "${BIN_DIR}"/lan-play* 2>/dev/null
else
    echo "  ⚠️  lan-play NOT found in bin/"
    echo "  Download from: https://github.com/spacemeowx2/switch-lan-play/releases"
    echo "  Place in: ${BIN_DIR}/"
    echo ""
fi
echo ""

# ---- Step 3: Package with electron-builder ----
echo "📦 Step 3: Packaging with electron-builder..."

# Inherit GH_TOKEN for github releases publishing
export GH_TOKEN="${GH_TOKEN:-}"
PUBLISH_FLAG=""
if [ -n "$GITHUB_ACTIONS" ]; then
    PUBLISH_FLAG="--publish always"
fi

case ${PLATFORM} in
    mac)
        npm run build:mac -- $PUBLISH_FLAG
        ;;
    win)
        npm run build:win -- $PUBLISH_FLAG
        ;;
    linux)
        npm run build:linux -- $PUBLISH_FLAG
        ;;
    all)
        npm run build:all -- $PUBLISH_FLAG
        ;;
esac

echo ""
echo "✅ Build complete!"
echo "📁 Distributable packages in: ${ROOT_DIR}/dist/"
ls -lh "${ROOT_DIR}/dist/" 2>/dev/null
