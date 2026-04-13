#!/bin/bash
# BillPlay - Go Sidecar Cross-Compilation Script
# Builds the ts-sidecar binary for Windows, macOS, and Linux
#
# Usage: ./build.sh [platform]
#   platform: all (default), windows, darwin, linux

set -e

SIDECAR_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${SIDECAR_DIR}/../bin"
MODULE_NAME="github.com/ocnaibill/switch-lan-relay/client/sidecar"

# Version from git tag or fallback
VERSION=$(git describe --tags --always 2>/dev/null || echo "dev")

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
        -ldflags="-s -w -X main.Version=${VERSION}" \
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
