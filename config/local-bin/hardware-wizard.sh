#!/usr/bin/env bash
# ==============================================================================
# StxSaryus — Universal CPU & GPU Driver Detection & Optimization Wizard
#
# Automatically detects CPU architecture, GPU hardware, and display topology.
# Recommends and installs optimal driver packages (Intel, AMD, NVIDIA Turing+,
# NVIDIA Pascal 580xx, VMs) and generates dynamic Hyprland environment settings.
#
# Usage:
#   hardware-wizard.sh             # Interactive wizard (diagnoses & prompts)
#   hardware-wizard.sh --check     # Status-only report (useful for updates & CI)
#   hardware-wizard.sh --auto      # Non-interactive auto-install of missing drivers
#   hardware-wizard.sh --env-only  # Only regenerate ~/.config/hypr/gpu-env.conf
#   hardware-wizard.sh --help      # Show usage help
# ==============================================================================

set -euo pipefail

# ANSI Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
MAGENTA='\033[0;35m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." 2>/dev/null && pwd || echo "")"
MODE="interactive"
SUDO_KEEPALIVE_PID=""

# Hardware state variables
CPU_VENDOR=""
CPU_MODEL=""
CPU_DRIVER=""
CPU_UCODE_PKG=""

GPU_COUNT=0
HAS_INTEL_GPU=0
HAS_AMD_GPU=0
HAS_NVIDIA_GPU=0
HAS_VM_GPU=0

INTEL_GPU_NAME=""
AMD_GPU_NAME=""
NVIDIA_GPU_NAME=""
VM_GPU_NAME=""

NVIDIA_PCI_ID=""
NVIDIA_BRANCH="none"     # "580xx", "open", "470xx", or "none"
TOPOLOGY="UNKNOWN"       # HYBRID_INTEL_NVIDIA, HYBRID_AMD_NVIDIA, PURE_NVIDIA, PURE_AMD, PURE_INTEL, VM

MULTILIB_ENABLED=0

# Package recommendation lists
RECOMMENDED_PACMAN=()
RECOMMENDED_AUR=()
MISSING_PACMAN=()
MISSING_AUR=()
INSTALLED_PKGS=()
CONFLICTING_PKGS=()

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
section() { echo -e "\n${BOLD}${BLUE}═══ $1 ═══${NC}"; }
banner()  {
    echo -e "\n${CYAN}${BOLD}╭────────────────────────────────────────────────────────────────────╮${NC}"
    printf "${CYAN}${BOLD}│  %-66s │${NC}\n" "$1"
    echo -e "${CYAN}${BOLD}╰────────────────────────────────────────────────────────────────────╯${NC}\n"
}

usage() {
    cat <<EOF
Universal CPU & GPU Driver Detection & Optimization Wizard
Author: StxSaryus

Usage:
  hardware-wizard.sh [OPTIONS]

Options:
  (no args)       Interactive hardware scan, diagnosis, and driver setup
  --check         Check driver health, missing packages, and DKMS status (no changes)
  --auto          Non-interactive: auto-detect and install recommended drivers
  --env-only      Only generate ~/.config/hypr/gpu-env.conf based on detected hardware
  --check-missing Output missing package names (used by Sentinel & automation)
  --check-updates Check if upstream driver/kernel packages have pending updates
  --check-status  Output structured health & telemetry summary
  -h, --help      Display this help dialog

Supported Hardware:
  • CPUs: Intel (Core, Xeon, Celeron), AMD (Ryzen, Threadripper, EPYC)
  • Intel GPUs: HD / UHD / Iris Xe / Arc (Mesa + intel-media-driver + vulkan-intel)
  • AMD GPUs: Radeon RX / Vega / RDNA (Mesa + vulkan-radeon + VA-API)
  • NVIDIA GPUs:
      - Turing / Ampere / Ada / Blackwell (RTX 20xx+, GTX 16xx+): nvidia-open
      - Pascal / Maxwell (GTX 10xx, GTX 9xx, GTX 750): AUR nvidia-580xx-dkms
      - Kepler (GTX 6xx, 7xx): AUR nvidia-470xx-dkms
  • Virtual Machines: QEMU / KVM, VMware, VirtualBox
EOF
}

need_sudo() {
    if ! sudo -n true 2>/dev/null; then
        info "Elevated permissions required for driver verification/installation..."
        sudo -v || { error "sudo authentication failed"; exit 1; }
    fi
    if [[ -z "$SUDO_KEEPALIVE_PID" ]]; then
        ( while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done ) 2>/dev/null &
        SUDO_KEEPALIVE_PID=$!
        trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT
    fi
}

check_multilib() {
    if grep -qE '^\s*\[multilib\]' /etc/pacman.conf 2>/dev/null; then
        MULTILIB_ENABLED=1
    else
        MULTILIB_ENABLED=0
    fi
}

is_exact_pkg_installed() {
    pacman -Qq 2>/dev/null | grep -Fxq "$1"
}

detect_cpu() {
    local raw_vendor
    raw_vendor="$(grep -m1 'vendor_id' /proc/cpuinfo 2>/dev/null | awk '{print $3}' || echo "Unknown")"
    CPU_MODEL="$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2- | sed -e 's/^[ \t]*//' || echo "Unknown CPU")"
    CPU_DRIVER="$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null || echo "generic")"

    case "$raw_vendor" in
        GenuineIntel*)
            CPU_VENDOR="Intel"
            CPU_UCODE_PKG="intel-ucode"
            ;;
        AuthenticAMD*)
            CPU_VENDOR="AMD"
            CPU_UCODE_PKG="amd-ucode"
            ;;
        *)
            CPU_VENDOR="Other ($raw_vendor)"
            CPU_UCODE_PKG=""
            ;;
    esac

    if [[ -n "$CPU_UCODE_PKG" ]]; then
        RECOMMENDED_PACMAN+=("$CPU_UCODE_PKG")
    fi
}

detect_gpus() {
    GPU_COUNT=0
    local pci_devices
    pci_devices="$(lspci -nn 2>/dev/null | grep -iE 'vga compatible controller|3d controller|display controller' || true)"

    if [[ -z "$pci_devices" ]]; then
        warn "No PCI display controllers detected via lspci"
        return
    fi

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        GPU_COUNT=$((GPU_COUNT + 1))

        local pci_id vendor device
        pci_id="$(echo "$line" | grep -oE '\[[0-9a-fA-F]{4}:[0-9a-fA-F]{4}\]' | tr -d '[]' | head -1 || true)"
        vendor="$(echo "$pci_id" | cut -d: -f1 | tr '[:upper:]' '[:lower:]')"
        device="$(echo "$pci_id" | cut -d: -f2 | tr '[:upper:]' '[:lower:]')"

        case "$vendor" in
            8086) # Intel
                HAS_INTEL_GPU=1
                INTEL_GPU_NAME="$(echo "$line" | sed -E 's/^.*\[03[0-9a-fA-F]{2}\]: //; s/ \[8086:.*$//')"
                ;;
            1002) # AMD
                HAS_AMD_GPU=1
                AMD_GPU_NAME="$(echo "$line" | sed -E 's/^.*\[03[0-9a-fA-F]{2}\]: //; s/ \[1002:.*$//')"
                ;;
            10de) # NVIDIA
                HAS_NVIDIA_GPU=1
                NVIDIA_GPU_NAME="$(echo "$line" | sed -E 's/^.*\[03[0-9a-fA-F]{2}\]: //; s/ \[10de:.*$//')"
                NVIDIA_PCI_ID="$device"
                classify_nvidia_branch "$device"
                ;;
            1af4|15ad|80ee|1234) # VM (VirtIO, VMware, VirtualBox, QEMU)
                HAS_VM_GPU=1
                VM_GPU_NAME="$(echo "$line" | sed -E 's/^.*\[03[0-9a-fA-F]{2}\]: //; s/ \[[0-9a-fA-F]{4}:.*$//')"
                ;;
        esac
    done <<< "$pci_devices"

    determine_topology
}

classify_nvidia_branch() {
    local dev="$1"
    # Pascal: 1bxx, 1cxx, 1d80-1d82
    # Maxwell: 13xx, 14xx, 17xx, 12xx
    # Kepler: 0fxx, 10xx, 11xx
    case "${dev,,}" in
        1c*|1b*|1d80|1d81|1d82|14*|13*|17*|12*|11*|0f*|0e*|0c*|0a*|019*)
            # Pascal, Maxwell, or older
            if [[ "${dev,,}" =~ ^(0f|10|11) ]]; then
                NVIDIA_BRANCH="470xx"
            else
                NVIDIA_BRANCH="580xx"
            fi
            ;;
        *)
            # Turing, Ampere, Ada Lovelace, Blackwell (RTX 20xx+, GTX 16xx+, RTX 30xx+, 40xx+, 50xx+)
            if journalctl -b -k --no-pager 2>/dev/null | grep -q "not supported by open"; then
                NVIDIA_BRANCH="580xx"
            else
                NVIDIA_BRANCH="open"
            fi
            ;;
    esac
}

determine_topology() {
    if [[ "$HAS_VM_GPU" -eq 1 && "$GPU_COUNT" -eq 1 ]]; then
        TOPOLOGY="VM"
    elif [[ "$HAS_INTEL_GPU" -eq 1 && "$HAS_NVIDIA_GPU" -eq 1 ]]; then
        TOPOLOGY="HYBRID_INTEL_NVIDIA"
    elif [[ "$HAS_AMD_GPU" -eq 1 && "$HAS_NVIDIA_GPU" -eq 1 ]]; then
        TOPOLOGY="HYBRID_AMD_NVIDIA"
    elif [[ "$HAS_AMD_GPU" -eq 1 && "$GPU_COUNT" -gt 1 ]]; then
        TOPOLOGY="HYBRID_AMD_AMD"
    elif [[ "$HAS_INTEL_GPU" -eq 1 && "$GPU_COUNT" -gt 1 ]]; then
        TOPOLOGY="HYBRID_INTEL_INTEL"
    elif [[ "$HAS_NVIDIA_GPU" -eq 1 ]]; then
        TOPOLOGY="PURE_NVIDIA"
    elif [[ "$HAS_AMD_GPU" -eq 1 ]]; then
        TOPOLOGY="PURE_AMD"
    elif [[ "$HAS_INTEL_GPU" -eq 1 ]]; then
        TOPOLOGY="PURE_INTEL"
    else
        TOPOLOGY="UNKNOWN"
    fi
}

assemble_recommendations() {
    RECOMMENDED_PACMAN+=("mesa")

    # Intel Acceleration
    if [[ "$HAS_INTEL_GPU" -eq 1 ]]; then
        RECOMMENDED_PACMAN+=("vulkan-intel" "intel-media-driver")
        if [[ "$MULTILIB_ENABLED" -eq 1 ]]; then
            RECOMMENDED_PACMAN+=("lib32-vulkan-intel" "lib32-mesa")
        fi
    fi

    # AMD Acceleration
    if [[ "$HAS_AMD_GPU" -eq 1 ]]; then
        RECOMMENDED_PACMAN+=("vulkan-radeon" "libva-mesa-driver" "mesa-vdpau")
        if [[ "$MULTILIB_ENABLED" -eq 1 ]]; then
            RECOMMENDED_PACMAN+=("lib32-vulkan-radeon" "lib32-mesa")
        fi
    fi

    # NVIDIA Drivers & Acceleration
    if [[ "$HAS_NVIDIA_GPU" -eq 1 ]]; then
        RECOMMENDED_PACMAN+=("linux-headers" "dkms" "libva-nvidia-driver")

        case "$NVIDIA_BRANCH" in
            580xx)
                RECOMMENDED_AUR+=("nvidia-580xx-dkms" "nvidia-580xx-utils")
                if [[ "$MULTILIB_ENABLED" -eq 1 ]]; then
                    RECOMMENDED_AUR+=("lib32-nvidia-580xx-utils")
                fi
                # Conflict checks
                if is_exact_pkg_installed nvidia-open; then CONFLICTING_PKGS+=("nvidia-open"); fi
                if is_exact_pkg_installed nvidia-open-dkms; then CONFLICTING_PKGS+=("nvidia-open-dkms"); fi
                if is_exact_pkg_installed nvidia; then CONFLICTING_PKGS+=("nvidia"); fi
                if is_exact_pkg_installed nvidia-utils && ! is_exact_pkg_installed nvidia-580xx-utils; then
                    CONFLICTING_PKGS+=("nvidia-utils")
                fi
                ;;
            open)
                RECOMMENDED_PACMAN+=("nvidia-open" "nvidia-utils")
                if [[ "$MULTILIB_ENABLED" -eq 1 ]]; then
                    RECOMMENDED_PACMAN+=("lib32-nvidia-utils")
                fi
                if is_exact_pkg_installed nvidia-580xx-dkms; then CONFLICTING_PKGS+=("nvidia-580xx-dkms"); fi
                if is_exact_pkg_installed nvidia-580xx-utils; then CONFLICTING_PKGS+=("nvidia-580xx-utils"); fi
                ;;
            470xx)
                RECOMMENDED_AUR+=("nvidia-470xx-dkms" "nvidia-470xx-utils")
                if [[ "$MULTILIB_ENABLED" -eq 1 ]]; then
                    RECOMMENDED_AUR+=("lib32-nvidia-470xx-utils")
                fi
                ;;
        esac

        if [[ "$TOPOLOGY" =~ ^HYBRID_ ]]; then
            # Offloading utilities
            RECOMMENDED_PACMAN+=("nvidia-prime")
        fi
    fi

    # Deduplicate arrays
    read -ra RECOMMENDED_PACMAN <<< "$(printf '%s\n' "${RECOMMENDED_PACMAN[@]}" | sort -u | tr '\n' ' ')"
    if [[ "${#RECOMMENDED_AUR[@]}" -gt 0 ]]; then
        read -ra RECOMMENDED_AUR <<< "$(printf '%s\n' "${RECOMMENDED_AUR[@]}" | sort -u | tr '\n' ' ')"
    fi
}

audit_installed_packages() {
    MISSING_PACMAN=()
    MISSING_AUR=()
    INSTALLED_PKGS=()

    for pkg in "${RECOMMENDED_PACMAN[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            INSTALLED_PKGS+=("$pkg")
        else
            MISSING_PACMAN+=("$pkg")
        fi
    done

    for pkg in "${RECOMMENDED_AUR[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            INSTALLED_PKGS+=("$pkg")
        else
            MISSING_AUR+=("$pkg")
        fi
    done
}

print_hardware_summary() {
    banner "StxSaryus Universal Hardware & Driver Wizard"
    
    echo -e "${BOLD}Detected Architecture:${NC}"
    echo -e "  • ${BOLD}CPU:${NC}       ${CYAN}${CPU_VENDOR}${NC} — ${CPU_MODEL}"
    echo -e "    Scaling:   ${DIM}${CPU_DRIVER}${NC}"
    if [[ -n "$CPU_UCODE_PKG" ]]; then
        if pacman -Q "$CPU_UCODE_PKG" &>/dev/null; then
            echo -e "    Microcode: ${GREEN}${CPU_UCODE_PKG} (Installed)${NC}"
        else
            echo -e "    Microcode: ${YELLOW}${CPU_UCODE_PKG} (Missing)${NC}"
        fi
    fi
    echo ""

    echo -e "${BOLD}Detected GPU(s):${NC} [Count: ${GPU_COUNT}]"
    if [[ "$HAS_INTEL_GPU" -eq 1 ]]; then
        echo -e "  • ${BLUE}Intel GPU:${NC}  ${INTEL_GPU_NAME:-Integrated Graphics}"
        echo -e "    Stack:      Mesa + Intel Media Driver (iHD) + Vulkan Intel"
    fi
    if [[ "$HAS_AMD_GPU" -eq 1 ]]; then
        echo -e "  • ${RED}AMD GPU:${NC}    ${AMD_GPU_NAME:-Radeon Graphics}"
        echo -e "    Stack:      Mesa + RADV Vulkan + VA-API radeonsi"
    fi
    if [[ "$HAS_NVIDIA_GPU" -eq 1 ]]; then
        echo -e "  • ${GREEN}NVIDIA GPU:${NC} ${NVIDIA_GPU_NAME:-GeForce}"
        echo -e "    Device ID:  10de:${NVIDIA_PCI_ID}"
        case "$NVIDIA_BRANCH" in
            580xx)
                echo -e "    Branch:     ${YELLOW}Legacy 580xx branch (Pascal / Maxwell)${NC}"
                echo -e "    Notice:     Arch dropped Pascal in driver 590+; uses AUR nvidia-580xx-dkms"
                ;;
            open)
                echo -e "    Branch:     ${GREEN}Open Kernel Modules (Turing / RTX / Ampere / Ada)${NC}"
                echo -e "    Driver:     Repo nvidia-open + nvidia-utils"
                ;;
            470xx)
                echo -e "    Branch:     ${MAGENTA}Legacy 470xx branch (Kepler)${NC}"
                ;;
        esac
    fi
    if [[ "$HAS_VM_GPU" -eq 1 ]]; then
        echo -e "  • ${CYAN}Virtual GPU:${NC} ${VM_GPU_NAME:-VM Guest Display}"
    fi
    echo ""

    echo -e "${BOLD}Display Topology:${NC}"
    case "$TOPOLOGY" in
        HYBRID_INTEL_NVIDIA)
            echo -e "  ${YELLOW}⚡ Hybrid Optimus${NC} (Intel iGPU drives display, NVIDIA available for on-demand 3D offload)"
            echo -e "  Runner: ${BOLD}prime-run <command>${NC} sends workloads to NVIDIA dGPU."
            ;;
        HYBRID_AMD_NVIDIA)
            echo -e "  ${YELLOW}⚡ Hybrid Optimus${NC} (AMD iGPU drives display, NVIDIA available for on-demand 3D offload)"
            echo -e "  Runner: ${BOLD}prime-run <command>${NC} sends workloads to NVIDIA dGPU."
            ;;
        PURE_NVIDIA)
            echo -e "  ${GREEN}🚀 Pure NVIDIA Desktop${NC} (Direct DRM KMS modeset enabled via nvidia-drm)"
            ;;
        PURE_AMD)
            echo -e "  ${BLUE}💠 Pure AMD Radeon${NC} (Native open-source Wayland acceleration)"
            ;;
        PURE_INTEL)
            echo -e "  ${BLUE}💠 Pure Intel Graphics${NC} (Native open-source Wayland acceleration)"
            ;;
        VM)
            echo -e "  ${CYAN}📦 Virtual Machine Guest${NC} (Software/VirtIO acceleration)"
            ;;
        *)
            echo -e "  ${DIM}Standard display configuration${NC}"
            ;;
    esac
    echo ""
}

print_package_table() {
    section "Driver & Acceleration Package Status"
    printf "%b%-32s %-14s %-16s%b\n" "${BOLD}" "PACKAGE" "STATUS" "SOURCE" "${NC}"
    echo "──────────────────────────────────────────────────────────────────"

    for pkg in "${RECOMMENDED_PACMAN[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            local ver
            ver="$(pacman -Q "$pkg" | awk '{print $2}')"
            printf "%-32s %b%-14s%b %b%-16s%b\n" "$pkg" "${GREEN}" "Installed" "${NC}" "${DIM}" "repo ($ver)" "${NC}"
        else
            printf "%-32s %b%-14s%b %b%-16s%b\n" "$pkg" "${YELLOW}" "Missing" "${NC}" "${CYAN}" "Official Repo" "${NC}"
        fi
    done

    for pkg in "${RECOMMENDED_AUR[@]}"; do
        if pacman -Q "$pkg" &>/dev/null; then
            local ver
            ver="$(pacman -Q "$pkg" | awk '{print $2}')"
            printf "%-32s %b%-14s%b %b%-16s%b\n" "$pkg" "${GREEN}" "Installed" "${NC}" "${DIM}" "AUR ($ver)" "${NC}"
        else
            printf "%-32s %b%-14s%b %b%-16s%b\n" "$pkg" "${RED}" "Missing" "${NC}" "${MAGENTA}" "AUR" "${NC}"
        fi
    done

    if [[ "${#CONFLICTING_PKGS[@]}" -gt 0 ]]; then
        echo "──────────────────────────────────────────────────────────────────"
        warn "Conflicting packages detected:"
        for cpkg in "${CONFLICTING_PKGS[@]}"; do
            echo -e "  ${RED}✖ ${cpkg}${NC} (needs removal to prevent driver mismatch)"
        done
    fi
    echo ""
}

detect_drm_devices_env() {
    local igpu="" dgpu=""
    if compgen -G "/dev/dri/by-path/*-card" >/dev/null; then
        for dev in /dev/dri/by-path/*-card; do
            local pci_dev
            pci_dev="$(basename "$dev" | sed "s/-card$//" | sed "s/^pci-//")"
            if [[ -d "/sys/bus/pci/devices/$pci_dev" ]]; then
                local vendor
                vendor="$(cat "/sys/bus/pci/devices/$pci_dev/vendor" 2>/dev/null || echo "")"
                case "$vendor" in
                    0x8086) igpu="$dev" ;;
                    0x1002)
                        if [[ -z "$igpu" ]]; then igpu="$dev"; else dgpu="$dev"; fi ;;
                    0x10de) dgpu="$dev" ;;
                esac
            fi
        done
    fi
    if [[ -n "$igpu" && -n "$dgpu" ]]; then
        echo "$igpu:$dgpu"
    elif [[ -n "$igpu" ]]; then
        echo "$igpu"
    elif [[ -n "$dgpu" ]]; then
        echo "$dgpu"
    fi
}

generate_gpu_env() {
    local target_file="${HOME}/.config/hypr/gpu-env.conf"
    local repo_file=""
    if [[ -n "$REPO_DIR" && -d "$REPO_DIR/config/hypr" ]]; then
        repo_file="$REPO_DIR/config/hypr/gpu-env.conf"
    fi

    info "Generating dynamic Hyprland environment configuration..."
    mkdir -p "$(dirname "$target_file")"

    local tmp
    tmp="$(mktemp)"

    cat <<EOF > "$tmp"
# ==============================================================================
# StxSaryus — Dynamic Hardware & GPU Environment
# Generated by: hardware-wizard.sh
# Topology: ${TOPOLOGY}
# Generated on: $(date '+%Y-%m-%d %H:%M:%S')
# ==============================================================================

env = XDG_SESSION_TYPE,wayland
env = ELECTRON_OZONE_PLATFORM_HINT,auto
env = MOZ_ENABLE_WAYLAND,1
EOF

    case "$TOPOLOGY" in
        HYBRID_INTEL_NVIDIA)
            cat <<EOF >> "$tmp"

# Hybrid Graphics (Intel iGPU drives compositor, NVIDIA discrete GPU offloaded)
# Note: GBM_BACKEND and __GLX_VENDOR_LIBRARY_NAME are omitted globally
# to avoid Mesa abort crashes on the internal eDP-1 display.
# Run 3D games and apps on NVIDIA discrete GPU using: prime-run <app>
env = LIBVA_DRIVER_NAME,nvidia
env = NVD_BACKEND,direct

cursor {
    no_hardware_cursors = true
}
EOF
            ;;
        HYBRID_AMD_NVIDIA)
            cat <<EOF >> "$tmp"

# Hybrid Graphics (AMD iGPU drives compositor, NVIDIA discrete GPU offloaded)
# Run 3D games and apps on NVIDIA discrete GPU using: prime-run <app>
env = LIBVA_DRIVER_NAME,nvidia
env = NVD_BACKEND,direct

cursor {
    no_hardware_cursors = true
}
EOF

cursor {
    no_hardware_cursors = true
}
EOF
            ;;
        PURE_NVIDIA)
            cat <<EOF >> "$tmp"

# Pure Dedicated NVIDIA Graphics
env = LIBVA_DRIVER_NAME,nvidia
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct

cursor {
    no_hardware_cursors = true
}
EOF
            ;;
        PURE_AMD|HYBRID_AMD_AMD)
            cat <<EOF >> "$tmp"

# Pure AMD Radeon Graphics (Native Open-Source Wayland Stack)
env = LIBVA_DRIVER_NAME,radeonsi
env = VDPAU_DRIVER,radeonsi

cursor {
    no_hardware_cursors = false
}
EOF
            ;;
        PURE_INTEL|HYBRID_INTEL_INTEL)
            cat <<EOF >> "$tmp"

# Pure Intel Graphics (Native Open-Source Wayland Stack)
env = LIBVA_DRIVER_NAME,iHD

cursor {
    no_hardware_cursors = false
}
EOF
            ;;
        VM)
            cat <<EOF >> "$tmp"

# Virtual Machine Guest Environment
env = WLR_NO_HARDWARE_CURSORS,1

cursor {
    no_hardware_cursors = true
}
EOF
            ;;
        *)
            cat <<EOF >> "$tmp"

# Fallback Configuration
cursor {
    no_hardware_cursors = true
}
EOF
            ;;
    esac

    # If repo_file exists and target_file is a symlink to it, write to repo_file
    if [[ -n "$repo_file" && -L "$target_file" ]]; then
        local link_target
        link_target="$(readlink -f "$target_file")"
        if [[ "$link_target" == "$repo_file" ]]; then
            cp "$tmp" "$repo_file"
        else
            cp "$tmp" "$target_file"
        fi
    else
        if [[ -n "$repo_file" ]]; then
            cp "$tmp" "$repo_file"
        fi
        cp "$tmp" "$target_file"
    fi
    rm -f "$tmp"

    success "Updated: $target_file"
}

setup_nvidia_system_files() {
    [[ "$HAS_NVIDIA_GPU" -eq 1 ]] || return 0
    section "Configuring NVIDIA Kernel & Modprobe"
    need_sudo

    local modprobe_src="" blacklist_src="" modules_src=""
    if [[ -n "$REPO_DIR" && -d "$REPO_DIR/nvidia" ]]; then
        modprobe_src="$REPO_DIR/nvidia/modprobe-nvidia.conf"
        blacklist_src="$REPO_DIR/nvidia/blacklist-nouveau.conf"
        modules_src="$REPO_DIR/nvidia/modules-load-nvidia.conf"
    fi

    if [[ -f "$modprobe_src" ]]; then
        sudo install -Dm644 "$modprobe_src" /etc/modprobe.d/nvidia.conf
    else
        sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia-drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var/tmp
options nvidia NVreg_DynamicPowerManagement=0x02
EOF
    fi

    if [[ -f "$blacklist_src" ]]; then
        sudo install -Dm644 "$blacklist_src" /etc/modprobe.d/blacklist-nouveau.conf
    else
        sudo tee /etc/modprobe.d/blacklist-nouveau.conf >/dev/null <<'EOF'
blacklist nouveau
EOF
    fi

    if [[ -f "$modules_src" ]]; then
        sudo install -Dm644 "$modules_src" /etc/modules-load.d/nvidia.conf
    else
        sudo tee /etc/modules-load.d/nvidia.conf >/dev/null <<'EOF'
nvidia
nvidia_modeset
nvidia_uvm
nvidia_drm
EOF
    fi
    success "Modprobe & nouveau blacklist configs in place"

    # GRUB check
    if [[ -f /etc/default/grub ]] && ! grep -q 'nvidia_drm.modeset=1' /etc/default/grub; then
        info "Adding nvidia_drm.modeset=1 to GRUB cmdline..."
        sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' /etc/default/grub
        sudo grub-mkconfig -o /boot/grub/grub.cfg 2>/dev/null || true
        success "GRUB configuration updated with nvidia_drm.modeset=1"
    fi
}

install_packages() {
    if [[ "${#CONFLICTING_PKGS[@]}" -gt 0 ]]; then
        section "Resolving Package Conflicts"
        need_sudo
        for cpkg in "${CONFLICTING_PKGS[@]}"; do
            info "Removing conflicting package: $cpkg"
            sudo pacman -Rdd --noconfirm "$cpkg" 2>/dev/null || true
        done
        success "Conflicting packages removed"
    fi

    if [[ "${#MISSING_PACMAN[@]}" -gt 0 ]]; then
        section "Installing Missing Official Packages"
        need_sudo
        info "Running pacman -S --needed: ${MISSING_PACMAN[*]}"
        sudo pacman -S --needed --noconfirm "${MISSING_PACMAN[@]}"
        success "Official packages installed"
    fi

    if [[ "${#MISSING_AUR[@]}" -gt 0 ]]; then
        section "Installing Missing AUR Packages"
        if ! command -v yay >/dev/null 2>&1; then
            warn "yay AUR helper is required for: ${MISSING_AUR[*]}"
            info "Bootstrapping yay-bin..."
            need_sudo
            sudo pacman -S --needed --noconfirm base-devel git
            local tmp
            tmp="$(mktemp -d)"
            git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
            ( cd "$tmp/yay-bin" && makepkg -si --noconfirm )
            rm -rf "$tmp"
        fi
        info "Running yay -S --needed: ${MISSING_AUR[*]}"
        yay -S --needed --noconfirm "${MISSING_AUR[@]}"
        success "AUR packages installed"
    fi

    # DKMS check
    if [[ "$HAS_NVIDIA_GPU" -eq 1 ]] && command -v dkms >/dev/null; then
        section "Building DKMS Kernel Modules"
        need_sudo
        info "Rebuilding DKMS modules for kernel $(uname -r)..."
        local nver
        nver="$(dkms status 2>/dev/null | awk -F'[/,: ]+' '/^nvidia\//{print $2; exit}')"
        if [[ -n "$nver" ]]; then
            sudo dkms install "nvidia/${nver}" -k "$(uname -r)" 2>/dev/null \
                || sudo dkms autoinstall \
                || warn "DKMS build finished with warnings (reboot may be required)"
        else
            sudo dkms autoinstall || true
        fi
        dkms status 2>/dev/null || true
    fi

    setup_nvidia_system_files
    generate_gpu_env
}

run_diagnostics() {
    section "System Diagnostics & Telemetry"

    # DKMS Status
    if command -v dkms >/dev/null; then
        local dstatus
        dstatus="$(dkms status 2>/dev/null || true)"
        if [[ -n "$dstatus" ]]; then
            echo -e "${BOLD}DKMS Modules:${NC}\n$dstatus"
        fi
    fi

    # Vulkan ICDs
    echo -e "${BOLD}Vulkan ICD Loaders (/usr/share/vulkan/icd.d):${NC}"
    if compgen -G "/usr/share/vulkan/icd.d/*.json" >/dev/null; then
        for icd in /usr/share/vulkan/icd.d/*.json; do
            echo -e "  • ${GREEN}$(basename "$icd")${NC}"
        done
    else
        echo -e "  ${YELLOW}No Vulkan ICDs registered${NC}"
    fi

    # VA-API Video Acceleration
    if command -v vainfo >/dev/null 2>&1; then
        echo -e "\n${BOLD}VA-API Drivers:${NC}"
        vainfo --display drm 2>&1 | grep -iE 'va_openDriverAttribute|Driver version' | head -4 || true
    fi

    # NVIDIA-SMI
    if [[ "$HAS_NVIDIA_GPU" -eq 1 ]] && command -v nvidia-smi >/dev/null 2>&1; then
        echo -e "\n${BOLD}NVIDIA SMI Telemetry:${NC}"
        nvidia-smi --query-gpu=name,driver_version,temperature.gpu,utilization.gpu --format=csv,noheader 2>/dev/null \
            && success "NVIDIA Driver active and communicating with hardware" \
            || warn "NVIDIA driver not loaded into running kernel (Reboot required)"
    fi
}

check_upstream_driver_updates() {
    local updates=()
    if command -v checkupdates >/dev/null 2>&1; then
        while IFS= read -r u; do
            [[ -n "$u" ]] && updates+=("$u")
        done < <(checkupdates 2>/dev/null | grep -E '^linux([ -]|$)|^nvidia|^mesa|^vulkan|^intel-media-driver|^libva' || true)
    fi
    if command -v yay >/dev/null 2>&1; then
        while IFS= read -r u; do
            [[ -n "$u" ]] && updates+=("$u")
        done < <(yay -Qua 2>/dev/null | grep -E '^linux([ -]|$)|^nvidia|^mesa|^vulkan|^intel-media-driver|^libva' || true)
    fi
    if [[ "${#updates[@]}" -gt 0 ]]; then
        printf '%s\n' "${updates[@]}"
        return 0
    fi
    return 1
}

# --- Main Flow ---

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    --check)
        MODE="check"
        ;;
    --check-missing)
        MODE="check-missing"
        ;;
    --check-updates)
        MODE="check-updates"
        ;;
    --check-status)
        MODE="check-status"
        ;;
    --auto)
        MODE="auto"
        ;;
    --env-only)
        MODE="env-only"
        ;;
    "")
        MODE="interactive"
        ;;
    *)
        error "Unknown argument: $1"
        usage
        exit 1
        ;;
esac

check_multilib
detect_cpu
detect_gpus
assemble_recommendations
audit_installed_packages

if [[ "$MODE" == "env-only" ]]; then
    generate_gpu_env
    exit 0
fi

if [[ "$MODE" == "check-missing" ]]; then
    all_missing=("${MISSING_PACMAN[@]}" "${MISSING_AUR[@]}")
    if [[ "${#all_missing[@]}" -gt 0 ]]; then
        echo "${all_missing[*]}"
        exit 1
    else
        exit 0
    fi
fi

if [[ "$MODE" == "check-updates" ]]; then
    if check_upstream_driver_updates; then
        exit 2
    else
        echo "No driver updates available"
        exit 0
    fi
fi

if [[ "$MODE" == "check-status" ]]; then
    all_missing=("${MISSING_PACMAN[@]}" "${MISSING_AUR[@]}")
    dkms_ok=1
    if command -v dkms >/dev/null 2>&1; then
        if ! dkms status 2>/dev/null | grep -qE "(installed|built)"; then
            dkms_ok=0
        fi
    fi
    echo "TOPOLOGY=\"$TOPOLOGY\""
    echo "CPU_VENDOR=\"$CPU_VENDOR\""
    echo "NVIDIA_BRANCH=\"$NVIDIA_BRANCH\""
    echo "MISSING_COUNT=\"${#all_missing[@]}\""
    echo "MISSING_PKGS=\"${all_missing[*]}\""
    echo "DKMS_OK=\"$dkms_ok\""
    exit 0
fi

if [[ "$MODE" == "check" ]]; then
    print_hardware_summary
    print_package_table
    run_diagnostics

    total_missing=$((${#MISSING_PACMAN[@]} + ${#MISSING_AUR[@]} + ${#CONFLICTING_PKGS[@]}))
    if [[ "$total_missing" -eq 0 ]]; then
        echo -e "\n${GREEN}${BOLD}✓ Driver and hardware stack are in optimal state.${NC}\n"
        exit 0
    else
        echo -e "\n${YELLOW}${BOLD}⚠ Action recommended: $total_missing missing/conflicting package(s) detected.${NC}"
        echo -e "Run ${CYAN}hardware-wizard.sh${NC} to install recommended packages.\n"
        exit 1
    fi
fi

# Interactive / Auto mode
print_hardware_summary
print_package_table

total_missing=$((${#MISSING_PACMAN[@]} + ${#MISSING_AUR[@]} + ${#CONFLICTING_PKGS[@]}))

if [[ "$total_missing" -eq 0 ]]; then
    success "All recommended driver packages are already installed!"
    generate_gpu_env
    run_diagnostics
    exit 0
fi

if [[ "$MODE" == "auto" ]]; then
    info "Auto mode specified — installing recommended driver stack..."
    install_packages
    run_diagnostics
else
    echo -e "${BOLD}Would you like to install the recommended drivers and update Hyprland environment?${NC}"
    read -rp "Proceed with installation? [Y/n]: " choice
    if [[ "${choice,,}" == "n" ]]; then
        info "Aborted by user. Only updating environment variables..."
        generate_gpu_env
        exit 0
    fi
    install_packages
    run_diagnostics
fi

banner "Hardware Wizard Complete"
echo -e "${GREEN}${BOLD}Recommended next steps:${NC}"
echo "  1) If new kernel modules or drivers were installed: sudo reboot"
echo "  2) Run 'prime-run <command>' to execute games/apps on the dedicated GPU"
echo "  3) Check system telemetry anytime via Waybar battery menu or hardware-wizard.sh --check"
echo ""
