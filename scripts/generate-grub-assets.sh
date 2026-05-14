#!/usr/bin/env bash
# BLUR OS — generate-grub-assets.sh
# Generates GRUB .pf2 fonts and placeholder PNG assets.
# Run on an Arch Linux host before building the ISO.
# Requires: grub, imagemagick, python-pillow (optional)

set -euo pipefail

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/airootfs/usr/share/grub/themes/blur"
FONT_REGULAR="${FONT_REGULAR:-/usr/share/fonts/noto/NotoSans-Regular.ttf}"
FONT_BOLD="${FONT_BOLD:-/usr/share/fonts/noto/NotoSans-Bold.ttf}"

command -v grub-mkfont &>/dev/null || { echo "grub not installed"; exit 1; }
command -v convert    &>/dev/null || { echo "imagemagick not installed: pacman -S imagemagick"; exit 1; }

mkdir -p "${THEME_DIR}/fonts" "${THEME_DIR}/icons"

# ── Fonts ──────────────────────────────────────────────────
echo "[*] Generating GRUB fonts..."
grub-mkfont -s 36 -o "${THEME_DIR}/fonts/blur_bold_36.pf2"    "$FONT_BOLD"
grub-mkfont -s 14 -o "${THEME_DIR}/fonts/blur_bold_14.pf2"    "$FONT_BOLD"
grub-mkfont -s 14 -o "${THEME_DIR}/fonts/blur_regular_14.pf2" "$FONT_REGULAR"
grub-mkfont -s 13 -o "${THEME_DIR}/fonts/blur_regular_13.pf2" "$FONT_REGULAR"
grub-mkfont -s 11 -o "${THEME_DIR}/fonts/blur_regular_11.pf2" "$FONT_REGULAR"
grub-mkfont -s  1 -o "${THEME_DIR}/fonts/blur_regular_1.pf2"  "$FONT_REGULAR"
echo "[OK] Fonts written to ${THEME_DIR}/fonts/"

# ── Background ────────────────────────────────────────────
echo "[*] Generating placeholder background..."
if [[ -f "${THEME_DIR}/background.png" ]]; then
    echo "  background.png exists — skipping"
else
    convert -size 1920x1080 \
        -define gradient:angle=135 \
        gradient:"#1e1e2e"-"#181825" \
        -fill "#7f5af0" -draw "rectangle 0,1079 1920,1080" \
        "${THEME_DIR}/background.png"
    echo "  Generated gradient background. Replace with final wallpaper."
fi

# ── Selected item highlight ───────────────────────────────
echo "[*] Generating selection box assets..."
_make_9slice() {
    local name="$1" color="$2" border_color="$3" w=460 h=48 r=6
    for variant in c n s e w ne nw se sw; do
        case "$variant" in
          c)  coords="6,6 $((w-6)),$((h-6))"; region="${w}x${h}+0+0" ;;
          n)  coords="0,0 ${w},6";             region="${w}x6+0+0" ;;
          s)  coords="0,$((h-6)) ${w},${h}";   region="${w}x6+0+$((h-6))" ;;
          w)  coords="0,0 6,${h}";             region="6x${h}+0+0" ;;
          e)  coords="$((w-6)),0 ${w},${h}";   region="6x${h}+$((w-6))+0" ;;
          nw) coords="0,0 6,6";                region="6x6+0+0" ;;
          ne) coords="$((w-6)),0 ${w},6";      region="6x6+$((w-6))+0" ;;
          sw) coords="0,$((h-6)) 6,${h}";      region="6x6+0+$((h-6))" ;;
          se) coords="$((w-6)),$((h-6)) ${w},${h}"; region="6x6+$((w-6))+$((h-6))" ;;
        esac
        convert -size "${w}x${h}" xc:"$color" \
            -fill none -stroke "$border_color" -strokewidth 2 \
            -draw "roundrectangle 1,1,$((w-2)),$((h-2)),$r,$r" \
            -region "$region" -flatten \
            "${THEME_DIR}/${name}_${variant}.png" 2>/dev/null
    done
}
_make_9slice "select" "#313244" "#7f5af0"
echo "[OK] Selection box assets generated"

# ── Separator ────────────────────────────────────────────
echo "[*] Generating separator..."
convert -size 440x1 xc:"#313244" "${THEME_DIR}/separator.png"

# ── Progress bar ─────────────────────────────────────────
echo "[*] Generating progress bar assets..."
for v in c n s e w ne nw se sw; do
    convert -size 460x3 xc:"#7f5af0" "${THEME_DIR}/progress_bar_${v}.png" 2>/dev/null
done

echo ""
echo "[OK] GRUB theme assets ready in:"
echo "     ${THEME_DIR}"
echo ""
echo "  To install into a running system:"
echo "    sudo cp -r ${THEME_DIR} /boot/grub/themes/blur"
echo "    sudo grub-mkconfig -o /boot/grub/grub.cfg"
