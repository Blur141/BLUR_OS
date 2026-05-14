#!/usr/bin/env bash
# BLUR OS Installer — main orchestrator
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG="/tmp/blur-install.log"
exec > >(tee -a "$LOG") 2>&1

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
die()     { echo -e "${RED}[ERROR]${NC} $*" >&2; exit 1; }

check_root() { [[ $EUID -eq 0 ]] || die "Run as root (sudo -i)"; }

check_uefi() {
    [[ -d /sys/firmware/efi/efivars ]] || die "UEFI required. Legacy BIOS not supported."
    success "UEFI confirmed"
}

check_network() {
    ping -c1 -W3 archlinux.org &>/dev/null || die "No internet. Connect and retry."
    success "Network OK"
}

collect_input() {
    echo ""
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}          BLUR OS Installer v1.0.0${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo ""

    # Disk
    lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    echo ""
    read -rp "Target disk (e.g. /dev/nvme0n1 or /dev/sda): " TARGET_DISK
    [[ -b "$TARGET_DISK" ]] || die "Not a valid block device: $TARGET_DISK"

    # Swap
    TOTAL_RAM_GB=$(awk '/MemTotal/ {printf "%d", $2/1024/1024 + 0.5}' /proc/meminfo)
    read -rp "Swap partition size in GiB [default: ${TOTAL_RAM_GB}]: " SWAP_SIZE
    SWAP_SIZE="${SWAP_SIZE:-$TOTAL_RAM_GB}"

    # User
    read -rp "Hostname: " HOSTNAME
    [[ -n "$HOSTNAME" ]] || die "Hostname cannot be empty"

    read -rp "Username: " USERNAME
    [[ "$USERNAME" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || die "Invalid username"

    read -rsp "Password: " PASSWORD; echo
    read -rsp "Confirm password: " PASSWORD2; echo
    [[ "$PASSWORD" == "$PASSWORD2" ]] || die "Passwords do not match"

    # Timezone
    read -rp "Timezone [default: Asia/Kolkata]: " TIMEZONE
    TIMEZONE="${TIMEZONE:-Asia/Kolkata}"
    [[ -f "/usr/share/zoneinfo/$TIMEZONE" ]] || die "Invalid timezone: $TIMEZONE"

    # GPU driver hint
    echo ""
    echo "GPU driver selection:"
    echo "  1) AMD (default)"
    echo "  2) Intel"
    echo "  3) NVIDIA (proprietary)"
    echo "  4) NVIDIA (open/nouveau)"
    read -rp "Choice [1]: " GPU_CHOICE
    GPU_CHOICE="${GPU_CHOICE:-1}"

    export TARGET_DISK SWAP_SIZE HOSTNAME USERNAME PASSWORD TIMEZONE GPU_CHOICE
    success "Configuration collected"
}

confirm() {
    echo ""
    warn "This will DESTROY all data on ${TARGET_DISK}!"
    read -rp "Type 'yes' to continue: " CONFIRM
    [[ "$CONFIRM" == "yes" ]] || die "Aborted by user"
}

main() {
    check_root
    check_uefi
    check_network
    collect_input
    confirm

    info "Starting installation..."
    timedatectl set-ntp true

    source "$SCRIPT_DIR/partitions.sh"
    partition_disk

    source "$SCRIPT_DIR/packages.sh"
    install_base_packages

    source "$SCRIPT_DIR/configure.sh"
    configure_system

    info "Generating initramfs..."
    arch-chroot /mnt mkinitcpio -p linux-lts

    info "Installing bootloader..."
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi \
        --bootloader-id=NiyasOS --recheck
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

    success ""
    success "BLUR OS installation complete!"
    success "Remove the installation media and reboot."
    read -rp "Reboot now? [y/N]: " REBOOT
    [[ "$REBOOT" =~ ^[Yy]$ ]] && reboot
}

main "$@"
