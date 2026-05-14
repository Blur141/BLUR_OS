#!/usr/bin/env bash
# NiyasOS — build-iso.sh
# Run this on an Arch Linux host (or in a container) to build the ISO.
# Requires: archiso, git
# Usage: sudo bash scripts/build-iso.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="/tmp/niyasos-build"
OUT_DIR="${REPO_ROOT}/out"

check_deps() {
    command -v mkarchiso &>/dev/null || {
        echo "archiso not found. Install: pacman -S archiso"
        exit 1
    }
}

clean_build() {
    [[ -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"
    mkdir -p "$OUT_DIR"
}

copy_installer() {
    # Bundle the installer scripts into airootfs
    mkdir -p "${REPO_ROOT}/airootfs/usr/share/niyasos"
    cp -r "${REPO_ROOT}/installer" "${REPO_ROOT}/airootfs/usr/share/niyasos/"
    cp -r "${REPO_ROOT}/configs"   "${REPO_ROOT}/airootfs/usr/share/niyasos/"
}

build() {
    echo "[*] Building NiyasOS ISO..."
    mkarchiso -v \
        -w "$WORK_DIR" \
        -o "$OUT_DIR" \
        "$REPO_ROOT"
    echo "[OK] ISO written to: ${OUT_DIR}"
    ls -lh "${OUT_DIR}"/*.iso
}

check_deps
clean_build
copy_installer
build
