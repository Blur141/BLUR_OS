#!/usr/bin/env bash
# NiyasOS — packages.sh
# Bootstrap base system with pacstrap, then set up AUR + Flatpak

GPU_PACKAGES=()
_set_gpu_packages() {
    case "$GPU_CHOICE" in
        2) GPU_PACKAGES=(mesa vulkan-intel intel-media-driver libva-intel-driver) ;;
        3) GPU_PACKAGES=(nvidia-lts nvidia-utils nvidia-settings cuda) ;;
        4) GPU_PACKAGES=(mesa xf86-video-nouveau) ;;
        *) GPU_PACKAGES=(mesa vulkan-radeon libva-mesa-driver mesa-vdpau) ;;
    esac
}

install_base_packages() {
    _set_gpu_packages
    info "Running pacstrap (this takes a while)..."

    pacstrap -K /mnt \
        base base-devel linux-lts linux-lts-headers linux-firmware \
        amd-ucode \
        grub efibootmgr os-prober dosfstools \
        xfsprogs \
        systemd networkmanager \
        bash bash-completion \
        git curl wget rsync \
        neovim nano \
        "${GPU_PACKAGES[@]}"

    success "Base system installed"
}

install_full_packages() {
    info "Installing full package set inside chroot..."

    # Sync mirrors with reflector
    arch-chroot /mnt bash -c "
        pacman -S --noconfirm reflector
        reflector --country 'United States,Germany,India' --age 12 \
            --protocol https --sort rate --save /etc/pacman.d/mirrorlist
        pacman -Syu --noconfirm
    "

    # Core system
    arch-chroot /mnt pacman -S --noconfirm --needed \
        plasma-meta sddm sddm-kcm \
        kde-applications-meta \
        plasma-wayland-session xorg-xwayland \
        wayland wayland-protocols wayland-utils \
        pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
        apparmor audit firejail ufw \
        docker docker-compose podman podman-compose buildah skopeo \
        qemu-full libvirt virt-manager \
        flatpak xdg-desktop-portal xdg-desktop-portal-kde \
        python python-pip nodejs npm rust cargo gcc clang cmake meson ninja \
        git github-cli \
        htop btop nvtop iotop nethogs \
        bat eza fd ripgrep fzf zoxide jq \
        zram-generator irqbalance thermald power-profiles-daemon \
        noto-fonts noto-fonts-emoji ttf-jetbrains-mono ttf-fira-code \
        kitty konsole dolphin ark firefox

    success "Full package set installed"
}

setup_aur_helper() {
    info "Installing yay (AUR helper)..."
    arch-chroot /mnt bash -c "
        cd /tmp
        sudo -u nobody git clone https://aur.archlinux.org/yay-bin.git
        cd yay-bin
        sudo -u nobody makepkg -si --noconfirm
        cd / && rm -rf /tmp/yay-bin
    " || warn "yay install failed — install manually post-boot"

    # AUR packages
    arch-chroot /mnt sudo -u "$USERNAME" bash -c "
        yay -S --noconfirm \
            preload \
            ananicy-cpp \
            visual-studio-code-bin \
            gitlab-runner \
            brave-bin \
            timeshift \
            2>/dev/null || true
    " || warn "Some AUR packages failed — retry post-boot with: yay -S <package>"

    success "AUR helper ready"
}

setup_flatpak() {
    info "Configuring Flatpak..."
    arch-chroot /mnt bash -c "
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    "
    success "Flatpak Flathub remote added"
}
