#!/usr/bin/env bash
# NiyasOS — test-in-qemu.sh
# Boot the built ISO in QEMU/UEFI for testing.
# Requires: qemu, OVMF firmware

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ISO=$(ls "${REPO_ROOT}/out/"*.iso 2>/dev/null | head -1)
OVMF_PATH="${OVMF_PATH:-/usr/share/ovmf/x64/OVMF.fd}"

[[ -n "$ISO" ]] || { echo "No ISO found in out/. Run scripts/build-iso.sh first."; exit 1; }
[[ -f "$OVMF_PATH" ]] || OVMF_PATH="/usr/share/edk2/x64/OVMF.fd"
[[ -f "$OVMF_PATH" ]] || { echo "OVMF not found. Install: pacman -S edk2-ovmf"; exit 1; }

echo "[*] Booting: $ISO"
qemu-system-x86_64 \
    -enable-kvm \
    -machine q35 \
    -cpu host \
    -smp cores=4 \
    -m 4G \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF_PATH" \
    -cdrom "$ISO" \
    -boot order=d \
    -vga virtio \
    -display sdl,gl=on \
    -audiodev pa,id=snd \
    -device ich9-intel-hda \
    -device hda-output,audiodev=snd \
    -net nic,model=virtio \
    -net user \
    -usb \
    -device usb-tablet
