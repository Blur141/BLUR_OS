#!/usr/bin/env bash
# archiso profile definition for BLUR OS

iso_name="blur"
iso_label="BLUR_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="BLUR OS <https://github.com/blur-os>"
iso_application="BLUR — Arch-based Linux Distribution"
iso_version="1.0.0"
install_dir="arch"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'uefi-x64.grub.esp')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '19' '-b' '1M')
bootstrap_tarball_compression=('zstd' '-c' '-T0' '--auto-threads=logical' '--long' '-19')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/usr/local/bin/blur-install"]="0:0:755"
  ["/usr/local/bin/blur-welcome"]="0:0:755"
)
