# GaBuntu 🎮

**An Ubuntu 24.04 LTS based gaming Linux distribution — like Bazzite, but Ubuntu-based.**

KDE Plasma · Steam · Lutris · GE-Proton · MangoHud · GameMode · PipeWire · NVIDIA + AMD + Intel

---

## Quick Start

```bash
# On an Ubuntu 22.04 or 24.04 host with 20+ GB free:
git clone https://github.com/your-org/gabuntu
cd gabuntu
sudo bash build.sh
```

The ISO will appear in the project root as `gabuntu-YYYYMMDD-amd64.iso`.

---

## What's Included

### Gaming Software
| Tool | Purpose |
|------|---------|
| Steam | PC gaming platform |
| Lutris | Universal game launcher (GOG, Epic, etc.) |
| Heroic Games Launcher | Epic + GOG native launcher |
| Wine + Winetricks | Run Windows games |
| GE-Proton | Community Proton with extra game patches |
| ProtonUp-Qt | Manage Proton/Wine versions easily |
| GameMode | CPU/GPU boost when games run |
| MangoHud | In-game FPS + GPU/CPU overlay |
| vkBasalt | Vulkan post-processing (sharpening, etc.) |
| RetroArch | Retro game emulation |
| ScummVM / DOSBox | Classic game support |
| Discord | Gaming chat |

### GPU Drivers
| GPU | Driver |
|-----|--------|
| NVIDIA (GTX 900+) | nvidia-driver-535 (proprietary) |
| AMD | Mesa AMDGPU (open source, best perf) |
| Intel | intel-media-va-driver + i965 |
| All | Vulkan + OpenCL support |

### Audio
- **PipeWire** replaces PulseAudio — ~2.7ms latency at 48kHz/128 samples
- JACK support for pro-audio users
- WirePlumber session manager

### Controller Support
- PlayStation 3 / 4 / 5 (DualShock + DualSense)
- Xbox 360 / One / Series X|S
- Nintendo Switch Pro Controller
- 8BitDo controllers
- Logitech gamepads
- Generic USB/Bluetooth HID gamepads

### Performance Tweaks
```
vm.max_map_count = 2147483642   # Required by many modern games
vm.swappiness = 10              # Prefer RAM over swap
fs.file-max = 524288            # Many open files for large games
kernel.sched_autogroup_enabled = 0  # Reduce stuttering
CPU governor = performance      # Max clock speeds
GameMode = enabled globally     # Auto-activates for game processes
```

### Desktop
- KDE Plasma (dark Breeze theme)
- SDDM login manager
- Compositor set to OpenGL with "block when game is fullscreen" for 0-overhead gaming
- Flatpak + Flathub pre-configured

---

## Build Requirements

| Requirement | Minimum |
|-------------|---------|
| Host OS | Ubuntu 22.04 or 24.04 (x86_64) |
| Free disk space | 20 GB |
| RAM | 4 GB (8 GB recommended) |
| Internet | Required (downloads ~4-6 GB) |
| Time | 30–90 min depending on connection |

---

## Project Structure

```
gabuntu/
├── build.sh                          # Main build script — run this
├── README.md                         # This file
└── config/
    ├── package-lists/
    │   ├── 01-desktop.list.chroot    # KDE Plasma packages
    │   ├── 02-gaming.list.chroot     # Steam, Lutris, Wine, etc.
    │   ├── 03-drivers.list.chroot    # NVIDIA, AMD, Intel drivers
    │   └── 04-system.list.chroot     # Base system, firmware
    └── hooks/
        └── live/
            ├── 0010-add-repos.hook.chroot       # Add PPAs & download .debs
            ├── 0020-install-extras.hook.chroot  # NVIDIA driver, Heroic, Discord
            ├── 0030-gaming-tweaks.hook.chroot   # sysctl, limits, CPU governor
            ├── 0040-udev-controllers.hook.chroot # Controller udev rules
            ├── 0050-pipewire-audio.hook.chroot  # Low-latency PipeWire
            ├── 0060-kde-gaming-profile.hook.chroot # KDE dark theme + perf
            ├── 0070-proton-ge.hook.chroot       # GE-Proton installation
            ├── 0080-branding.hook.chroot        # OS name, hostname, neofetch
            └── 0090-cleanup.hook.chroot         # Remove cache, reduce ISO size
```

---

## Customizing

### Add/remove packages
Edit the `.list.chroot` files in `config/package-lists/`. Each line is a package name.
Lines starting with `#` are comments.

### Change NVIDIA driver version
In `0020-install-extras.hook.chroot`, change `nvidia-driver-535` to your preferred version (e.g. `nvidia-driver-550`).

### Change GE-Proton version
In `0070-proton-ge.hook.chroot`, update `PROTON_GE_VERSION`.

### Add your own hook
Create a `.hook.chroot` file in `config/hooks/live/`. Name it with a number prefix to control execution order. Make it executable (`chmod +x`).

### Custom wallpaper
Place a file at `config/includes.chroot/usr/share/wallpapers/GaBuntu/gabuntu.png`.
Update the KDE hook to reference it.

---

## Flashing to USB

```bash
# Find your USB drive
lsblk

# Flash (replace /dev/sdX with your USB device — DOUBLE CHECK THIS!)
sudo dd if=gabuntu-20240101-amd64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

Or use **balenaEtcher**, **Ventoy**, or **Rufus** (Windows).

---

## FAQ

**Q: Why Ubuntu and not Fedora like Bazzite?**
Ubuntu has broader hardware compatibility, larger package repos, and more community resources for gaming (Steam officially supports Ubuntu).

**Q: Will NVIDIA drivers work out of the box?**
Yes — nvidia-driver-535 is installed during build and supports all GTX 900 series and newer cards. Older cards may need an older driver version.

**Q: How do I install Windows games?**
Use Steam (with Proton enabled), Lutris, or Heroic Games Launcher for Epic/GOG games. For everything else, use Wine + Winetricks.

**Q: Can I use this as a daily driver (installed to disk)?**
Yes! Boot the live ISO, then use the "Install GaBuntu" option in the app menu (Ubiquity installer). All tweaks are baked in.

**Q: How do I update GE-Proton after install?**
Open ProtonUp-Qt from the app menu or run it via Flathub.

---

## Credits

Inspired by [Bazzite](https://bazzite.gg/) (Fedora-based), built on Ubuntu 24.04 LTS.
Packaging tools: [live-build](https://live-team.pages.debian.net/live-manual/).
