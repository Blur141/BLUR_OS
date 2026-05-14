<![CDATA[<p align="center">
  <img src="assets/banner.png" alt="BLUR OS Banner" width="100%"/>
</p>

<p align="center">
  <b>Arch-based · Developer-first · Security-hardened · KDE Plasma / Wayland</b>
</p>

<p align="center">
  <img alt="Arch Linux" src="https://img.shields.io/badge/base-Arch%20Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white"/>
  <img alt="Kernel" src="https://img.shields.io/badge/kernel-linux--lts-black?style=flat-square&logo=linux&logoColor=white"/>
  <img alt="Desktop" src="https://img.shields.io/badge/desktop-KDE%20Plasma%20(Wayland)-3498DB?style=flat-square&logo=kde&logoColor=white"/>
  <img alt="Version" src="https://img.shields.io/badge/version-1.0.0-brightgreen?style=flat-square"/>
  <img alt="License" src="https://img.shields.io/github/license/Blur141/BLUR_OS?style=flat-square"/>
  <img alt="Build" src="https://img.shields.io/github/actions/workflow/status/Blur141/BLUR_OS/build-iso.yml?style=flat-square&label=ISO%20build"/>
</p>

---

## What is BLUR OS?

**BLUR OS** is a custom Arch Linux-based distribution built with `archiso`. It ships a fully configured **KDE Plasma / Wayland** desktop with a curated developer toolchain, aggressive performance tuning, and security-hardened defaults — all ready to boot from a single ISO.

> Think of it as Arch Linux with the hard work already done: partitioning, bootloader, AppArmor, zram, IO schedulers, KDE theming, Docker, Flatpak, Rust, Node, Python, and more — configured and enabled out of the box.

---

## ✨ Highlights

| Category | Details |
|---|---|
| 🏗️ **Base** | Arch Linux + `linux-lts` kernel |
| 🖥️ **Desktop** | KDE Plasma 6 · Wayland-native (SDDM) |
| 🔒 **Security** | AppArmor · auditd · ufw · firejail · GnuPG |
| ⚡ **Performance** | zram (zstd) · zswap (z3fold) · IO scheduler udev rules · BBR TCP · preload · ananicy-cpp |
| 📦 **Packages** | Pacman + AUR (yay) + Flatpak (Flathub) |
| 🛠️ **Dev Tools** | Python · Node.js · Rust · GCC · Clang · Docker · Podman · Git · GitHub CLI · GitLab Runner · QEMU · libvirt |
| 💾 **File System** | XFS (root) · GPT with EFI + swap partition |
| 🌐 **Bootloader** | GRUB (UEFI) with custom BLUR theme |
| 🐚 **Shell** | Bash (with fzf, zoxide, eza, bat aliases) |
| 🎨 **Theme** | BlurDark — custom Kvantum + Breeze color scheme |

---

## 🗂️ Repository Structure

```
BLUR_OS/
├── profiledef.sh              # archiso profile definition
├── packages.x86_64            # full package list for the live ISO
│
├── airootfs/                  # filesystem overlay onto the live environment
│   ├── etc/
│   │   ├── pacman.conf        # custom pacman configuration
│   │   ├── mkinitcpio.conf    # initramfs hooks
│   │   ├── sysctl.d/          # kernel parameter tuning
│   │   ├── udev/rules.d/      # IO scheduler udev rules
│   │   ├── modprobe.d/        # zswap configuration
│   │   ├── systemd/           # zram-generator config
│   │   ├── apparmor.d/        # AppArmor profiles
│   │   ├── security/          # limits.conf
│   │   └── skel/              # default user dotfiles (.bashrc, .bash_profile)
│   └── usr/local/bin/
│       ├── blur-install       # live-boot installer launcher
│       └── blur-welcome       # post-install welcome script
│
├── installer/                 # installation scripts (run on live boot)
│   ├── install.sh             # main orchestrator
│   ├── partitions.sh          # GPT: EFI + swap + XFS root
│   ├── packages.sh            # pacstrap + AUR (yay) + Flatpak
│   └── configure.sh           # locale, users, services, AppArmor, perf, KDE
│
├── configs/
│   ├── kde/                   # KDE Plasma default configs (kdeglobals, kwinrc, …)
│   └── performance/           # cpupower & preload config
│
├── grub/grub.cfg              # GRUB menu configuration
├── efiboot/                   # EFI boot loader entries
│
├── scripts/
│   ├── build-iso.sh           # build the ISO on an Arch Linux host
│   ├── generate-grub-assets.sh # generate GRUB theme images
│   └── test-in-qemu.sh        # boot ISO in QEMU/OVMF for local testing
│
└── .github/workflows/
    ├── build-iso.yml          # CI: build ISO on every push
    ├── release.yml            # CD: publish release + attach ISO
    └── validate-packages.yml  # lint: verify packages exist in repos
```

---

## 🚀 Building the ISO

> **Requires an Arch Linux host** (or an Arch Linux Docker container).

### 1. Install the build dependency

```bash
sudo pacman -S archiso
```

### 2. Clone the repository

```bash
git clone https://github.com/Blur141/BLUR_OS.git
cd BLUR_OS
```

### 3. Build

```bash
sudo bash scripts/build-iso.sh
```

The ISO will be written to `out/blur-*.iso`.

> **Tip:** The CI pipeline (GitHub Actions) builds the ISO automatically on every push to `main` or `dev` using an Arch Linux container. You can download the artifact from the **Actions** tab without needing a local Arch system.

---

## 🧪 Testing in QEMU

After building, boot the ISO locally with QEMU/UEFI — no bare-metal needed:

```bash
# Install QEMU + OVMF firmware
sudo pacman -S qemu-full edk2-ovmf

# Launch
bash scripts/test-in-qemu.sh
```

This starts a VM with 4 CPU cores, 4 GB RAM, Virtio GPU (OpenGL), and USB tablet for clean mouse input.

---

## 💿 Installing BLUR OS

Boot the live ISO, open a terminal, and run:

```bash
sudo blur-install
# or directly:
sudo bash /usr/share/niyasos/installer/install.sh
```

The interactive installer will ask for:

| Prompt | Example |
|---|---|
| Target disk | `/dev/nvme0n1` |
| Swap size (GiB) | Auto-detected from RAM |
| Hostname | `blur-pc` |
| Username | `niyas` |
| Password | *(hidden input)* |
| Timezone | `Asia/Kolkata` *(default)* |
| GPU driver | AMD / Intel / NVIDIA (proprietary) / NVIDIA (open) |

The installer will then:
1. Partition the disk (GPT: 512 MiB EFI · swap · XFS root)
2. `pacstrap` all packages
3. Configure locale, hostname, users, sudoers
4. Enable all services (NetworkManager, SDDM, AppArmor, Docker, ufw, …)
5. Apply performance tuning (zram, zswap, IO scheduler, BBR TCP)
6. Install GRUB with the custom BLUR theme
7. Copy KDE defaults and dotfiles to the new user

> ⚠️ **Warning:** The installer will **destroy all data** on the selected disk. Double-check your target device before confirming.

---

## ⚙️ Key Design Decisions

### Security
- **AppArmor** enabled via kernel cmdline: `lsm=landlock,lockdown,yama,integrity,apparmor,bpf`
- **ufw** pre-configured: deny all incoming, allow outgoing + SSH
- **firejail** available for sandboxed application launches
- **auditd** enabled for kernel audit logging

### Performance
- **zram** — half of RAM compressed with `zstd`, priority 100
- **zswap** — `zstd` compressor + `z3fold` pool (better than lzo/zbud on modern hardware), capped at 20% of RAM
- **IO Scheduler** — `none` for NVMe · `mq-deadline` for SSD · `bfq` for HDD (via udev rules)
- **BBR TCP** congestion control + `cake` qdisc for improved network throughput
- **preload** + **ananicy-cpp** for adaptive application pre-loading and CPU priority management
- **CPU governor** — `schedutil` by default (balance performance + efficiency)

### Desktop
- **SDDM** configured for Wayland-native session (`DisplayServer=wayland`)
- All Wayland environment variables set globally in `/etc/skel/.bash_profile`
- **Kvantum BlurDark** theme applied to both KDE and GTK apps for visual consistency
- **Papirus** icon theme, **JetBrains Mono** + **Fira Code** fonts pre-installed

---

## 🛠️ Common Customisation Tasks

| Task | Where to edit |
|---|---|
| Add/remove a package | `packages.x86_64` |
| Change default dotfiles | `airootfs/etc/skel/` |
| Tune kernel parameters | `airootfs/etc/sysctl.d/99-niyasos.conf` |
| Add a systemd service at boot | `_configure_services()` in `installer/configure.sh` |
| Change the KDE default theme/config | `configs/kde/` |
| Modify GRUB menu | `grub/grub.cfg` |
| Add Flatpak apps at install | `installer/packages.sh` |

---

## 🔄 CI / CD

| Workflow | Trigger | Purpose |
|---|---|---|
| `build-iso.yml` | Push to `main` / `dev` | Build ISO in Arch container, upload artifact |
| `release.yml` | Push a `v*` tag | Create GitHub Release, attach ISO + checksums |
| `validate-packages.yml` | Push / PR | Verify every package in `packages.x86_64` exists in repos |

---

## 📦 Package Highlights

<details>
<summary>Click to expand full package categories</summary>

- **Base**: `base` · `base-devel` · `linux-lts` · `linux-firmware`
- **Bootloader**: `grub` · `efibootmgr` · `os-prober`
- **Desktop**: `plasma-meta` · `kde-applications-meta` · `sddm` · `kvantum` · `papirus-icon-theme`
- **Audio**: `pipewire` · `wireplumber` · `pavucontrol` · `easyeffects`
- **Dev**: `python` · `nodejs` · `npm` · `rust` · `gcc` · `clang` · `llvm` · `cmake` · `gdb` · `valgrind`
- **Containers**: `docker` · `docker-compose` · `podman` · `buildah` · `skopeo`
- **Virtualisation**: `qemu-full` · `libvirt` · `virt-manager`
- **CLI Tools**: `bat` · `eza` · `fd` · `ripgrep` · `fzf` · `zoxide` · `btop` · `htop` · `hyperfine`
- **Security**: `apparmor` · `audit` · `firejail` · `ufw` · `gnupg` · `pass`
- **Fonts**: `ttf-jetbrains-mono` · `ttf-fira-code` · `ttf-roboto` · `noto-fonts` · `noto-fonts-emoji`
- **Performance**: `zram-generator` · `irqbalance` · `thermald` · `power-profiles-daemon` · `cpupower`

</details>

---

## 🤝 Contributing

Contributions are welcome! To get started:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-change`
3. Commit your changes: `git commit -m "feat: add my change"`
4. Push to your fork: `git push origin feature/my-change`
5. Open a Pull Request against `main`

Please keep pull requests focused — one logical change per PR. The CI will automatically validate your package list and attempt to build the ISO.

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<p align="center">
  Built with ❤️ on Arch Linux · Powered by <a href="https://wiki.archlinux.org/title/Archiso">archiso</a>
</p>
]]>
