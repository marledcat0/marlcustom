#!/bin/bash
set -e

# 1. Ensure the script is executed with root/sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "[-] Error: This script must be run with sudo or as root."
    echo "[!] Usage: sudo $0"
    exit 1
fi

SUDOERS_FILE="/etc/sudoers.d/99-sudo-group-nopasswd"

# 2. Grant NOPASSWD privileges to the %sudo group
echo "%sudo ALL=(ALL:ALL) NOPASSWD: ALL" > "${SUDOERS_FILE}"

# 3. Set strict permissions (required for sudoers files)
chmod 0440 "${SUDOERS_FILE}"

# 4. Validate syntax with visudo (delete file on failure to avoid lockout)
if ! visudo -cf "${SUDOERS_FILE}"; then
    echo "[-] Error: Invalid sudoers syntax. Removing temporary configuration."
    rm -f "${SUDOERS_FILE}"
    exit 1
fi

echo "[+] Success: NOPASSWD configured for the '%sudo' group."