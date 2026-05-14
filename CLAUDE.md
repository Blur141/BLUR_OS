# NiyasOS — Project Context for Claude

## What this is
A custom Arch Linux-based OS distribution. The project builds a bootable ISO using `archiso`, containing a KDE Plasma / Wayland desktop with a full developer toolchain and security-hardened defaults.

## Stack
| Component | Choice |
|-----------|--------|
| Base | Arch Linux |
| Kernel | linux-lts |
| Bootloader | GRUB (UEFI) |
| Init | systemd |
| Package Manager | Pacman + AUR (yay) + Flatpak |
| File System | XFS |
| Desktop | KDE Plasma (Wayland) |
| Display Manager | SDDM |
| Security | AppArmor + audit + ufw + firejail |
| Shell | Bash |
| Editors | VS Code (AUR) + Neovim |
| Dev Tools | Python, Node.js, Rust, GCC, Git, GitLab Runner, Docker, Podman |
| Performance | zram + zswap (zstd) + preload (AUR) + IO scheduler udev rules |
| App Support | Flatpak (Flathub) |

## Project Layout
```
OS/
├── profiledef.sh          # archiso profile
├── packages.x86_64        # package list for live ISO
├── airootfs/              # overlay onto the live system root
│   ├── etc/
│   │   ├── pacman.conf
│   │   ├── mkinitcpio.conf
│   │   ├── sysctl.d/99-niyasos.conf   # kernel tuning
│   │   ├── udev/rules.d/60-ioscheduler.rules
│   │   ├── modprobe.d/zswap.conf
│   │   ├── systemd/zram-generator.conf
│   │   ├── apparmor.d/
│   │   ├── security/limits.conf
│   │   └── skel/          # default user dotfiles
│   └── usr/local/bin/niyasos-install
├── installer/
│   ├── install.sh         # main orchestrator (run on live boot)
│   ├── partitions.sh      # GPT: EFI + swap + XFS root
│   ├── packages.sh        # pacstrap + AUR + Flatpak
│   └── configure.sh       # locale, users, services, AppArmor, perf
├── grub/grub.cfg
├── efiboot/loader/
├── configs/
│   └── performance/
└── scripts/
    ├── build-iso.sh       # builds the ISO on an Arch host
    └── test-in-qemu.sh    # boots ISO in QEMU/OVMF for testing
```

## Build Instructions
Run these on an Arch Linux host:
```bash
sudo pacman -S archiso
sudo bash scripts/build-iso.sh
# ISO output: out/niyasos-*.iso
```

## Testing
```bash
bash scripts/test-in-qemu.sh
```

## Key Design Decisions
- AppArmor enabled via kernel cmdline: `lsm=landlock,lockdown,yama,integrity,apparmor,bpf`
- zswap uses zstd + z3fold (better than lzo + zbud on modern hardware)
- IO scheduler: `none` for NVMe, `mq-deadline` for SSD, `bfq` for HDD
- SDDM configured for Wayland-native session (not X11 fallback)
- All Wayland env vars set in `/etc/skel/.bash_profile`
- BBR TCP congestion control + cake qdisc for better network throughput

## Common Tasks
- Add a package: edit `packages.x86_64`
- Change default dotfiles: edit `airootfs/etc/skel/`
- Tune kernel params: edit `airootfs/etc/sysctl.d/99-niyasos.conf`
- Add a systemd service at boot: add to `_configure_services()` in `installer/configure.sh`
