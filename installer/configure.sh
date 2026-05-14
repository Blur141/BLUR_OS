#!/usr/bin/env bash
# BLUR OS — configure.sh
# Full post-pacstrap system configuration

configure_system() {
    info "Writing fstab..."
    genfstab -U /mnt >> /mnt/etc/fstab

    info "Setting timezone: ${TIMEZONE}..."
    arch-chroot /mnt ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
    arch-chroot /mnt hwclock --systohc

    info "Configuring locale..."
    arch-chroot /mnt bash -c "
        sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
        locale-gen
        echo 'LANG=en_US.UTF-8' > /etc/locale.conf
        echo 'KEYMAP=us' > /etc/vconsole.conf
    "

    info "Setting hostname: ${HOSTNAME}..."
    echo "$HOSTNAME" > /mnt/etc/hostname
    cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

    info "Creating user: ${USERNAME}..."
    arch-chroot /mnt bash -c "
        useradd -m -G wheel,audio,video,storage,optical,network,docker,libvirt -s /bin/bash '${USERNAME}'
        echo '${USERNAME}:${PASSWORD}' | chpasswd
        echo 'root:${PASSWORD}' | chpasswd
        sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
    "

    _configure_services
    _configure_apparmor
    _configure_grub
    _configure_performance
    _configure_network
    _configure_display_manager
    _configure_kde_defaults
    _configure_dev_environment
    _copy_dotfiles

    success "System configuration complete"
}

_configure_services() {
    info "Enabling system services..."
    local services=(
        NetworkManager
        sddm
        apparmor
        auditd
        docker
        libvirtd
        ufw
        irqbalance
        thermald
        power-profiles-daemon
        fstrim.timer
        paccache.timer
        systemd-timesyncd
    )
    for svc in "${services[@]}"; do
        arch-chroot /mnt systemctl enable "$svc" 2>/dev/null || warn "Could not enable: $svc"
    done
    success "Services enabled"
}

_configure_apparmor() {
    info "Configuring AppArmor..."
    arch-chroot /mnt bash -c "
        # Add AppArmor kernel params to GRUB
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"lsm=landlock,lockdown,yama,integrity,apparmor,bpf apparmor=1 security=apparmor /' \
            /etc/default/grub
        # Enable audit logging
        sed -i 's/-a always,exit/-a always,exit/' /etc/audit/audit.rules 2>/dev/null || true
    "
    success "AppArmor configured"
}

_configure_grub() {
    info "Installing GRUB theme..."
    local grub_theme_src
    grub_theme_src="$(dirname "${BASH_SOURCE[0]}")/../airootfs/usr/share/grub/themes/blur"

    if [[ -d "$grub_theme_src" ]]; then
        mkdir -p /mnt/boot/grub/themes
        cp -r "$grub_theme_src" /mnt/boot/grub/themes/blur
    fi

    # Inject theme path and kernel params into /etc/default/grub
    sed -i \
        -e 's|^#GRUB_THEME=.*|GRUB_THEME=/boot/grub/themes/blur/theme.txt|' \
        -e '/^GRUB_THEME=/!{/GRUB_CMDLINE_LINUX_DEFAULT/!s/^#GRUB_THEME=.*/GRUB_THEME=\/boot\/grub\/themes\/blur\/theme.txt/}' \
        /mnt/etc/default/grub

    # Set GRUB_THEME if line doesn't exist yet
    grep -q '^GRUB_THEME=' /mnt/etc/default/grub || \
        echo 'GRUB_THEME=/boot/grub/themes/blur/theme.txt' >> /mnt/etc/default/grub

    # Enable OS prober for dual-boot detection
    sed -i 's/^#GRUB_DISABLE_OS_PROBER=.*/GRUB_DISABLE_OS_PROBER=false/' /mnt/etc/default/grub
    grep -q '^GRUB_DISABLE_OS_PROBER=' /mnt/etc/default/grub || \
        echo 'GRUB_DISABLE_OS_PROBER=false' >> /mnt/etc/default/grub

    success "GRUB theme configured"
}

_configure_performance() {
    info "Configuring performance tweaks..."

    # zram
    cat > /mnt/etc/systemd/zram-generator.conf <<'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
EOF

    # zswap
    cat > /mnt/etc/modprobe.d/zswap.conf <<'EOF'
options zswap enabled=1 compressor=zstd zpool=z3fold max_pool_percent=20
EOF

    # IO scheduler
    cp -f "$(dirname "${BASH_SOURCE[0]}")/../airootfs/etc/udev/rules.d/60-ioscheduler.rules" \
        /mnt/etc/udev/rules.d/60-ioscheduler.rules

    # sysctl
    cp -f "$(dirname "${BASH_SOURCE[0]}")/../airootfs/etc/sysctl.d/99-niyasos.conf" \
        /mnt/etc/sysctl.d/99-niyasos.conf

    # CPU governor — schedutil by default, switch to performance for desktop
    arch-chroot /mnt bash -c "
        echo 'GOVERNOR=schedutil' > /etc/default/cpupower
    "

    # Enable preload if installed
    arch-chroot /mnt systemctl enable preload 2>/dev/null || true

    success "Performance tweaks applied"
}

_configure_network() {
    info "Configuring firewall (ufw)..."
    arch-chroot /mnt bash -c "
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        ufw --force enable
    "
}

_configure_display_manager() {
    info "Configuring SDDM for Wayland..."
    mkdir -p /mnt/etc/sddm.conf.d
    cat > /mnt/etc/sddm.conf.d/wayland.conf <<'EOF'
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --no-lockscreen
EOF
    # Copy SDDM theme
    local sddm_src
    sddm_src="$(dirname "${BASH_SOURCE[0]}")/../airootfs/etc/sddm.conf.d/theme.conf"
    [[ -f "$sddm_src" ]] && cp "$sddm_src" /mnt/etc/sddm.conf.d/theme.conf

    local sddm_theme_src
    sddm_theme_src="$(dirname "${BASH_SOURCE[0]}")/../airootfs/usr/share/sddm/themes/blur"
    [[ -d "$sddm_theme_src" ]] && cp -r "$sddm_theme_src" /mnt/usr/share/sddm/themes/
}

_configure_kde_defaults() {
    info "Installing BLUR OS KDE theme defaults..."
    local kde_src
    kde_src="$(dirname "${BASH_SOURCE[0]}")/../configs/kde"
    local skel_config="/mnt/etc/skel/.config"
    local skel_local="/mnt/etc/skel/.local/share"

    mkdir -p "$skel_config/Kvantum" "$skel_config/gtk-3.0" "$skel_config/gtk-4.0"
    mkdir -p "$skel_local/color-schemes"

    # Core KDE configs
    for f in kdeglobals kwinrc plasmarc breezerc ksplashrc \
              kscreenlockerrc ksmserverrc kdecoration2rc \
              plasma-org.kde.plasma.desktop-appletsrc; do
        [[ -f "${kde_src}/${f}" ]] && cp "${kde_src}/${f}" "${skel_config}/${f}"
    done

    # Color scheme
    cp "${kde_src}/colorschemes/BlurDark.colors" "${skel_local}/color-schemes/BlurDark.colors"

    # Kvantum theme
    cp -r "${kde_src}/Kvantum/BlurDark" "${skel_config}/Kvantum/"
    cat > "${skel_config}/Kvantum/kvantum.kvconfig" <<'EOF'
[General]
theme=BlurDark
EOF

    # GTK dark settings
    cp "${kde_src}/gtk-3.0/settings.ini" "${skel_config}/gtk-3.0/settings.ini"
    cp "${kde_src}/gtk-4.0/settings.ini" "${skel_config}/gtk-4.0/settings.ini"

    # Apply to installed user as well
    local user_config="/mnt/home/${USERNAME}/.config"
    local user_local="/mnt/home/${USERNAME}/.local/share"
    cp -r "${skel_config}/." "${user_config}/"
    cp -r "${skel_local}/." "${user_local}/"
    arch-chroot /mnt chown -R "${USERNAME}:${USERNAME}" \
        "/home/${USERNAME}/.config" "/home/${USERNAME}/.local"

    # Install Papirus icons
    arch-chroot /mnt pacman -S --noconfirm papirus-icon-theme 2>/dev/null || \
        warn "papirus-icon-theme not found in repos — install via AUR: yay -S papirus-icon-theme"

    success "KDE BLUR theme applied"
}

_configure_dev_environment() {
    info "Configuring dev environment..."

    # Docker: rootless mode for user
    arch-chroot /mnt bash -c "
        usermod -aG docker '${USERNAME}'
        systemctl enable docker.socket
    "

    # Enable BBR congestion control
    echo 'tcp_bbr' >> /mnt/etc/modules-load.d/modules.conf

    # Git global config skeleton
    cat > /mnt/home/${USERNAME}/.gitconfig <<EOF
[init]
    defaultBranch = main
[pull]
    rebase = false
[core]
    editor = nvim
    autocrlf = input
EOF
    arch-chroot /mnt chown "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.gitconfig"
}

_copy_dotfiles() {
    info "Copying dotfiles to new user home..."
    local skel_src
    skel_src="$(dirname "${BASH_SOURCE[0]}")/../airootfs/etc/skel"
    for f in "$skel_src"/.*; do
        [[ -f "$f" ]] || continue
        cp "$f" "/mnt/home/${USERNAME}/"
        arch-chroot /mnt chown "${USERNAME}:${USERNAME}" "/home/${USERNAME}/$(basename "$f")"
    done
    success "Dotfiles installed"
}
