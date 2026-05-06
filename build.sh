#!/bin/bash
# ============================================================
#  GaBuntu — Ubuntu-based Gaming Linux ISO Builder
#  Based on: Ubuntu 24.04 LTS (Noble Numbat)
#  Desktop:  KDE Plasma 6
#  GPUs:     NVIDIA + AMD + Intel (all included)
#
#  Requirements:
#    - Ubuntu 22.04 or 24.04 host (x86_64)
#    - ~20 GB free disk space
#    - Internet connection
#    - Run as root (or with sudo)
#
#  Usage:
#    sudo bash build.sh
# ============================================================

set -euo pipefail

# ── Colors ──────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Configuration ────────────────────────────────────────────
DISTRO_NAME="GaBuntu"
UBUNTU_CODENAME="noble"          # Ubuntu 24.04
ARCH="amd64"
BUILD_DIR="$(pwd)/build"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_ISO="${SCRIPT_DIR}/${DISTRO_NAME,,}-$(date +%Y%m%d)-${ARCH}.iso"

# ── Banner ───────────────────────────────────────────────────
echo -e "${BOLD}"
cat << 'BANNER'
  ██████╗  █████╗ ███╗   ███╗███████╗██████╗ ██╗   ██╗███╗   ██╗████████╗██╗   ██╗
 ██╔════╝ ██╔══██╗████╗ ████║██╔════╝██╔══██╗██║   ██║████╗  ██║╚══██╔══╝██║   ██║
 ██║  ███╗███████║██╔████╔██║█████╗  ██████╔╝██║   ██║██╔██╗ ██║   ██║   ██║   ██║
 ██║   ██║██╔══██║██║╚██╔╝██║██╔══╝  ██╔══██╗██║   ██║██║╚██╗██║   ██║   ██║   ██║
 ╚██████╔╝██║  ██║██║ ╚═╝ ██║███████╗██████╔╝╚██████╔╝██║ ╚████║   ██║   ╚██████╔╝
  ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝╚══════╝╚═════╝  ╚═════╝ ╚═╝  ╚═══╝   ╚═╝    ╚═════╝
BANNER
echo -e "${NC}"
echo -e "  ${BOLD}Ubuntu-based Gaming OS  |  KDE Plasma  |  NVIDIA + AMD + Intel${NC}"
echo ""

# ── Preflight checks ─────────────────────────────────────────
info "Running preflight checks..."

[[ "$(id -u)" -eq 0 ]] || error "This script must be run as root. Use: sudo bash build.sh"

# OS check
. /etc/os-release
if [[ "$ID" != "ubuntu" && "$ID_LIKE" != *"ubuntu"* ]]; then
    warn "This script is designed for Ubuntu hosts. Proceeding anyway..."
fi

# Disk space check (need at least 20 GB free)
AVAIL_KB=$(df --output=avail "$(pwd)" | tail -1)
AVAIL_GB=$((AVAIL_KB / 1024 / 1024))
if [[ "$AVAIL_GB" -lt 20 ]]; then
    error "Not enough disk space. Need 20 GB free, only ${AVAIL_GB} GB available."
fi
success "Disk space: ${AVAIL_GB} GB available"

# Internet check
if ! curl -fsSL --max-time 5 https://archive.ubuntu.com > /dev/null 2>&1; then
    error "No internet access. Ubuntu archive must be reachable."
fi
success "Internet connection OK"

# ── Install build dependencies ───────────────────────────────
info "Installing build tools (live-build, debootstrap, xorriso)..."
apt-get update -qq
apt-get install -y --no-install-recommends \
    live-build \
    debootstrap \
    xorriso \
    squashfs-tools \
    isolinux \
    syslinux-common \
    grub-efi-amd64-bin \
    grub-pc-bin \
    mtools \
    curl \
    wget \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    git
success "Build tools installed"

# ── Prepare build directory ──────────────────────────────────
info "Preparing build directory: ${BUILD_DIR}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Copy config from this repo into the build dir
cp -r "${SCRIPT_DIR}/config" "${BUILD_DIR}/"

# Make all hook scripts executable
chmod +x "${BUILD_DIR}"/config/hooks/live/*.hook.chroot 2>/dev/null || true
chmod +x "${BUILD_DIR}"/config/hooks/normal/*.hook.chroot 2>/dev/null || true

cd "${BUILD_DIR}"

# ── live-build configuration ─────────────────────────────────
info "Configuring live-build for ${DISTRO_NAME}..."

lb config \
    --mode ubuntu \
    --system live \
    --distribution "${UBUNTU_CODENAME}" \
    --architectures "${ARCH}" \
    --archive-areas "main restricted universe multiverse" \
    --apt-recommends false \
    --apt-options "--yes --no-install-recommends" \
    --binary-images iso-hybrid \
    --bootloaders "grub-efi,syslinux" \
    --uefi-secure-boot disable \
    --memtest none \
    --win32-loader false \
    --image-name "${DISTRO_NAME,,}" \
    --iso-volume "${DISTRO_NAME}" \
    --iso-publisher "${DISTRO_NAME} Project" \
    --iso-application "${DISTRO_NAME} Gaming Linux" \
    --debian-installer none \
    --linux-flavours generic \
    --bootappend-live "boot=live components quiet splash username=gamer hostname=gabuntu" \
    --mirror-bootstrap "http://archive.ubuntu.com/ubuntu/" \
    --mirror-chroot "http://archive.ubuntu.com/ubuntu/" \
    --mirror-binary "http://archive.ubuntu.com/ubuntu/" \
    --mirror-chroot-security "http://security.ubuntu.com/ubuntu/" \
    --mirror-binary-security "http://security.ubuntu.com/ubuntu/"

success "live-build configured"

# ── Custom GRUB bootloader menu ──────────────────────────────
info "Writing custom GRUB boot menu..."

mkdir -p "${BUILD_DIR}/config/bootloaders/grub-pc"
cat > "${BUILD_DIR}/config/bootloaders/grub-pc/grub.cfg" << 'GRUB'
set default=0
set timeout=10

if loadfont /boot/grub/unicode.pf2 ; then
    set gfxmode=auto
    insmod all_video
    insmod gfxterm
    terminal_output gfxterm
fi

set menu_color_normal=white/black
set menu_color_highlight=cyan/black

menuentry "GaBuntu — Start Gaming" --class gabuntu --class gnu-linux --class gnu --class os {
    linux   /live/vmlinuz boot=live components quiet splash username=gamer hostname=gabuntu nvidia-drm.modeset=1 amd_iommu=on iommu=pt
    initrd  /live/initrd
}

menuentry "GaBuntu — Safe Graphics Mode" --class gabuntu {
    linux   /live/vmlinuz boot=live components nomodeset quiet splash username=gamer hostname=gabuntu
    initrd  /live/initrd
}

menuentry "GaBuntu — Debug (no splash)" --class gabuntu {
    linux   /live/vmlinuz boot=live components username=gamer hostname=gabuntu
    initrd  /live/initrd
}

menuentry "Check this medium for defects" {
    linux   /live/vmlinuz boot=live components integrity-check quiet splash username=gamer hostname=gabuntu
    initrd  /live/initrd
}

menuentry "Reboot" --class restart {
    reboot
}
GRUB

success "GRUB menu written"

# ── Build! ───────────────────────────────────────────────────
info "Starting lb build — this will take 30-90 minutes depending on your connection..."
info "Coffee time ☕"
echo ""

START_TIME=$(date +%s)

lb build 2>&1 | tee "${BUILD_DIR}/build.log"

END_TIME=$(date +%s)
BUILD_SECONDS=$((END_TIME - START_TIME))
BUILD_MINUTES=$((BUILD_SECONDS / 60))

# ── Locate and move ISO ──────────────────────────────────────
ISO_FILE=$(find "${BUILD_DIR}" -maxdepth 1 -name "*.iso" | head -1)

if [[ -z "$ISO_FILE" ]]; then
    error "Build failed — no ISO found. Check ${BUILD_DIR}/build.log for details."
fi

mv "${ISO_FILE}" "${OUTPUT_ISO}"
ISO_SIZE=$(du -sh "${OUTPUT_ISO}" | cut -f1)

# ── Generate SHA256 checksum ─────────────────────────────────
info "Generating SHA256 checksum..."
sha256sum "${OUTPUT_ISO}" > "${OUTPUT_ISO}.sha256"

# ── Done ─────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║           BUILD SUCCESSFUL!  🎮                      ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BOLD}ISO:${NC}       ${OUTPUT_ISO}"
echo -e "  ${BOLD}Size:${NC}      ${ISO_SIZE}"
echo -e "  ${BOLD}Checksum:${NC}  ${OUTPUT_ISO}.sha256"
echo -e "  ${BOLD}Build time:${NC} ${BUILD_MINUTES} minutes"
echo ""
echo -e "  ${BOLD}Next steps:${NC}"
echo -e "    Flash to USB:  ${CYAN}sudo dd if='${OUTPUT_ISO}' of=/dev/sdX bs=4M status=progress conv=fsync${NC}"
echo -e "    Or use:        ${CYAN}balenaEtcher / Ventoy / Rufus${NC}"
echo ""
echo -e "  ${BOLD}Included features:${NC}"
echo -e "    🎮 Steam + Lutris + Heroic Games Launcher"
echo -e "    🍷 Wine + Winetricks + GE-Proton"
echo -e "    🖥️  NVIDIA 535 + AMD Mesa + Intel VA-API drivers"
echo -e "    ⚡ GameMode + MangoHud + MangoHud Overlay"
echo -e "    🎵 PipeWire low-latency audio (~2.7ms)"
echo -e "    🕹️  Controller support: PS3/4/5, Xbox, Switch Pro, 8BitDo"
echo -e "    🔧 vm.max_map_count=2147483642, optimized sysctl"
echo -e "    📦 Flatpak + Flathub pre-configured"
echo -e "    🎨 KDE Plasma Dark + gaming performance profile"
echo ""
