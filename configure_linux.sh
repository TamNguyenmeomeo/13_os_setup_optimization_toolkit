#!/bin/bash
# configure_linux.sh — v2.0 Interactive Menu
# Automated Linux IT Setup & Optimization Toolkit
# Supports: Ubuntu/Debian and CentOS/RHEL/AlmaLinux

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; WHITE='\033[1;37m'; GRAY='\033[0;37m'; NC='\033[0m'

# ── Detect OS & Package Manager ───────────────────────────────────────────────
detect_os() {
    if command -v apt-get &>/dev/null; then
        PKG_MANAGER="apt-get"
        INSTALL_CMD="apt-get install -y"
        UPDATE_CMD="apt-get update -q"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"
        INSTALL_CMD="yum install -y"
        UPDATE_CMD="yum check-update -q || true"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="dnf install -y"
        UPDATE_CMD="dnf check-update -q || true"
    else
        PKG_MANAGER="unknown"
    fi
}

detect_os
LOG_FILE="$(dirname "$0")/toolkit_report_$(date +%Y%m%d_%H%M%S).txt"
LOG_BUFFER=""

log() { LOG_BUFFER+="$1\n"; echo -e "$1"; }

# ── Header ────────────────────────────────────────────────────────────────────
show_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   🐧  Linux IT Setup & Optimization Toolkit  v2.0        ║${NC}"
    echo -e "${CYAN}║   OS: $(lsb_release -d 2>/dev/null | cut -f2 || uname -s)  |  PKG: ${PKG_MANAGER}$(printf '%*s' $((28 - ${#PKG_MANAGER})) '')║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

menu_option() { echo -e "  ${GRAY}[${NC}${YELLOW}$1${NC}${GRAY}]${NC}  ${WHITE}$2${NC}"; }

# ── Action 1: System Info ─────────────────────────────────────────────────────
show_system_info() {
    echo -e "\n${YELLOW}[1] Gathering System Diagnostics...${NC}"
    log " -> Hostname:         $(hostname)"
    log " -> Kernel:           $(uname -r)"
    log " -> OS:               $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"
    log " -> CPU:              $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
    log " -> Memory:           $(free -h | awk '/Mem:/ {print $3 "/" $2 " used"}')"
    log " -> Disk (/):         $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 " used)"}')"
    log " -> Uptime:           $(uptime -p)"
}

# ── Action 2: Clean Cache ─────────────────────────────────────────────────────
clean_cache() {
    echo -e "\n${YELLOW}[2] Cleaning System Cache & Temp Files...${NC}"
    if [ "$EUID" -ne 0 ]; then
        echo -e " -> ${CYAN}[Notice] Run as root (sudo) to clean package cache.${NC}"
    else
        if [ "$PKG_MANAGER" = "apt-get" ]; then
            apt-get clean -q && apt-get autoremove -y -q
            log " -> apt-get: cache cleaned and orphan packages removed."
        elif [ "$PKG_MANAGER" = "yum" ] || [ "$PKG_MANAGER" = "dnf" ]; then
            $PKG_MANAGER clean all
            log " -> $PKG_MANAGER: cache cleaned."
        fi
    fi
    TEMP_SIZE=$(du -sh /tmp 2>/dev/null | cut -f1)
    log " -> /tmp size: ${TEMP_SIZE}"
}

# ── Action 3: Firewall Check ──────────────────────────────────────────────────
check_firewall() {
    echo -e "\n${YELLOW}[3] Checking Firewall Status...${NC}"
    if command -v ufw &>/dev/null; then
        STATUS=$(sudo ufw status 2>/dev/null || echo "requires sudo")
        log " -> UFW: $STATUS"
    elif command -v firewall-cmd &>/dev/null; then
        STATUS=$(sudo firewall-cmd --state 2>/dev/null || echo "requires sudo")
        log " -> firewalld: $STATUS"
    else
        log " -> No firewall tool detected (ufw / firewalld)."
    fi
}

# ── Action 4: Network Diagnostics ────────────────────────────────────────────
check_network() {
    echo -e "\n${YELLOW}[4] Running Network Diagnostics...${NC}"
    if ping -c 1 -W 2 google.com &>/dev/null; then
        log " -> DNS Resolution (google.com): ${GREEN}SUCCESS ✔${NC}"
    else
        log " -> DNS Resolution (google.com): ${RED}FAILED ✘${NC}"
    fi
    if ping -c 2 -W 2 8.8.8.8 &>/dev/null; then
        log " -> Ping 8.8.8.8 (Google DNS):    ${GREEN}SUCCESS ✔${NC}"
    else
        log " -> Ping 8.8.8.8 (Google DNS):    ${RED}FAILED ✘${NC}"
    fi
}

# ── Action 5: Auto Install Common Software ────────────────────────────────────
install_software() {
    if [ "$PKG_MANAGER" = "unknown" ]; then
        echo -e " -> ${RED}No supported package manager found.${NC}"; return
    fi
    echo -e "\n${YELLOW}[5] Auto Install Common Software${NC}"
    echo -e "     Select software (comma-separated, e.g. 1,3): ${CYAN}"

    declare -A PKGS=(
        [1]="curl"  [2]="git"    [3]="vim"
        [4]="htop"  [5]="unzip" [6]="wget"
        [7]="net-tools" [8]="nmap"
    )
    for i in "${!PKGS[@]}"; do
        echo -e "   ${GRAY}[${NC}${YELLOW}$i${NC}${GRAY}]${NC} ${PKGS[$i]}"
    done
    echo -e "   ${GRAY}[0]${NC} Cancel${NC}"
    read -rp "   Your choice: " choices

    [ "$choices" = "0" ] || [ -z "$choices" ] && return

    IFS=',' read -ra selected <<< "$choices"
    if [ "$EUID" -ne 0 ]; then
        echo -e " -> ${CYAN}Run as root (sudo) to install packages.${NC}"; return
    fi
    $UPDATE_CMD
    for choice in "${selected[@]}"; do
        choice=$(echo "$choice" | xargs)
        pkg="${PKGS[$choice]}"
        if [ -n "$pkg" ]; then
            echo -e " -> Installing ${CYAN}$pkg${NC}..."
            $INSTALL_CMD "$pkg"
            log " -> Installed: $pkg"
        fi
    done
}

# ── Action 6: Save Report ─────────────────────────────────────────────────────
save_report() {
    echo -e "$LOG_BUFFER" > "$LOG_FILE"
    echo -e " -> ${GREEN}Report saved to: $LOG_FILE${NC}"
}

# ── Main Menu Loop ────────────────────────────────────────────────────────────
while true; do
    show_header
    echo -e "  Select an action:\n"
    menu_option "1" "System Information & Diagnostics"
    menu_option "2" "Clean System Cache & Temp Files"
    menu_option "3" "Check Firewall Status"
    menu_option "4" "Network Connectivity Test"
    menu_option "5" "Auto Install Common Software"
    menu_option "6" "Save Diagnostic Report to File"
    menu_option "A" "Run All Diagnostics (1-4)"
    menu_option "0" "Exit"
    echo ""
    read -rp "  Enter your choice: " choice

    case "${choice^^}" in
        1) show_system_info; read -rp $'\n  Press Enter to continue...' ;;
        2) clean_cache;      read -rp $'\n  Press Enter to continue...' ;;
        3) check_firewall;   read -rp $'\n  Press Enter to continue...' ;;
        4) check_network;    read -rp $'\n  Press Enter to continue...' ;;
        5) install_software; read -rp $'\n  Press Enter to continue...' ;;
        6) save_report;      read -rp $'\n  Press Enter to continue...' ;;
        A)
            show_system_info; clean_cache
            check_firewall; check_network
            read -rp $'\n  All tasks complete. Press Enter...'
            ;;
        0) echo -e "\n  ${GREEN}Goodbye! Stay optimized. 🚀${NC}"; break ;;
        *) echo -e "\n  ${RED}Invalid option. Try again.${NC}"; sleep 1 ;;
    esac
done
