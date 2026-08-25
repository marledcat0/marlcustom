#!/bin/bash

# ==================================================
# WSL2 Ubuntu 24.04 Initialization Script
#
# Description:
#   Initializes a WSL2 Ubuntu 24.04 environment
#   with development tools, X11 applications,
#   Zsh, Starship, and 32-bit support.
#
# Author: JeongHwan Lee
# Version: 1.0.0
# ==================================================

set -Eeuo pipefail

# ==================================================
# Configuration
# ==================================================

STATE_FILE="$HOME/.wsl-init.state"
LOG_FILE="$HOME/.wsl-init.log"

# ==================================================
# Check initialization status
# ==================================================

if [[ -f "$STATE_FILE" ]] && grep -qx "0" "$STATE_FILE"; then
    echo
    echo "=================================================="
    echo " WSL2 Ubuntu24.04 initialization is already done."
    echo "=================================================="
    echo
    echo "State file : $STATE_FILE"
    echo "Log file   : $LOG_FILE"
    echo
    echo "If you want to run the initialization again:"
    echo
    echo "    rm -f $STATE_FILE"
    echo
    echo "Then run this script again."
    echo

    exit 0
fi


# ==================================================
# Initialize log file
# ==================================================

touch "$LOG_FILE"


# ==================================================
# Current step
# ==================================================

CURRENT_STEP="unknown"
CURRENT_DESCRIPTION="unknown"


# ==================================================
# Error handler
# ==================================================

error_handler() {
    local exit_code=$?
    local line_no=$1

    echo "$(date '+%Y-%m-%d %H:%M:%S') | FAILED   | Step=$CURRENT_STEP | $CURRENT_DESCRIPTION | Line=$line_no | Exit=$exit_code" \
        >> "$LOG_FILE"

    echo
    echo "=================================================="
    echo " ERROR"
    echo "=================================================="
    echo "Step       : $CURRENT_STEP"
    echo "Description: $CURRENT_DESCRIPTION"
    echo "Line       : $line_no"
    echo "Exit code  : $exit_code"
    echo "Log file   : $LOG_FILE"
    echo
    echo "Last 30 lines of log:"
    echo "--------------------------------------------------"

    tail -n 30 "$LOG_FILE"

    echo "--------------------------------------------------"
    echo "Initialization stopped."
    echo
    echo "Run this script again to resume from the failed step."
    echo "=================================================="

    exit "$exit_code"
}


trap 'error_handler $LINENO' ERR


# ==================================================
# Step functions
# ==================================================

# Update the system packages.
step_system_update() {
    sudo apt-get update && sudo apt-get upgrade -y
}


# Install basic development tools.
step_basic_tools() {
    sudo apt-get install -y \
         neovim gcc git tmux curl wget unzip build-essential gdb make \
         ca-certificates
    
    if update-alternatives --list editor 2>/dev/null \
    | grep -qx "$(command -v nvim)"; then
    sudo update-alternatives --set editor "$(command -v nvim)"
    else
    sudo update-alternatives \
        --install /usr/bin/editor editor "$(command -v nvim)" 100

    sudo update-alternatives \
        --set editor "$(command -v nvim)"
    fi
}




# Configure Zsh and Starship.
step_zsh_starship() {
    sudo apt-get install -y \
        zsh zsh-syntax-highlighting zsh-autosuggestions

    if ! command -v starship >/dev/null 2>&1; then
        curl -sS https://starship.rs/install.sh | sh
    fi

    if [[ ! -d "$HOME/marlcustom/.git" ]]; then
        git clone https://github.com/marledcat0/marlcustom.git \
            "$HOME/marlcustom"
    fi

    cp "$HOME/marlcustom/zsh/.zshrc" "$HOME/.zshrc"
    mkdir -p "$HOME/.config"
    cp "$HOME/marlcustom/starship/starship.toml" "$HOME/.config/starship.toml"

    sudo chsh -s "$(command -v zsh)" "$USER"
}

# Install X11 applications.
step_x11() {
    sudo apt-get install -y \
         x11-apps nautilus
}

# Install docker
step_docker() {
    # 기존 설치된 서드파티 의존성 제거
    # for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt remove $pkg; done

    # 도커 제거
    # sudo apt purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

    # 이미지, 컨테이너 등 제거
    # sudo rm -rf /var/lib/docker
    # sudo rm -rf /var/lib/containerd

    # Add docker official GPG Key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list
    sudo apt-get update

    sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
    docker-compose-plugin

    # Add user to docker group
    sudo usermod -a -G docker $USER
}

# Enable 32-bit support.
step_32bit() {
    sudo dpkg --add-architecture i386
    sudo apt-get update
    sudo apt-get install -y \
         libssl-dev libc6-i386 libc6-dbg gcc-multilib libffi-dev libc6:i386
}


# ==================================================
# Step runner
# ==================================================

run_step() {
    local step="$1"
    local description="$2"
    local function_name="$3"

    CURRENT_STEP="$step"
    CURRENT_DESCRIPTION="$description"


    # --------------------------------------------------
    # Skip already completed step
    # --------------------------------------------------

    if [[ -f "$STATE_FILE" ]] && grep -qx "$step" "$STATE_FILE"; then
        echo "[SKIP] Step $step - $description"
        echo "$(date '+%Y-%m-%d %H:%M:%S') | SKIP     | Step=$step | \
        $description" >> "$LOG_FILE"
        return 0
    fi


    # --------------------------------------------------
    # Start step
    # --------------------------------------------------

    echo
    echo "=================================================="
    echo "[STEP $step] $description"
    echo "=================================================="
    echo "$(date '+%Y-%m-%d %H:%M:%S') | START    | Step=$step | $description" \
        >> "$LOG_FILE"

    # --------------------------------------------------
    # Execute step
    #
    # Normal output -> log
    # Error output  -> log
    # --------------------------------------------------

    "$function_name" >> "$LOG_FILE" 2>&1


    # --------------------------------------------------
    # Mark step as completed
    # --------------------------------------------------

    echo "$step" >> "$STATE_FILE"
    echo "$(date '+%Y-%m-%d %H:%M:%S') | DONE     | Step=$step | $description" \
        >> "$LOG_FILE"
    echo "[DONE] Step $step - $description"
}


# ==================================================
# Execute steps
# ==================================================

run_step "1" "System update" step_system_update
run_step "2" "Install basic tools" step_basic_tools
run_step "3" "Install X11 GUI applications" step_x11
run_step "4" "Configure Zsh and Starship" step_zsh_starship
run_step "5" "Install Docker" step_docker
run_step "6" "Enable 32-bit support" step_32bit


# ==================================================
# Initialization complete
# ==================================================

# 0 means the entire initialization has completed.
echo "0" > "$STATE_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') | COMPLETE | Step=0 | \
     Initialization completed successfully" >> "$LOG_FILE"


# ==================================================
# Complete message
# ==================================================

echo
echo "=================================================="
echo " WSL2 Ubuntu24.04 initialization COMPLETE!"
echo "=================================================="
echo
echo "All steps were successfully completed."
echo
echo "State file : $STATE_FILE"
echo "Log file   : $LOG_FILE"
echo
echo "If you want to run this script again from the beginning:"
echo
echo "    rm -f $STATE_FILE"
echo
echo "=================================================="