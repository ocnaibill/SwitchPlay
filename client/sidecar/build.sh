#!/bin/bash
# ==========================================
# SwitchPlay — Go Sidecar Build Script
# Cross-compiles ts-sidecar for all platforms.
#
# Usage: ./build.sh [platform]
#   platform: all (default), windows, darwin, linux
# ==========================================

set -e

SIDECAR_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${SIDECAR_DIR}/../bin"

# Version from git tag or fallback
VERSION=$(git describe --tags --always 2>/dev/null || echo "dev")

# --- Build ldflags with injected secrets ---
LDFLAGS="-s -w"
LDFLAGS="${LDFLAGS} -X main.Version=${VERSION}"

echo "🔨 Building ts-sidecar ${VERSION}..."
echo ""

mkdir -p "${OUTPUT_DIR}"

build_target() {
    local os=$1
    local arch=$2
    local ext=$3

    local output="${OUTPUT_DIR}/ts-sidecar-${os}-${arch}${ext}"
    echo "  → ${os}/${arch}..."

    GOOS=${os} GOARCH=${arch} go build \
        -ldflags="${LDFLAGS}" \
        -o "${output}" \
        "${SIDECAR_DIR}"

    echo "    ✅ $(du -h "${output}" | cut -f1) → ${output}"
}

PLATFORM=${1:-all}

case ${PLATFORM} in
    windows)
        build_target windows amd64 .exe
        ;;
    darwin)
        build_target darwin amd64 ""
        build_target darwin arm64 ""
        ;;
    linux)
        build_target linux amd64 ""
        build_target linux arm64 ""
        ;;
    all)
        build_target windows amd64 .exe
        build_target darwin amd64 ""
        build_target darwin arm64 ""
        build_target linux amd64 ""
        build_target linux arm64 ""
        ;;
    *)
        echo "❌ Platform desconhecida: ${PLATFORM}"
        echo "   Use: all, windows, darwin, linux"
        exit 1
        ;;
esac

echo ""
echo "✅ Build completo! Binários em: ${OUTPUT_DIR}/"
ls -lh "${OUTPUT_DIR}"/ts-sidecar-*
