#!/usr/bin/env bash
# NiyasOS — partitions.sh
# Partition layout: GPT | EFI (1G) | Swap | XFS root (remainder)

partition_disk() {
    info "Partitioning ${TARGET_DISK}..."

    # Wipe existing signatures
    wipefs -af "$TARGET_DISK"
    sgdisk --zap-all "$TARGET_DISK"

    # Create partition table
    sgdisk \
        -n 1:0:+1G   -t 1:ef00 -c 1:"EFI"  \
        -n 2:0:+"${SWAP_SIZE}G" -t 2:8200 -c 2:"swap" \
        -n 3:0:0     -t 3:8300 -c 3:"root"  \
        "$TARGET_DISK"

    partprobe "$TARGET_DISK"
    sleep 2

    # Identify partitions (handles both nvme0n1p1 and sda1 naming)
    if [[ "$TARGET_DISK" == *nvme* ]]; then
        EFI_PART="${TARGET_DISK}p1"
        SWAP_PART="${TARGET_DISK}p2"
        ROOT_PART="${TARGET_DISK}p3"
    else
        EFI_PART="${TARGET_DISK}1"
        SWAP_PART="${TARGET_DISK}2"
        ROOT_PART="${TARGET_DISK}3"
    fi

    export EFI_PART SWAP_PART ROOT_PART

    info "Formatting partitions..."
    mkfs.fat -F32 -n EFI "$EFI_PART"
    mkswap -L swap "$SWAP_PART"
    mkfs.xfs -f -L root "$ROOT_PART"

    info "Mounting..."
    mount "$ROOT_PART" /mnt
    mkdir -p /mnt/boot/efi
    mount "$EFI_PART" /mnt/boot/efi
    swapon "$SWAP_PART"

    success "Partitions ready — EFI=${EFI_PART} SWAP=${SWAP_PART} ROOT=${ROOT_PART}"
}
