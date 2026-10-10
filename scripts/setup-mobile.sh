#!/usr/bin/env bash
# ==============================================================================
# setup-mobile.sh
# Automated Environment Setup for Neovim (optimized_for_mobile branch)
# Designed for Kali NetHunter Rootless (Android / Termux / PRoot / aarch64)
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RED="\033[31m"
RESET="\033[0m"

log_info() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

echo -e "${BOLD}${CYAN}"
echo "=================================================================="
echo "  📱 Neovim Mobile & NetHunter Rootless Environment Setup"
echo "  Branch: optimized_for_mobile"
echo "=================================================================="
echo -e "${RESET}"

# 1. Architecture & Platform Detection
ARCH=$(uname -m)
log_info "Detected system architecture: ${BOLD}${ARCH}${RESET}"

if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    log_info "Running on ARM64. Applying mobile & ARM64-specific configurations..."
else
    log_info "Running on ${ARCH}."
fi

# 2. System Dependencies Check
log_info "Checking essential system packages..."
REQUIRED_PKGS=()
for cmd in clangd rg make gcc curl tar xclip fc-cache python3; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        case "$cmd" in
            rg) REQUIRED_PKGS+=("ripgrep") ;;
            fc-cache) REQUIRED_PKGS+=("fontconfig") ;;
            *) REQUIRED_PKGS+=("$cmd") ;;
        esac
    fi
done

if [ ${#REQUIRED_PKGS[@]} -gt 0 ]; then
    log_warn "Missing required packages: ${REQUIRED_PKGS[*]}"
    if command -v apt-get >/dev/null 2>&1; then
        echo -e "${YELLOW}Attempting to install missing packages via apt...${RESET}"
        if [ "$(id -u)" -eq 0 ]; then
            apt-get update && apt-get install -y "${REQUIRED_PKGS[@]}"
        elif command -v sudo >/dev/null 2>&1; then
            echo -e "${YELLOW}Enter your sudo password if prompted:${RESET}"
            sudo apt-get update && sudo apt-get install -y "${REQUIRED_PKGS[@]}"
        else
            log_error "Please run: apt update && apt install -y ${REQUIRED_PKGS[*]}"
            exit 1
        fi
    else
        log_error "Unsupported package manager. Please manually install: ${REQUIRED_PKGS[*]}"
        exit 1
    fi
else
    log_success "All essential system utilities are already installed."
fi

# 3. Nerd Font Setup (JetBrains Mono Nerd Font v3.5.1)
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
log_info "Checking Nerd Font installation..."

if fc-list : family | grep -qi "JetBrainsMono Nerd Font"; then
    log_success "JetBrains Mono Nerd Font is already installed in fontconfig."
else
    log_info "Installing JetBrains Mono Nerd Font..."
    mkdir -p "$FONT_DIR"
    FONT_TAR="$FONT_DIR/JetBrainsMono.tar.xz"
    curl -fLo "$FONT_TAR" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    tar -xf "$FONT_TAR" -C "$FONT_DIR"
    rm -f "$FONT_TAR"
    fc-cache -fv "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
    log_success "JetBrains Mono Nerd Font installed and cached successfully."
fi

# Copy font to Android /sdcard/Download if accessible for Termux/mobile setup
if [ -d "/sdcard/Download" ] && [ -w "/sdcard/Download" ]; then
    FONT_SOURCE=$(find "$HOME/.local/share/fonts" -name "JetBrainsMonoNerdFont-Regular.ttf" 2>/dev/null | head -n 1)
    if [ -n "$FONT_SOURCE" ]; then
        cp "$FONT_SOURCE" "/sdcard/Download/JetBrainsMonoNerdFont-Regular.ttf"
        log_success "Saved font copy to /sdcard/Download/JetBrainsMonoNerdFont-Regular.ttf"
    fi
fi

# 4. Verify Mobile Clipboard Configuration
log_info "Verifying mobile clipboard setup..."
if [ -w "/dev/tty" ]; then
    log_success "/dev/tty is writable (OSC 52 escape sequences will reach Android terminal directly)."
else
    log_warn "/dev/tty is not directly writable. Standard TUI channels will be used."
fi

# 5. Neovim Pre-flight Check
log_info "Testing Neovim startup and LSP configuration..."
if command -v nvim >/dev/null 2>&1; then
    NVIM_OUT=$(nvim --headless -c "quit" 2>&1 || true)
    if echo "$NVIM_OUT" | grep -qi "failed to install clangd"; then
        log_error "Found unresolved Mason clangd error in Neovim output."
    else
        log_success "Neovim loaded cleanly without Mason/platform errors."
    fi
else
    log_error "Neovim (nvim) binary not found in PATH."
    exit 1
fi

echo -e "\n${BOLD}${GREEN}=================================================================="
echo "  🎉 Mobile Environment Setup Complete!"
echo "==================================================================${RESET}"
echo -e "${BOLD}Tips for NetHunter / Termux usage:${RESET}"
echo -e "  • ${CYAN}Copying text out of Neovim:${RESET} Simply yank ('y' or 'yy'). It copies to your Android clipboard."
echo -e "  • ${CYAN}Pasting text from Android:${RESET} Long-press screen in Termux -> tap 'Paste', or use your keyboard's paste button."
echo -e "  • ${CYAN}Termux font setup (if using Termux directly):${RESET}"
echo -e "      cp /sdcard/Download/JetBrainsMonoNerdFont-Regular.ttf ~/.termux/font.ttf && termux-reload-settings"
echo ""
