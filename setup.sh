#!/data/data/com.termux/files/usr/bin/bash
#######################################################
#  Termux Linux Setup Script (XFCE4, Mali/Exynos)
#
#  - XFCE4 desktop on Termux-X11
#  - Software rendering (llvmpipe): no Turnip/Zink on Mali
#  - Firefox, VLC, Python, Wine (Hangover)
#######################################################

# ============== CONFIGURATION ==============
TOTAL_STEPS=10
CURRENT_STEP=0
LOG="$HOME/termux-setup.log"
FAILED=()

# ============== COLORS ==============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

# ============== HELPERS ==============
update_progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    PERCENT=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    FILLED=$((PERCENT / 5))
    BAR="${GREEN}"
    for ((i=0; i<FILLED; i++)); do BAR+="*"; done
    BAR+="${GRAY}"
    for ((i=FILLED; i<20; i++)); do BAR+="-"; done
    BAR+="${NC}"

    echo ""
    echo -e "${WHITE}------------------------------------------------------------${NC}"
    echo -e "${CYAN}  OVERALL PROGRESS: ${WHITE}Step ${CURRENT_STEP}/${TOTAL_STEPS}${NC} ${BAR} ${WHITE}${PERCENT}%${NC}"
    echo -e "${WHITE}------------------------------------------------------------${NC}"
    echo ""
}

step_title() {
    update_progress
    echo -e "${PURPLE}[Step ${CURRENT_STEP}/${TOTAL_STEPS}] $1${NC}"
    echo ""
}

spinner() {
    local pid=$1 message=$2 spin='-\|/' i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf '\r  [*] %s %b%s%b  ' "$message" "$CYAN" "${spin:$i:1}" "$NC"
        sleep 0.1
    done
    wait "$pid"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        printf '\r  [+] %s                    \n' "$message"
    else
        printf '\r  [-] %s %b(failed, see %s)%b\n' "$message" "$RED" "$LOG" "$NC"
        FAILED+=("$message")
    fi
    return $exit_code
}

# run "<message>" cmd args...  (output goes to $LOG)
run() {
    local message=$1; shift
    echo "===== $message: $* =====" >> "$LOG"
    ("$@" >> "$LOG" 2>&1) &
    spinner $! "$message"
}

install_pkg() {
    run "Installing ${2:-$1}..." env DEBIAN_FRONTEND=noninteractive \
        apt-get install -y -o Dpkg::Options::="--force-confold" "$1"
}

abort() {
    echo -e "\n${RED}[!] $1 failed. Cannot continue. Details in ${LOG}${NC}"
    exit 1
}

# ============== PRE-FLIGHT ==============
preflight() {
    clear
    echo -e "${CYAN}"
    cat << 'BANNER'
    -------------------------------------------

          Termux Linux Setup Script (XFCE4)

    -------------------------------------------
BANNER
    echo -e "${NC}"

    if [ -z "$PREFIX" ] || [ ! -d "$PREFIX" ] || ! command -v apt-get >/dev/null; then
        echo -e "${RED}[!] This script must be run inside Termux.${NC}"
        exit 1
    fi

    : > "$LOG"
    echo -e "  [*] Device: ${WHITE}$(getprop ro.product.brand) $(getprop ro.product.model)${NC}"
    echo -e "  [*] Android: ${WHITE}$(getprop ro.build.version.release)${NC}"
    echo -e "  [*] Rendering: ${WHITE}Software (llvmpipe), configured for Mali GPUs${NC}"
    echo -e "  [*] Log file: ${WHITE}${LOG}${NC}"
}

# ============== STEPS ==============
step_update() {
    step_title "Updating system packages..."
    run "Updating package lists..." apt-get update -y || abort "Package list update"
    run "Upgrading installed packages..." env DEBIAN_FRONTEND=noninteractive \
        apt-get upgrade -y -o Dpkg::Options::="--force-confold"
}

step_repos() {
    step_title "Adding package repositories..."
    install_pkg "x11-repo" "X11 Repository" || abort "X11 repository"
    install_pkg "tur-repo" "TUR Repository (Firefox)"
    # New repos are invisible to apt until lists are refreshed
    run "Refreshing package lists..." apt-get update -y || abort "Package list refresh"
}

step_x11() {
    step_title "Installing Termux-X11..."
    install_pkg "termux-x11-nightly" "Termux-X11 Display Server" || abort "Termux-X11"
    install_pkg "xorg-xrandr" "XRandR (Display Settings)"
}

step_desktop() {
    step_title "Installing XFCE4 Desktop..."
    install_pkg "xfce4" "XFCE4 Desktop" || abort "XFCE4"
    install_pkg "xfce4-terminal" "XFCE4 Terminal"
    install_pkg "xfce4-whiskermenu-plugin" "Whisker Menu"
    install_pkg "plank-reloaded" "Plank Dock"
    install_pkg "thunar" "Thunar File Manager"
    install_pkg "mousepad" "Mousepad Editor"
    install_pkg "dbus" "D-Bus"
}

step_audio() {
    step_title "Installing Audio..."
    install_pkg "pulseaudio" "PulseAudio Server"
}

step_apps() {
    step_title "Installing Media & Dev Apps..."
    install_pkg "firefox" "Firefox Browser"
    install_pkg "vlc" "VLC Media Player"
    install_pkg "git" "Git Version Control"
    install_pkg "wget" "Wget Downloader"
    install_pkg "curl" "cURL"
}

step_python() {
    step_title "Installing Python..."
    install_pkg "python" "Python 3"
}

step_wine() {
    step_title "Installing Windows Support (Wine/Box64)..."
    run "Removing old Wine versions..." apt-get remove -y wine-stable
    install_pkg "hangover-wine" "Wine Compatibility Layer"
    install_pkg "hangover-wowbox64" "Box64 Wrapper"

    local bin
    for bin in wine winecfg; do
        local src="$PREFIX/opt/hangover-wine/bin/$bin"
        if [ -x "$src" ] && [ ! -e "$PREFIX/bin/$bin" ]; then
            ln -s "$src" "$PREFIX/bin/$bin"
        fi
    done
}

step_launchers() {
    step_title "Configuring Startup Scripts..."
    mkdir -p ~/.config ~/.config/autostart
    rm -f ~/.config/linux-gpu.sh  # old Zink config, breaks rendering on Mali

    # Expanded at runtime, not now
    cat > ~/.config/linux-env.sh << 'EOF'
export XDG_DATA_DIRS="$PREFIX/share${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
export XDG_CONFIG_DIRS="$PREFIX/etc/xdg${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}"
EOF

    cat > ~/.config/autostart/plank.desktop << 'EOF'
[Desktop Entry]
Type=Application
Exec=plank
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank
EOF

    cat > ~/stop-linux.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Stopping XFCE4..."
pkill xfce4-session 2>/dev/null
pkill plank 2>/dev/null
sleep 1
pkill -f "dbus-daemon.*--session" 2>/dev/null
pkill -f "termux.x11" 2>/dev/null
pulseaudio --kill 2>/dev/null
echo "Desktop stopped."
EOF
    chmod +x ~/stop-linux.sh
    echo -e "  [+] Created ~/stop-linux.sh"

    cat > ~/start-linux.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "[*] Starting XFCE4..."
source ~/.config/linux-env.sh

echo "[*] Cleaning up old sessions..."
~/stop-linux.sh > /dev/null 2>&1

echo "[*] Starting audio server..."
pulseaudio --start --exit-idle-time=-1

echo "[*] Starting X11 server..."
termux-x11 :0 > /dev/null 2>&1 &
for _ in $(seq 1 50); do
    [ -S "$PREFIX/tmp/.X11-unix/X0" ] && break
    sleep 0.2
done
if [ ! -S "$PREFIX/tmp/.X11-unix/X0" ]; then
    echo "[!] X11 server did not start."
    exit 1
fi
export DISPLAY=:0

echo "-----------------------------------------------"
echo "  [*] Open the Termux:X11 app to view desktop!"
echo "-----------------------------------------------"
exec dbus-launch --exit-with-session startxfce4
EOF
    chmod +x ~/start-linux.sh
    echo -e "  [+] Created ~/start-linux.sh"
}

step_shortcuts() {
    step_title "Creating Desktop Shortcuts..."
    mkdir -p ~/Desktop

    cat > ~/Desktop/Firefox.desktop << 'EOF'
[Desktop Entry]
Name=Firefox
Exec=firefox
Icon=firefox
Type=Application
EOF

    cat > ~/Desktop/VLC.desktop << 'EOF'
[Desktop Entry]
Name=VLC Media Player
Exec=vlc
Icon=vlc
Type=Application
EOF

    cat > ~/Desktop/Terminal.desktop << 'EOF'
[Desktop Entry]
Name=Terminal
Exec=xfce4-terminal
Icon=utilities-terminal
Type=Application
EOF

    if command -v wine >/dev/null; then
        cat > ~/Desktop/Wine_Config.desktop << 'EOF'
[Desktop Entry]
Name=Wine Config (Windows)
Exec=winecfg
Icon=wine
Type=Application
EOF
    fi

    chmod +x ~/Desktop/*.desktop 2>/dev/null
    echo -e "  [+] Added desktop shortcuts."
}

# ============== COMPLETION ==============
show_completion() {
    echo ""
    if [ ${#FAILED[@]} -eq 0 ]; then
        echo -e "${GREEN}    [*]  INSTALLATION COMPLETE!  [*]${NC}"
    else
        echo -e "${YELLOW}    [!]  INSTALLATION FINISHED WITH ${#FAILED[@]} FAILURE(S):${NC}"
        printf '         - %s\n' "${FAILED[@]}"
        echo -e "${YELLOW}    Details in ${LOG}${NC}"
    fi
    echo ""
    echo -e "${WHITE}[*] Also install the Termux:X11 Android app (github.com/termux/termux-x11/releases).${NC}"
    echo -e "${WHITE}[*] Tip: disable compositing for speed: Settings > Window Manager Tweaks > Compositor.${NC}"
    echo ""
    echo -e "${YELLOW}------------------------------------------------------------${NC}"
    echo -e "${WHITE}[*] TO START THE DESKTOP:${NC}  ${GREEN}~/start-linux.sh${NC}"
    echo -e "${WHITE}[*] TO STOP THE DESKTOP:${NC}   ${GREEN}~/stop-linux.sh${NC}"
    echo -e "${YELLOW}------------------------------------------------------------${NC}"
}

# ============== MAIN ==============
preflight
step_update
step_repos
step_x11
step_desktop
step_audio
step_apps
step_python
step_wine
step_launchers
step_shortcuts
show_completion
